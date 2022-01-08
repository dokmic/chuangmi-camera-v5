
## The third party binaries in prefix/sbin that should be stripped and copied to firmware/bin
THIRD_PARTY_SBINS :=	\
	fatlabel	\
	fsck.fat	\
	mkfs.fat	\
	dropbear	\
	logrotate

## The third party binaries in prefix/bin that should be stripped and copied to firmware/bin
THIRD_PARTY_BINS :=	\
	busybox	   	\
	clear	   	\
	dbclient   	\
	dropbearkey	\
	ffmpeg	   	\
	ffprobe	   	\
	filan		\
	fromdos		\
	infocmp		\
	jq		\
	lsof		\
	nano		\
	openssl		\
	procan		\
	rsync		\
	scp		\
	sftp-server	\
	socat		\
	strace		\
	tabs		\
	tic		\
	todos		\
	toe		\
	tput		\
	tset

## Extra tools and symlinks that should not be stripped but copied too
THIRD_PARTY_BIN_EXTRAS := 	\
	captoinfo		\
	infotocap		\
	reset

## Third party library files that should be stripped and copied to firmware/lib
THIRD_PARTY_LIBS :=			\
	libavcodec.so.58.18.100		\
	libavdevice.so.58.3.100		\
	libavfilter.so.7.16.100		\
	libavformat.so.58.12.100	\
	libavutil.so.56.14.100		\
	libcrypto.a			\
	libform.a			\
	libhistory.so.7.0		\
	libmenu.a			\
	libncurses++.a			\
	libncurses.a			\
	libpanel.a			\
	libpopt.so.0.0.0		\
	libpostproc.so.55.1.100		\
	libreadline.so.7.0		\
	libssl.a			\
	libswresample.so.3.1.100	\
	libswscale.so.5.1.100		\
	libx264.so.161			\
	libz.a				\
	libz.so.$(ZLIBVERSION)		\
	libjq.a				\
	libjq.so.1.0.4			\
	libonig.a			\
	libonig.so.4.0.0


## The symlinks to library files that should be copied to firmware/lib but not stripped
THIRD_PARTY_LIB_EXTRAS :=		\
	libjq.so			\
	libjq.so.1			\
	libonig.so			\
	libonig.so.4			\
	libavcodec.so			\
	libavcodec.so.58		\
	libavdevice.so			\
	libavdevice.so.58		\
	libavfilter.so			\
	libavfilter.so.7		\
	libavformat.so			\
	libavformat.so.58		\
	libavutil.so			\
	libavutil.so.56			\
	libhistory.so			\
	libhistory.so.7			\
	libpopt.so			\
	libpopt.so.0			\
	libpostproc.so			\
	libpostproc.so.55		\
	libreadline.so			\
	libreadline.so.7		\
	libswresample.so		\
	libswresample.so.3		\
	libswscale.so			\
	libswscale.so.5			\
	libx264.so			\
	libz.so				\
	libz.so.1

