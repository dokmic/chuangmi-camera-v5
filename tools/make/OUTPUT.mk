## The third party binaries in prefix/bin that should be stripped and copied to firmware/bin
THIRD_PARTY_BINS :=	\
	busybox

## Third party library files that should be stripped and copied to firmware/lib
THIRD_PARTY_LIBS :=			\
	libpopt.so.0.0.0		\
	libz.a				\
	libz.so.$(ZLIBVERSION)


## The symlinks to library files that should be copied to firmware/lib but not stripped
THIRD_PARTY_LIB_EXTRAS :=		\
	libpopt.so			\
	libpopt.so.0			\
	libz.so				\
	libz.so.1

