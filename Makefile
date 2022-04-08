
TOOLCHAINDIR := /usr/src/arm-linux-3.3/toolchain_gnueabi-4.4.0_ARMv5TE/usr/bin
PATH         := $(TOOLCHAINDIR):$(PATH)
TARGET       := arm-unknown-linux-uclibcgnueabi
PROCS        := $(shell nproc --all )

DOWNLOADCMD := curl -qs --http1.1 -L --retry 10 --output

TOPDIR         := $(CURDIR)
SOURCEDIR      := $(TOPDIR)/src
PREFIXDIR      := $(TOPDIR)/prefix
BUILDDIR       := $(TOPDIR)/build
TOOLSDIR       := $(TOPDIR)/tools

BUILDENV :=			\
	AR=$(TARGET)-ar		\
	AS=$(TARGET)-as		\
	CC=$(TARGET)-gcc	\
	CXX=$(TARGET)-g++	\
	LD=${TARGET}-ld		\
	LDSHARED="$(TARGET)-gcc -shared"		\
	NM=$(TARGET)-nm		\
	RANLIB=$(TARGET)-ranlib	\
	STRIP=$(TARGET)-strip	\
	CFLAGS="-fPIC"		\
	CPPFLAGS="-I$(PREFIXDIR)/include -L$(PREFIXDIR)/lib" \
	LDFLAGS=" -I$(PREFIXDIR)/include -L$(PREFIXDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags"

PATCHESDIR     := $(TOOLSDIR)/patches
GMLIBDIR       := $(TOOLSDIR)/gm_lib
RTSPDDIR       := $(TOOLSDIR)/rtsp_server
UTILSDIR       := $(TOOLSDIR)/utils

BINARIESDIR    := $(TOPDIR)/sdcard/firmware/bin
LIBRARIESDIR   := $(TOPDIR)/sdcard/firmware/lib

SOURCES        := $(TOPDIR)/sources.json

#################################################################
## Functions                                                   ##
#################################################################

include tools/make/functions.mk


#################################################################
## Results                                                     ##
#################################################################

LIBS :=					\
	$(BUILDDIR)/chuangmi_ircut	\
	$(BUILDDIR)/chuangmi_isp328	\
	$(BUILDDIR)/chuangmi_pwm	\
	$(BUILDDIR)/chuangmi_led	\
	$(BUILDDIR)/chuangmi_utils

UTILS :=				\
	$(BUILDDIR)/chuangmi_ctrl	\
	$(BUILDDIR)/take_snapshot	\
	$(BUILDDIR)/take_video		\
	$(BUILDDIR)/ir_cut		\
	$(BUILDDIR)/ir_led		\
	$(BUILDDIR)/blue_led		\
	$(BUILDDIR)/yellow_led		\
	$(BUILDDIR)/mirrormode		\
	$(BUILDDIR)/nightmode		\
	$(BUILDDIR)/flipmode		\
	$(BUILDDIR)/camera_adjust	\
	$(BUILDDIR)/auto_night_mode

GMUTILS :=				\
	$(BUILDDIR)/audio_playback	\
	$(BUILDDIR)/encode_with_osd	\
	$(BUILDDIR)/osd

THIRD_PARTY_SOFTWARE :=			\
	$(BUILDDIR)/zlib		\
	$(BUILDDIR)/popt		\
	$(BUILDDIR)/busybox		\
	$(BUILDDIR)/logrotate

libs: $(LIBS)

third-party: $(THIRD_PARTY_SOFTWARE)

utils: $(UTILS)

libs: $(LIBS)

gmutils: $(GMUTILS)

all:					\
	sources				\
	libs				\
	utils				\
	gmutils				\
	sdcard/config.cfg		\
	sdcard/manufacture.bin		\
	sdcard/firmware/etc/os-release	\
	$(BUILDDIR)/rtspd		\
	third-party

#################################################################
## DIRS                                                        ##
#################################################################

$(SOURCEDIR):
	@mkdir -p $(SOURCEDIR)

$(PREFIXDIR)/bin:
	@mkdir -p $(PREFIXDIR)/bin

$(PREFIXDIR)/sbin:
	@mkdir -p $(PREFIXDIR)/sbin

$(PREFIXDIR)/lib:
	@mkdir -p $(PREFIXDIR)/lib

#################################################################
## RTSPD                                                       ##
#################################################################

