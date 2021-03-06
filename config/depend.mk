all::	INIT $(ALLTRG)
		+$(LOOP_SUBDIRS)

clean::
ifdef CLEANFILES
		rm -f $(CLEANFILES)
endif
ifdef CLEANDIRS
		rm -rf $(CLEANDIRS)
endif
		+$(LOOP_SUBDIRS)

clobber::
ifdef CLOBBERFILES
		rm -f $(CLOBBERFILES)
endif
ifdef CLOBBERDIRS
		rm -rf $(CLOBBERDIRS)
endif
		+$(LOOP_SUBDIRS)

INIT::

FORCE:

# include dependencies if we are not cleaning or clobbering
ifneq ($(findstring clean,$(MAKECMDGOALS)),clean)
ifneq ($(findstring clobber,$(MAKECMDGOALS)),clobber)
-include $(BLTDEP)
endif
endif

# macro to construct needed target directories
define CHKDIR
if test ! -d $(@D); then mkdir $(@D); else true; fi
endef

# macro which recurses into SUBDIRS
ifdef SUBDIRS
LOOP_SUBDIRS = \
	@for d in $(SUBDIRS); do \
		set -e; \
		echo "cd $$d; $(MAKE) $@"; \
		$(MAKE) -C $$d $@; \
		set +e; \
	done
endif

$(BLTPRGEXE):	$(BLTPRGOBJ) $(BLTGENOBJ) $(BLTPBOBJ)
	@$(CHKDIR)
	$(LDCMD) -o $@ $(CPPFLAGS) $(DEFS) $(LDFLAGS) $(INCS) $(BLTPRGOBJ) $(BLTGENOBJ) $(BLTPBOBJ) $(LIBS)

$(BLTLIBA):		$(BLTLIBOBJ) $(BLTGENOBJ)
	@$(CHKDIR)
	$(ARCMD) $(ARFLAGS) -o $@ $(BLTLIBOBJ) $(BLTGENOBJ)

$(BLTGENSRC):	$(THRIFTSRC)
	@$(CHKDIR)
	thrift -gen cpp -out $(GENDIR) $(THRIFTSRC)

$(OBJDIR)/%.o:		%.cpp
	@$(CHKDIR)
	$(CPPCMD) -c $< -o $@ $(CPPFLAGS) $(DEFS) $(INCS)

# Generated C++ objects.
$(OBJDIR)/%.o:		$(GENDIR)/%.cpp
	@$(CHKDIR)
	$(CPPCMD) -c $< -o $@ $(CPPFLAGS) $(DEFS) $(INCS)

$(OBJDIR)/%.d:		%.cpp
	@$(CHKDIR)
	@echo "Updating dependencies for $<"
	@set -e; $(CPPCMD) -MM $< $(CPPFLAGS) $(DEFS) $(INCS) | \
	egrep -v $(DEPFLT) | \
	perl -p -e 's#(\S+.o)\s*:#$(@D)/$$1 $@: #g' > $@; \
	[ -s $@ ] || rm -f $@

$(OBJDIR)/%.d:		$(GENDIR)/%.cpp
	@$(CHKDIR)
	@echo "Updating dependencies for $<"
	@set -e; $(CPPCMD) -MM $< $(CPPFLAGS) $(DEFS) $(INCS) | \
	egrep -v $(DEPFLT) | \
	perl -p -e 's#(\S+.o)\s*:#$(@D)/$$1 $@: #g' > $@; \
	[ -s $@ ] || rm -f $@

$(GENDIR)/%.pb.h $(GENDIR)/%.pb.cpp:	%.proto
	@$(CHKDIR)
	mkdir -p $(OBJDIR)
	$(PROTOC) --cpp_out=$(GENDIR) \
              --descriptor_set_out=$(OBJDIR)/$*.fds $< && \
		mv $(GENDIR)/$*.pb.cc $(GENDIR)/$*.pb.cpp

$(BLTDEP):	$(GENHDRSRC)

.PRECIOUS:		$(GENHDRSRC)
