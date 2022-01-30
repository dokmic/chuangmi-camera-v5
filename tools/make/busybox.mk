#################################################################
## BUSYBOX														##
#################################################################

BUSYBOXVERSION := $(shell cat $(SOURCES) | jq -r '.busybox.version' )
BUSYBOXARCHIVE := $(shell cat $(SOURCES) | jq -r '.busybox.archive' )
BUSYBOXURI     := $(shell cat $(SOURCES) | jq -r '.busybox.uri' )


#################################################################
##                                                             ##
#################################################################

$(BUILDDIR)/$(BUSYBOXARCHIVE): $(BUILDDIR)
	$(call box,"Downloading busybox source code")
	test -f $@ || $(DOWNLOADCMD) $@ $(BUSYBOXURI) || rm -f $@


#################################################################
##                                                             ##
#################################################################

$(BUILDDIR)/busybox: $(BUILDDIR)/$(BUSYBOXARCHIVE)
	$(call box,"Building busybox")
	@mkdir -p $(BUILDDIR) $(BUILDDIR)/bin $(BUILDDIR)/sbin && rm -rf $@-$(BUSYBOXVERSION)
	@tar -xjf $(BUILDDIR)/$(BUSYBOXARCHIVE) -C $(BUILDDIR)
	@cd $@-$(BUSYBOXVERSION) && \
	cp $(TOOLSDIR)/patches/busybox.config $@-$(BUSYBOXVERSION)/.config 	\
	&& $(BUILDENV)				    									\
		make ARCH=arm CROSS_COMPILE=$(TARGET)- -j$(PROCS)         		\
		&& make ARCH=arm CROSS_COMPILE=$(TARGET)- -j$(PROCS) install 	\
		&& mv $@-$(BUSYBOXVERSION)/_install/bin/busybox $(BUILDDIR)/bin
	@touch $@
	@rm -rf $@-$(BUSYBOXVERSION)


#################################################################
##                                                             ##
#################################################################