$(BUILDDIR)/rtspd: $(PREFIXDIR)/bin
	@mkdir -p $(BUILDDIR) $(TOOLSDIR)/bin
	cd $(RTSPDDIR)			\
	&& $(TARGET)-gcc		\
		-DLOG_USE_COLOR		\
		-Wall			\
		-I$(GMLIBDIR)/inc	\
		$(RTSPDDIR)/$(@F).c	\
		$(RTSPDDIR)/log/log.c	\
		$(RTSPDDIR)/librtsp.a	\
		-L$(GMLIBDIR)/lib	\
		-lpthread -lm -lrt -lgm -o $(TOOLSDIR)/bin/rtspd && \
		$(TARGET)-strip $(TOOLSDIR)/bin/rtspd
	@touch $@


#################################################################
## LIBS                                                        ##
#################################################################

$(BUILDDIR)/chuangmi_utils:
	$(call box,"Compiling miicam library $(@F)")
	@mkdir -p $(BUILDDIR)
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(TOOLSDIR)/lib/libchuangmi_utils.so -fPIC $(TOOLSDIR)/lib/chuangmi_utils.c
	@touch $@

$(BUILDDIR)/chuangmi_ircut: $(BUILDDIR)/chuangmi_utils
	$(call box,"Compiling miicam library $(@F)")
	@mkdir -p $(BUILDDIR)
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(TOOLSDIR)/lib/libchuangmi_ircut.so -fPIC $(TOOLSDIR)/lib/chuangmi_ircut.c
	@touch $@

$(BUILDDIR)/chuangmi_isp328: $(BUILDDIR)/chuangmi_utils
	$(call box,"Compiling miicam library $(@F)")
	@mkdir -p $(BUILDDIR)
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(TOOLSDIR)/lib/libchuangmi_isp328.so -fPIC $(TOOLSDIR)/lib/chuangmi_isp328.c
	@touch $@

$(BUILDDIR)/chuangmi_pwm: $(BUILDDIR)/chuangmi_utils
	$(call box,"Compiling miicam library $(@F)")
	@mkdir -p $(BUILDDIR)
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(TOOLSDIR)/lib/libchuangmi_pwm.so -fPIC $(TOOLSDIR)/lib/chuangmi_pwm.c
	@touch $@

$(BUILDDIR)/chuangmi_led: $(BUILDDIR)/chuangmi_utils
	$(call box,"Compiling miicam library $(@F)")
	@mkdir -p $(BUILDDIR)
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc -shared -o $(TOOLSDIR)/lib/libchuangmi_led.so -fPIC $(TOOLSDIR)/lib/chuangmi_led.c
	@touch $@


#################################################################
## UTILS                                                       ##
#################################################################

$(UTILS): $(PREFIXDIR)/bin $(LIBS) $(BUILDDIR)/popt
	$(call box,"Compiling miicam utility $(@F)")
	@mkdir -p $(BUILDDIR) $(TOOLSDIR)/bin
	CPPFLAGS="-I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib" \
	LDFLAGS=" -I$(TOOLSDIR)/lib -L$(TOOLSDIR)/lib -Wl,-rpath -Wl,/tmp/sd/firmware/lib -Wl,--enable-new-dtags" \
	$(TARGET)-gcc \
		-Wall \
		-o $(TOOLSDIR)/bin/$(@F) $(UTILSDIR)/$(@F).c \
		-I $(TOOLSDIR)/lib -L$(TOOLSDIR)/lib \
		-I $(PREFIXDIR)/include -L$(PREFIXDIR)/lib \
		-l popt            \
		-l chuangmi_ircut  \
		-l chuangmi_utils  \
		-l chuangmi_isp328 \
		-l chuangmi_led    \
		-l chuangmi_pwm
	@touch $(BUILDDIR)/$(@F)


#################################################################
## GM Utils                                                    ##
#################################################################

$(GMUTILS): $(BUILDDIR)/popt
	$(call box,"Compiling miicam libraries")
	@mkdir -p $(BUILDDIR) $(TOOLSDIR)/bin
	cd $(GMLIBDIR)			\
	&& $(TARGET)-gcc		\
		-Wall			\
		-I $(GMLIBDIR)/inc	\
		-I $(TOOLSDIR)/lib	\
		-I $(PREFIXDIR)/include	\
		-L $(TOOLSDIR)/lib	\
		-L $(GMLIBDIR)/lib	\
		-L $(PREFIXDIR)/lib	\
		-o $(TOOLSDIR)/bin/$(@F)\
		$(GMLIBDIR)/$(@F).c	\
		-l gm 			\
		-l m			\
		-l popt			\
		-l rt			\
		-l pthread		\
	&& $(TARGET)-strip $(TOOLSDIR)/bin/$(@F)
	@touch $@


