#################################################################
## ZLIB														##
#################################################################

ZLIBVERSION := $(shell cat $(SOURCES) | jq -r '.zlib.version' )
ZLIBARCHIVE := $(shell cat $(SOURCES) | jq -r '.zlib.archive' )
ZLIBURI     := $(shell cat $(SOURCES) | jq -r '.zlib.uri' )


#################################################################
##                                                             ##
#################################################################

$(BUILDDIR)/$(ZLIBARCHIVE): $(BUILDDIR)
	$(call box,"Downloading zlib source code")
	test -f $@ || $(DOWNLOADCMD) $@ $(ZLIBURI) || rm -f $@


#################################################################
##                                                             ##
#################################################################

$(BUILDDIR)/zlib: $(BUILDDIR)/$(ZLIBARCHIVE)
	$(call box,"Building zlib")
	@mkdir -p $(BUILDDIR) && rm -rf $@-$(ZLIBVERSION)
	@tar -xzf $(BUILDDIR)/$(ZLIBARCHIVE) -C $(BUILDDIR)
	@cd $@-$(ZLIBVERSION)			\
	&& $(BUILDENV)					\
		./configure					\
			--prefix=$(BUILDDIR)	\
			--enable-shared			\
		&& make -j$(PROCS)			\
		&& make -j$(PROCS) install
	@rm -rf $@-$(ZLIBVERSION)
	@touch $@


#################################################################
##                                                             ##
#################################################################
