BUILD_DIR := $(CURDIR)/build
FIRMWARE_DIR := $(CURDIR)/firmware
SRC_DIR := $(CURDIR)/src

BIN := \
	$(BUILD_DIR)/bin/ceiling-mode \
	$(BUILD_DIR)/bin/indicator \
	$(BUILD_DIR)/bin/night-mode \
	$(BUILD_DIR)/bin/rtspd

LIB := \
	$(BUILD_DIR)/lib/libisp328.so \
	$(BUILD_DIR)/lib/libled.so \
	$(BUILD_DIR)/lib/libpwm.so \
	$(BUILD_DIR)/lib/libgpio.so

$(BUILD_DIR) $(BUILD_DIR)/bin $(BUILD_DIR)/lib:
	@mkdir -p $(@)

$(BUILD_DIR)/bin/%: $(LIB) $(SRC_DIR)/bin/%.c | $(BUILD_DIR)/bin
	$(CC) \
		-L$(BUILD_DIR)/lib \
		-I$(SRC_DIR)/lib \
		-Wall \
		-o $(@) \
		$(SRC_DIR)/bin/$(@F).c \
		-l isp328 \
		-l led \
		-l pwm \
		-l gpio
	$(STRIP) $(@)

$(BUILD_DIR)/bin/rtspd: $(SRC_DIR)/bin/rtspd.c | $(BUILD_DIR)/bin
	tar -xzf $(CURDIR)/sdk/gm_lib_2015-01-09-IPCAM.tgz -C $(BUILD_DIR)
	$(CC) \
		-L$(BUILD_DIR)/gm_graph/gm_lib/lib \
		-I$(BUILD_DIR)/gm_graph/gm_lib/inc \
		-I$(BUILD_DIR)/gm_graph/product/GM8136_1MP/samples \
		-DLOG_USE_COLOR \
		-Wall \
		-o $(@) \
		$(SRC_DIR)/bin/$(@F).c \
		$(BUILD_DIR)/gm_graph/product/GM8136_1MP/samples/librtsp.a \
		-l gm \
		-l m \
		-l pthread \
		-l rt
	$(STRIP) $(@)
	rm -rf $(BUILD_DIR)/gm_graph

$(BUILD_DIR)/lib/lib%.so: $(SRC_DIR)/lib/%.* | $(BUILD_DIR)/lib
	$(LDSHARED) -fPIC -o $(@) $(SRC_DIR)/lib/$(basename $(@F:lib%=%)).c
	$(STRIP) $(@)

$(FIRMWARE_DIR)/openssl/lib: OPENSSL_URL := https://www.openssl.org/source/openssl-1.1.1q.tar.gz
$(FIRMWARE_DIR)/openssl/lib: OPENSSL_ARCHIVE := $(BUILD_DIR)/$(notdir $(OPENSSL_URL))
$(FIRMWARE_DIR)/openssl/lib: OPENSSL_DIR := $(basename $(basename $(OPENSSL_ARCHIVE)))
$(FIRMWARE_DIR)/openssl/lib: | $(BUILD_DIR)
	test -f $(OPENSSL_ARCHIVE) || curl -s --output $(OPENSSL_ARCHIVE) $(OPENSSL_URL)
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
		&& make depend \
		&& make
	mkdir -p $(@)
	cp -f $(OPENSSL_DIR)/libssl.so.1.1 $(OPENSSL_DIR)/libcrypto.so.1.1 $(@)
	$(STRIP) $(@)/*
	rm -rf $(OPENSSL_ARCHIVE) $(OPENSSL_DIR)

$(BUILD_DIR)/firmware.bin: \
	$(BIN) \
	$(LIB) \
	$(shell find $(SRC_DIR) ! -name '*.[ch]' ! -name loader)
	tar czf $(@) --transform 's|^\.|firmware|' \
		-C $(BUILD_DIR) `cd $(BUILD_DIR) && find -path './bin/*' -o  -path './lib/*'` \
		-C $(SRC_DIR) `cd $(SRC_DIR) && find ! -type d ! -name '*.[ch]' ! -name loader`

$(BUILD_DIR)/manufacture.bin: $(SRC_DIR)/loader | $(BUILD_DIR)
	tar cf $(@) --transform 's|.*|manufacture/test_drv|' -C $(SRC_DIR) loader

$(BUILD_DIR)/manufacture.dat: $(BUILD_DIR)/manufacture.bin
	openssl req -batch -new -key $(FIRMWARE_DIR)/private-key.pem -out $(BUILD_DIR)/request.pem
	openssl x509 -req -in $(BUILD_DIR)/request.pem -signkey $(FIRMWARE_DIR)/private-key.pem -out $(BUILD_DIR)/certificate.pem
	openssl smime -encrypt -binary -in $(BUILD_DIR)/manufacture.bin -outform DEM -out $(@) $(BUILD_DIR)/certificate.pem
	rm $(BUILD_DIR)/request.pem $(BUILD_DIR)/certificate.pem

.PHONY: default dist clean

default: \
	$(BUILD_DIR)/firmware.bin \
	$(BUILD_DIR)/manufacture.dat

dist: \
	default \
	$(FIRMWARE_DIR)/openssl/lib
	tar czf $(BUILD_DIR)/firmware.tgz \
		-C $(BUILD_DIR) firmware.bin manufacture.dat \
		-C $(FIRMWARE_DIR) openssl tf_recovery.img
	(cd $(BUILD_DIR) && md5sum firmware.tgz) >$(BUILD_DIR)/firmware.tgz.md5

clean:
	rm -rf $(BUILD_DIR)
