CPUS := $(shell nproc --all)
CURL := curl -qs --http1.1 -L --retry 10 --output
BUILD_DIR := $(CURDIR)/build
SRC_DIR := $(CURDIR)/src

export CFLAGS := -fPIC
export CPPFLAGS := -I/usr/src/gm_lib/inc -I$(BUILD_DIR)/include -I$(SRC_DIR)/lib -L/usr/src/gm_lib/lib -L$(BUILD_DIR)/lib
export LDFLAGS := -I$(SRC_DIR)/lib -I$(BUILD_DIR)/include -L$(BUILD_DIR)/lib -Wl,--enable-new-dtags
export LDSHAREDFLAGS := -I$(SRC_DIR)/lib -I$(BUILD_DIR)/include -L$(BUILD_DIR)/lib

BIN := \
	$(BUILD_DIR)/bin/auto_night_mode \
	$(BUILD_DIR)/bin/blue_led \
	$(BUILD_DIR)/bin/camera_adjust \
	$(BUILD_DIR)/bin/chuangmi_ctrl \
	$(BUILD_DIR)/bin/flip_mode \
	$(BUILD_DIR)/bin/ir_cut \
	$(BUILD_DIR)/bin/ir_led \
	$(BUILD_DIR)/bin/mirror_mode \
	$(BUILD_DIR)/bin/night_mode \
	$(BUILD_DIR)/bin/yellow_led

LIB := \
	$(BUILD_DIR)/lib/libchuangmi_ircut.so \
	$(BUILD_DIR)/lib/libchuangmi_isp328.so \
	$(BUILD_DIR)/lib/libchuangmi_led.so \
	$(BUILD_DIR)/lib/libchuangmi_pwm.so \
	$(BUILD_DIR)/lib/libchuangmi_utils.so

$(BUILD_DIR) $(BUILD_DIR)/bin $(BUILD_DIR)/lib:
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
		librtsp.a \
		-l gm \
		-l m \
		-l pthread \
		-l rt

$(LIB): $(BUILD_DIR)/lib/libchuangmi_utils.so $(BUILD_DIR)/lib
	$(LDSHARED) $(CFLAGS) -o $(@) $(SRC_DIR)/lib/$(basename $(@F:lib%=%)).c

$(BUILD_DIR)/lib/libpopt.so: LIBPOPT_URL := http://ftp.rpm.org/mirror/popt/popt-1.16.tar.gz
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

$(BUILD_DIR)/lib/libz.so: ZLIB_URL := https://www.zlib.net/zlib-1.2.12.tar.gz
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

$(SRC_DIR)/sd/openssl/lib: OPENSSL_URL := https://www.openssl.org/source/openssl-1.1.1q.tar.gz
$(SRC_DIR)/sd/openssl/lib: OPENSSL_ARCHIVE := $(BUILD_DIR)/$(notdir $(OPENSSL_URL))
$(SRC_DIR)/sd/openssl/lib: OPENSSL_DIR := $(basename $(basename $(OPENSSL_ARCHIVE)))
$(SRC_DIR)/sd/openssl/lib: $(BUILD_DIR)
	test -f $(OPENSSL_ARCHIVE) || $(CURL) $(OPENSSL_ARCHIVE) $(OPENSSL_URL)
	test -d $(OPENSSL_DIR) || tar -xzf $(OPENSSL_ARCHIVE) -C $(BUILD_DIR)
	cd $(OPENSSL_DIR) \
		&& ./Configure \
			no-async \
			no-comp \
			no-engine \
			no-hw \
			no-ssl2 \
			no-ssl3 \
			no-zlib \
			linux-armv4 \
			-DL_ENDIAN \
			shared \
			--prefix=$(BUILD_DIR)/openssl \
		&& make -j$(CPUS) depend \
		&& make -j$(CPUS)
	mkdir -p $(@)
	cp -f $(OPENSSL_DIR)/libssl.so.1.1 $(OPENSSL_DIR)/libcrypto.so.1.1 $(@)
	$(STRIP) $(@)/*

$(BUILD_DIR)/manufacture.dat: $(BUILD_DIR)
	tar -cf $(BUILD_DIR)/manufacture.bin -C $(SRC_DIR) manufacture/test_drv
	openssl req -batch -new -key $(CURDIR)/private-key.pem -out $(BUILD_DIR)/request.pem
	openssl x509 -req -in $(BUILD_DIR)/request.pem -signkey $(CURDIR)/private-key.pem -out $(BUILD_DIR)/certificate.pem
	openssl smime -encrypt -binary -in $(BUILD_DIR)/manufacture.bin -outform DEM -out $(@) $(BUILD_DIR)/certificate.pem

$(BUILD_DIR)/firmware.bin: \
	$(BIN) \
	$(LIB) \
	$(BUILD_DIR)/bin/rtspd \
	$(BUILD_DIR)/lib/libpopt.so \
	$(BUILD_DIR)/lib/libz.so
	find $(BUILD_DIR)/lib -maxdepth 1 -type f -name '*.so*' -or -name '*.a*' -exec $(STRIP) {} \;
	find $(BUILD_DIR)/bin -maxdepth 1 -type f -exec $(STRIP) {} \;
	rm -rf $(BUILD_DIR)/firmware
	cp -r --preserve=links $(SRC_DIR)/firmware  $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/firmware/bin $(BUILD_DIR)/firmware/lib
	find $(BUILD_DIR)/lib -maxdepth 1 \( -name '*.so' -or -name '*.a' \) -exec cp {} $(BUILD_DIR)/firmware/lib \;
	find $(BUILD_DIR)/bin -maxdepth 1 -type f -exec cp {} $(BUILD_DIR)/firmware/bin \;
	sync
	sleep 3
	tar czf $(@) -C $(BUILD_DIR) firmware

$(BUILD_DIR)/secret.bin: $(BUILD_DIR)
	(cd src/sd/ft && md5sum *) | sed -r 's~([^[:space:]]+)$$~/tmp/sd/ft/\1~' >$(BUILD_DIR)/secret
	openssl rsautl -encrypt -inkey $(SRC_DIR)/manufacture/prikey.pem -in $(BUILD_DIR)/secret -out $(@)

.PHONY: default install dist clean

default: \
	$(BUILD_DIR)/firmware.bin \
	$(BUILD_DIR)/manufacture.dat \
	$(BUILD_DIR)/secret.bin

install: default
	rm -rf $(BUILD_DIR)/dist
	cp -r $(SRC_DIR)/sd $(BUILD_DIR)/dist
	cp $(BUILD_DIR)/firmware.bin $(BUILD_DIR)/dist
	cp $(BUILD_DIR)/manufacture.dat $(BUILD_DIR)/dist
	cp $(BUILD_DIR)/secret.bin $(BUILD_DIR)/dist/ft
	sync
	sleep 3

dist: install
	tar czf $(BUILD_DIR)/firmware.tgz -C $(BUILD_DIR)/dist .
	(cd $(BUILD_DIR) && md5sum firmware.tgz) >$(BUILD_DIR)/firmware.tgz.md5

clean:
	rm -rf $(BUILD_DIR)
