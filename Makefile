LIBPOPT_URL := http://ftp.rpm.org/mirror/popt/popt-1.16.tar.gz
ZLIB_URL := https://www.zlib.net/zlib-1.2.12.tar.gz

CPUS := $(shell nproc --all)
CURL := curl -qs --http1.1 -L --retry 10 --output
BUILD_DIR := $(CURDIR)/build
SRC_DIR := $(CURDIR)/src

export CFLAGS := -fPIC
export CPPFLAGS := -I$(BUILD_DIR)/include -I$(SRC_DIR)/gm/include -I$(SRC_DIR)/lib -L$(BUILD_DIR)/lib -L$(SRC_DIR)/gm/lib
export LDFLAGS := -I$(SRC_DIR)/lib -I$(BUILD_DIR)/include -L$(BUILD_DIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags
export LDSHAREDFLAGS := -I$(SRC_DIR)/lib -I$(BUILD_DIR)/include -L$(BUILD_DIR)/lib

BIN := \
	$(BUILD_DIR)/bin/auto_night_mode \
	$(BUILD_DIR)/bin/blue_led \
	$(BUILD_DIR)/bin/camera_adjust \
	$(BUILD_DIR)/bin/chuangmi_ctrl \
	$(BUILD_DIR)/bin/flipmode \
	$(BUILD_DIR)/bin/ir_cut \
	$(BUILD_DIR)/bin/ir_led \
	$(BUILD_DIR)/bin/mirrormode \
	$(BUILD_DIR)/bin/nightmode \
	$(BUILD_DIR)/bin/take_snapshot \
	$(BUILD_DIR)/bin/take_video \
	$(BUILD_DIR)/bin/yellow_led

GM := \
	$(BUILD_DIR)/bin/audio_playback \
	$(BUILD_DIR)/bin/encode_with_osd \
	$(BUILD_DIR)/bin/osd

LIB := \
	$(BUILD_DIR)/lib/libchuangmi_ircut.so \
	$(BUILD_DIR)/lib/libchuangmi_isp328.so \
	$(BUILD_DIR)/lib/libchuangmi_led.so \
	$(BUILD_DIR)/lib/libchuangmi_pwm.so \
	$(BUILD_DIR)/lib/libchuangmi_utils.so

$(BUILD_DIR)/bin:
	@mkdir -p $(@)

$(BUILD_DIR)/lib:
	@mkdir -p $(@)

$(BIN): $(LIB) $(BUILD_DIR)/lib/libpopt.so $(BUILD_DIR)/bin
	cd $(SRC_DIR)/bin && $(CC) \
		$(CPPFLAGS) \
		-Wall \
		-o $(@) \
		$(@F).c \
		-l chuangmi_ircut \
		-l chuangmi_isp328 \
		-l chuangmi_led \
		-l chuangmi_pwm \
		-l chuangmi_utils \
		-l popt

$(BUILD_DIR)/bin/rtspd: $(BUILD_DIR)/bin
	cd $(SRC_DIR)/rtspd && $(CC) \
		$(CPPFLAGS) \
		-DLOG_USE_COLOR \
		-Wall \
		-o $(@) \
		$(@F).c \
		log/log.c \
		librtsp.a \
		-l gm \
		-l m \
		-l pthread \
		-l rt

$(GM): $(BUILD_DIR)/lib/libpopt.so
	cd $(SRC_DIR)/gm/bin && $(CC) \
		$(CPPFLAGS) \
		-Wall \
		-o $(@) \
		$(@F).c \
		-l gm \
		-l m \
		-l popt \
		-l pthread \
		-l rt

$(LIB): $(BUILD_DIR)/lib/libchuangmi_utils.so $(BUILD_DIR)/lib
	$(LDSHARED) $(CFLAGS) -o $(@) $(SRC_DIR)/lib/$(basename $(@F:lib%=%)).c

$(BUILD_DIR)/lib/libpopt.so: LIBPOPT_ARCHIVE := $(BUILD_DIR)/$(notdir $(LIBPOPT_URL))
$(BUILD_DIR)/lib/libpopt.so: LIBPOPT_DIR := $(basename $(basename $(LIBPOPT_ARCHIVE)))
$(BUILD_DIR)/lib/libpopt.so: $(BUILD_DIR)/lib/libz.so $(BUILD_DIR)/lib
	test -f $(LIBPOPT_ARCHIVE) || $(CURL) $(LIBPOPT_ARCHIVE) $(LIBPOPT_URL)
	test -d $(LIBPOPT_DIR) || tar -xzf $(LIBPOPT_ARCHIVE) -C $(BUILD_DIR)
	cd $(LIBPOPT_DIR) \
		&& ./configure \
			--host=$(TARGET) \
			--prefix=$(BUILD_DIR) \
			--enable-shared \
			--disable-static \
		&& make -j$(CPUS) \
		&& make -j$(CPUS) install

$(BUILD_DIR)/lib/libz.so: ZLIB_ARCHIVE := $(BUILD_DIR)/$(notdir $(ZLIB_URL))
$(BUILD_DIR)/lib/libz.so: ZLIB_DIR := $(basename $(basename $(ZLIB_ARCHIVE)))
$(BUILD_DIR)/lib/libz.so: $(BUILD_DIR)/lib
	test -f $(ZLIB_ARCHIVE) || $(CURL) $(ZLIB_ARCHIVE) $(ZLIB_URL)
	test -d $(ZLIB_DIR) || tar -xzf $(ZLIB_ARCHIVE) -C $(BUILD_DIR)
	cd $(ZLIB_DIR) \
		&& ./configure \
			--prefix=$(BUILD_DIR) \
			--enable-shared \
		&& make -j$(CPUS) \
		&& make -j$(CPUS) install

$(BUILD_DIR)/config.cfg:
	$(SRC_DIR)/sdcard/firmware/scripts/configupdate $(@)

$(BUILD_DIR)/manufacture.bin:
	tar -cf $(@) -C $(SRC_DIR) manufacture/test_drv

.PHONY: default install dist clean

default: \
	$(BIN) \
	$(GM) \
	$(LIB) \
	$(BUILD_DIR)/bin/rtspd \
	$(BUILD_DIR)/lib/libpopt.so \
	$(BUILD_DIR)/lib/libz.so \
	$(BUILD_DIR)/config.cfg \
	$(BUILD_DIR)/manufacture.bin
	find $(BUILD_DIR)/lib -maxdepth 1 -type f -name '*.so*' -or -name '*.a*' -exec $(STRIP) {} \;
	find $(BUILD_DIR)/bin -maxdepth 1 -type f -exec $(STRIP) {} \;

install: default
	rm -rf $(BUILD_DIR)/dist
	mkdir -p $(BUILD_DIR)/dist
	cp -r --preserve=links $(SRC_DIR)/sdcard  $(BUILD_DIR)/dist
	cp $(BUILD_DIR)/manufacture.bin $(BUILD_DIR)/config.cfg $(BUILD_DIR)/dist/sdcard
	mkdir -p $(BUILD_DIR)/dist/sdcard/firmware/bin $(BUILD_DIR)/dist/sdcard/firmware/lib
	find $(BUILD_DIR)/lib -maxdepth 1 \( -type f -or -type l \) \( -name '*.so*' -or -name '*.a*' \) -exec cp --no-dereference {} $(BUILD_DIR)/dist/sdcard/firmware/lib/. \;
	find $(BUILD_DIR)/bin -maxdepth 1 -type f -exec cp {} $(BUILD_DIR)/dist/sdcard/firmware/bin \;
	sync

dist: install
	tar czf $(BUILD_DIR)/MiiCam.tar.gz -C $(BUILD_DIR)/dist sdcard
	md5sum $(BUILD_DIR)/MiiCam.tar.gz > $(BUILD_DIR)/MiiCam.tar.gz.md5

clean:
	rm -rf $(BUILD_DIR)