#################################################################
## Firmware configuration files                                ##
#################################################################

sdcard/config.cfg:
	$(TOPDIR)/sdcard/firmware/scripts/configupdate $(TOPDIR)/sdcard/config.cfg

sdcard/manufacture.bin:
	tar -cf $(TOPDIR)/sdcard/manufacture.bin manufacture/test_drv

sdcard/firmware/etc/os-release:
	$(TOPDIR)/bin/print-version | tee $@


#################################################################
## Third party tools                                           ##
#################################################################

include tools/make/zlib.mk
include tools/make/libpopt.mk
include tools/make/busybox.mk
include tools/make/logrotate.mk
include tools/make/OUTPUT.mk


#################################################################
##                                                             ##
#################################################################

.PHONY: sources install images clean

sources:
	$(call box,"Downloading current third-party sources")
	$(TOPDIR)/bin/download-sources.py --file $(SOURCES)

install: all
	$(call box,"Running make install")
	@mkdir -p $(BINARIESDIR) $(LIBRARIESDIR) \
	\
	&& echo "*** Copying third party binaries and extras to $(BINARIESDIR)" \
	&& cd $(PREFIXDIR)/sbin && $(TARGET)-strip $(THIRD_PARTY_SBINS) && cp $(THIRD_PARTY_SBINS) $(BINARIESDIR)/. \
	&& cd $(PREFIXDIR)/bin  && $(TARGET)-strip $(THIRD_PARTY_BINS)  && cp $(THIRD_PARTY_BINS)  $(BINARIESDIR)/. \
	\
	&& echo "*** Copying third party libraries and extras to $(LIBRARIESDIR)" \
	&& cd $(PREFIXDIR)/lib  && $(TARGET)-strip $(THIRD_PARTY_LIBS) && cp $(THIRD_PARTY_LIBS) $(LIBRARIESDIR)/. \
	&& cd $(PREFIXDIR)/lib  && cp $(THIRD_PARTY_LIB_EXTRAS) $(LIBRARIESDIR)/. \
	\
	&& echo "*** Copying our own binaries to $(BINARIESDIR)" \
	&& cd $(TOOLSDIR)/bin   && find . -maxdepth 1 -type f -exec $(TARGET)-strip {} \; -exec cp {} $(BINARIESDIR)/. \; \
	\
	&& echo "*** Copying our own libraries to $(BINARIESDIR)" \
	&& cd $(TOOLSDIR)/lib   && find . -maxdepth 1 -type f -name '*.so' -exec $(TARGET)-strip {} \; -exec cp {} $(LIBRARIESDIR) \;


images: all install
	$(call box,"Running make images")
	@cd $(TOPDIR) \
	\
	&& echo "*** Removing older version of MiiCam.tgz and MiiCam.zip" \
	&& find $(TOPDIR) -maxdepth 1 -type f -name 'MiiCam.zip' -or -name 'MiiCam.tgz' -delete \
	\
	&& echo "*** Creating file listing before packing" \
	&& find $(TOPDIR)/sdcard -type f -exec md5sum {} \; > sdcard/firmware/etc/files.db \
	\
	&& echo "*** Creating zip archive of sdcard/ to MiiCam.zip" \
	&& zip -r --quiet MiiCam.zip README.md sdcard \
	\
	&& echo "*** Creating tar archive of sdcard/ to MiiCam.tgz" \
	&& tar czf MiiCam.tgz -C $(TOPDIR) README.md sdcard \
	\
	&& md5sum MiiCam.tgz > MiiCam.tgz.md5sum \
	&& md5sum MiiCam.zip > MiiCam.zip.md5sum \
	\
	&& echo "*** MiiCam.zip and MiiCam.tgz created"


clean:
	$(call box,"Running make clean")
	@cd $(TOPDIR) \
	\
	&& echo "*** Removing directories with build artifacts" \
	&& rm -rf $(BINARIESDIR) $(LIBRARIESDIR) $(PREFIXDIR) $(BUILDDIR) \
	\
	&& echo "*** Removing all own-brewed binaries" \
	&& find $(TOOLSDIR)/bin -maxdepth 1 -type f -delete \
	\
	&& echo "*** Removing all self-brewed libraries" \
	&& find $(TOOLSDIR)/lib -maxdepth 1 -type f -name '*.so' -delete

