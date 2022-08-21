CPUS := $(shell nproc --all)
CURL := curl -qs --http1.1 -L --retry 10 --output
BUILD_DIR := $(CURDIR)/build
FIRMWARE_DIR := $(CURDIR)/firmware
SRC_DIR := $(CURDIR)/src

export CFLAGS := -fPIC
export CPPFLAGS := -I/usr/src/gm_lib/inc -I$(BUILD_DIR)/include -I$(SRC_DIR)/lib -L/usr/src/gm_lib/lib -L$(BUILD_DIR)/lib
export LDFLAGS := -I$(SRC_DIR)/lib -I$(BUILD_DIR)/include -L$(BUILD_DIR)/lib -Wl,--enable-new-dtags
export LDSHAREDFLAGS := -I$(SRC_DIR)/lib -I$(BUILD_DIR)/include -L$(BUILD_DIR)/lib

BIN := \
	$(BUILD_DIR)/bin/auto_night_mode \
	$(BUILD_DIR)/bin/blue_led \
	$(BUILD_DIR)/bin/flip_mode \
	$(BUILD_DIR)/bin/ir_cut \
	$(BUILD_DIR)/bin/ir_led \
	$(BUILD_DIR)/bin/mirror_mode \
	$(BUILD_DIR)/bin/night_mode \
	$(BUILD_DIR)/bin/rtspd

LIB := \
	$(BUILD_DIR)/lib/libisp328.so \
	$(BUILD_DIR)/lib/libled.so \
	$(BUILD_DIR)/lib/libpwm.so \
	$(BUILD_DIR)/lib/libgpio.so \
	$(BUILD_DIR)/lib/libpopt.so

$(BUILD_DIR) $(BUILD_DIR)/bin $(BUILD_DIR)/lib:
	@mkdir -p $(@)

$(BUILD_DIR)/bin/%: $(LIB) $(SRC_DIR)/bin/%.c | $(BUILD_DIR)/bin
	cd $(SRC_DIR)/bin && $(CC) \
		$(CPPFLAGS) \
		-Wall \
		-o $(@) \
		$(@F).c \
		-l isp328 \
		-l led \
		-l pwm \
		-l gpio \
		-l popt
	$(STRIP) $(@)

$(BUILD_DIR)/bin/rtspd: $(SRC_DIR)/bin/rtspd/* | $(BUILD_DIR)/bin
	cd $(SRC_DIR)/bin/rtspd && $(CC) \
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
	$(STRIP) $(@)

$(BUILD_DIR)/lib/lib%.so: $(SRC_DIR)/lib/%.* | $(BUILD_DIR)/lib
	$(LDSHARED) $(CFLAGS) -o $(@) $(SRC_DIR)/lib/$(basename $(@F:lib%=%)).c
	$(STRIP) $(@)

$(BUILD_DIR)/lib/libpopt.so: LIBPOPT_URL := http://ftp.rpm.org/mirror/popt/popt-1.16.tar.gz
$(BUILD_DIR)/lib/libpopt.so: LIBPOPT_ARCHIVE := $(BUILD_DIR)/$(notdir $(LIBPOPT_URL))
$(BUILD_DIR)/lib/libpopt.so: LIBPOPT_DIR := $(basename $(basename $(LIBPOPT_ARCHIVE)))
$(BUILD_DIR)/lib/libpopt.so: $(BUILD_DIR)/lib/libz.so | $(BUILD_DIR)/lib
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
	$(STRIP) $(@)
	rm -rf $(LIBPOPT_ARCHIVE) $(LIBPOPT_DIR)

$(BUILD_DIR)/lib/libz.so: ZLIB_URL := https://www.zlib.net/zlib-1.2.12.tar.gz
$(BUILD_DIR)/lib/libz.so: ZLIB_ARCHIVE := $(BUILD_DIR)/$(notdir $(ZLIB_URL))
$(BUILD_DIR)/lib/libz.so: ZLIB_DIR := $(basename $(basename $(ZLIB_ARCHIVE)))
$(BUILD_DIR)/lib/libz.so: | $(BUILD_DIR)/lib
	test -f $(ZLIB_ARCHIVE) || $(CURL) $(ZLIB_ARCHIVE) $(ZLIB_URL)
	test -d $(ZLIB_DIR) || tar -xzf $(ZLIB_ARCHIVE) -C $(BUILD_DIR)
	cd $(ZLIB_DIR) \
		&& ./configure \
			--prefix=$(BUILD_DIR) \
			--enable-shared \
		&& make -j$(CPUS) \
		&& make -j$(CPUS) install
	$(STRIP) $(@) $(@:.so=.a)
	rm -rf $(ZLIB_ARCHIVE) $(ZLIB_DIR)

$(FIRMWARE_DIR)/openssl/lib: OPENSSL_URL := https://www.openssl.org/source/openssl-1.1.1q.tar.gz
$(FIRMWARE_DIR)/openssl/lib: OPENSSL_ARCHIVE := $(BUILD_DIR)/$(notdir $(OPENSSL_URL))
$(FIRMWARE_DIR)/openssl/lib: OPENSSL_DIR := $(basename $(basename $(OPENSSL_ARCHIVE)))
$(FIRMWARE_DIR)/openssl/lib: | $(BUILD_DIR)
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
	rm -rf $(OPENSSL_ARCHIVE) $(OPENSSL_DIR)

$(BUILD_DIR)/manufacture.dat: $(SRC_DIR)/loader | $(BUILD_DIR)
	tar cf $(BUILD_DIR)/manufacture.bin --transform 's|.*|manufacture/test_drv|' -C $(SRC_DIR) loader
	openssl req -batch -new -key $(FIRMWARE_DIR)/private-key.pem -out $(BUILD_DIR)/request.pem
	openssl x509 -req -in $(BUILD_DIR)/request.pem -signkey $(FIRMWARE_DIR)/private-key.pem -out $(BUILD_DIR)/certificate.pem
	openssl smime -encrypt -binary -in $(BUILD_DIR)/manufacture.bin -outform DEM -out $(@) $(BUILD_DIR)/certificate.pem
	rm $(BUILD_DIR)/request.pem $(BUILD_DIR)/certificate.pem

$(BUILD_DIR)/firmware.bin: \
	$(BIN) \
	$(LIB) \
	$(shell find $(SRC_DIR) ! -name '*.[ach]' ! -name loader)
	tar czhf $(@) --transform 's|^\.|firmware|' \
		-C $(BUILD_DIR) `cd $(BUILD_DIR) && find -path './lib/*.so' -o -path './lib/*.a' -o -path './bin/*'` \
		-C $(SRC_DIR) `cd $(SRC_DIR) && find ! -type d ! -name '*.[ach]' ! -name loader`

.PHONY: default dist clean

default: \
	$(BUILD_DIR)/firmware.bin \
	$(BUILD_DIR)/manufacture.dat

dist: default
	tar czf $(BUILD_DIR)/firmware.tgz \
		-C $(BUILD_DIR) firmware.bin manufacture.dat \
		-C $(FIRMWARE_DIR) openssl tf_recovery.img
	(cd $(BUILD_DIR) && md5sum firmware.tgz) >$(BUILD_DIR)/firmware.tgz.md5

clean:
	rm -rf $(BUILD_DIR)
