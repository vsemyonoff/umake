################################################################################
#
# Makefile
#
# Author: Vladyslav Semyonov
# E-mail: vsemyonoff [at] gmail.com
#
################################################################################

.SUFFIXES:

# Defalut phony target allow to add user defined targets in config file
.PHONY: all
all :

# Empty string constant
override EMPTY =

ifeq ($(strip $(CONFIGFILE)), $(EMPTY))

################################################################################

#
# PART #1: search for configuration files & run submake
#

    # Makefile's name and path
    override MAKEFILE = $(firstword $(MAKEFILE_LIST))
    # Configuration files search path
    override CONFIGSPATH = $(dir $(MAKEFILE))

    # Extend MAKE variable with proper makefile name
    override MAKE += --makefile $(MAKEFILE) --no-print-directory

    # Search all config files in makefile's folder
    override CONFIGSLIST = $(wildcard $(CONFIGSPATH)*.prj)
    ifeq ($(strip $(CONFIGSLIST)), $(EMPTY))
        override CONFIGSLIST = $(shell cd $(CONFIGSPATH) && pwd).prj
    endif

    # Divide input arguments to projects and actions
    override PROJECTS = $(filter $(notdir $(CONFIGSLIST:%.prj=%)), $(MAKECMDGOALS))
    ifeq ($(strip $(PROJECTS)), $(EMPTY))
        override PROJECTS = $(notdir $(CONFIGSLIST:%.prj=%))
    endif
    override ACTIONS = $(filter-out $(PROJECTS), $(MAKECMDGOALS))

    all: $(PROJECTS)

    .PHONY: $(ACTIONS)
    $(ACTIONS): $(PROJECTS)
		@echo "Reached target: $@"

    .PHONY: $(PROJECTS)
    $(PROJECTS): %: $(CONFIGSPATH)%.prj
		@$(MAKE) $(ACTIONS) CONFIGFILE=$<

    %.prj:
		@$(MAKE) config CONFIGFILE=$@

    # Projects dependencyes file
    sinclude depends.prg

else

################################################################################

#
# PART #2: process configuration files managed by PART #1
#

#
# Build init stuff
#

    # Configuration file's absolute path (resolve symlink if needed)
    override CONFIGPATH   = $(dir $(shell readlink -f $(CONFIGFILE)))
    # Project's short name
    override PROJECT      = $(basename $(notdir $(CONFIGFILE)))

#
# Process configuration settings
#

    sinclude $(CONFIGFILE)

    # Empty string constant (to be sure it is correct after inclusion)
    override EMPTY        =

    # Trail argument with slash function
    override trgslash     = $(strip $(filter %/, $(1)) $(addsuffix /, $(filter-out %/, $(1))))
    # Remove all unneeded local prepending slashes function
    override rmprplslash  = $(strip $(patsubst ./%, %, $(1)))
    # Remove all unneeded prepending slashes function
    override rmprpslash   = $(strip $(patsubst /%, %, $(call rmprplslash, $(1))))
    # Prepend argument with dot function
    override prpdot       = $(strip $(filter .%, $(1)) $(addprefix ., $(filter-out .%, $(1))))

    # Check extensions
    ifeq ($(strip $(CEXT)), $(EMPTY))
        override CEXT     = .c
    else
        override CEXT    := $(strip $(call prpdot, $(firstword $(CEXT))))
    endif
    ifeq ($(strip $(CXXEXT)), $(EMPTY))
        override CXXEXT   = .cpp
    else
        override CXXEXT  := $(strip $(call prpdot, $(firstword $(CXXEXT))))
    endif
    ifeq ($(strip $(ASEXT)), $(EMPTY))
        override ASEXT    = .asm
    else
        override ASEXT   := $(strip $(call prpdot, $(firstword $(ASEXT))))
    endif

    # Check C/C++ GCH lists
    override CGCH        := $(call rmprpslash, $(CGCH))
    override CXXGCH      := $(call rmprpslash, $(CXXGCH))

    # Check sourcedirs and sources lists
    override SOURCEDIRS  := $(call rmprpslash, $(call trgslash, $(SOURCEDIRS)))
    override SOURCES     := $(call rmprpslash, $(SOURCES))

    # Check output folders
    override BUILDROOT   := $(strip $(call trgslash, $(firstword $(BUILDROOT))))
    override DEPDIR       = $(BUILDROOT).dep/$(notdir $(basename $(CONFIGFILE)))/
    override CGCHDIR      = $(BUILDROOT).cgch/$(notdir $(basename $(CONFIGFILE)))/
    override CXXGCHDIR    = $(BUILDROOT).cxxgch/$(notdir $(basename $(CONFIGFILE)))/
    override OBJDIR       = $(BUILDROOT).obj/$(notdir $(basename $(CONFIGFILE)))/
    override OUTPUTDIR   := $(call rmprpslash, $(call trgslash, $(firstword $(OUTPUTDIR))))

    # Check target name
    ifeq ($(strip $(TARGET)), $(EMPTY))
        override TARGET   =  $(basename $(notdir $(CONFIGFILE)))
    else
        override TARGET  := $(notdir $(firstword $(TARGET)))
    endif

    # Check include and library paths
    override CPPINCPATH  := $(call rmprplslash, $(call trgslash, $(CPPINCPATH)))
    override ASINCPATH   := $(call rmprplslash, $(call trgslash, $(ASINCPATH)))
    override LIBRARYPATH := $(call rmprplslash, $(call trgslash, $(LIBRARYPATH)))

#
# Do not run this part while generating configuration file
#

    ifeq ($(filter config, $(MAKECMDGOALS)), $(EMPTY))

        # Do not check packages while cleaning folder
        ifeq ($(filter clean distclean, $(MAKECMDGOALS)), $(EMPTY))

            ifneq ($(strip $(REQUIREPKGS)), $(EMPTY))

                ifeq ($(shell which pkg-config 2> /dev/null), $(EMPTY))
                    override MESS = "No 'pkg-config' tool found."
                    $(error $(MESS))
                endif

                # Package name manipulation functions
                override pkgname  = $(strip $(foreach package, $(1), $(firstword $(subst :, , $(package)))))
                override pkgvers  = $(strip $(word 2, $(subst :, , $(firstword $(1)))))

                # First of all, we need to check each required 'pkg-config' package.
                override PKGLIST  = $(subst >=,--atleast-version=, $(REQUIREPKGS))
                override PKGLIST := $(subst ==,--exact-version=, $(PKGLIST))
                override PKGLIST := $(subst <=,--max-version=, $(PKGLIST))
                override RESULT   = $(foreach package, $(PKGLIST), \
                                       $(shell pkg-config $(call pkgvers, $(package)) \
                                           $(call pkgname, $(package)); \
                                               [ ! $$? == 0 ] &&  echo -n $(call pkgname, $(package))))
                ifneq ($(strip $(RESULT)), $(EMPTY))
                    override MESS = "$(RESULT): packages are not installed or has incompatible version number."
                    $(error $(MESS))
                else
                    # Get packages information
                    override PKGMACROS  = $(shell pkg-config --cflags-only-other $(call pkgname, $(PKGLIST)))
                    override PKGINCPATH = $(shell pkg-config --cflags-only-I $(call pkgname, $(PKGLIST)))
                    override PKGLIBPATH = $(shell pkg-config --libs-only-L $(call pkgname, $(PKGLIST)))
                    override PKGLIBS    = $(shell pkg-config --libs-only-l $(call pkgname, $(PKGLIST)))
                endif

            endif

        endif

#
# Generate sources list
#

        override EXTLIST  = $(CEXT) $(CXXEXT) $(ASEXT)
        override SRCLIST  = $(foreach ext, $(EXTLIST), \
                               $(foreach srcdir, $(addprefix $(CONFIGPATH), $(SOURCEDIRS)), \
                                   $(wildcard $(srcdir)*$(ext))))
        override SRCLIST += $(filter $(addprefix %, $(EXTLIST)), $(addprefix $(CONFIGPATH), $(SOURCES)))

        ifeq ($(strip $(SRCLIST)), $(EMPTY))
            override SRCLIST  = $(foreach ext, $(EXTLIST), $(wildcard $(CONFIGPATH)*$(ext)))
            ifeq ($(strip $(SRCLIST)), $(EMPTY))
                override MESS = "No sources files found. Update configuration file '$(CONFIGFILE)'."
                $(error $(MESS))
            endif
        endif

#
# Setup C/C++ precompiled headers lists
#
       override CGCHLIST    = $(addprefix $(CONFIGPATH), $(CGCH))
       override CXXGCHLIST  = $(addprefix $(CONFIGPATH), $(CXXGCH))

#
# Setup preprocessors flags
#

        # C preprocessor flags
        override CPPFLAGS  += $(filter %, $(FLAGSCPP) \
                                          $(addprefix -D, $(CPPMACROS)) \
                                          $(PKGMACROS) \
                                          $(addprefix -I, $(CGCHDIR)) \
                                          $(addprefix -I$(CONFIGPATH), $(filter-out /%, $(CPPINCPATH))) \
                                          $(addprefix -I, $(filter /%, $(CPPINCPATH))) \
                                          $(PKGINCPATH))

        # C++ preprocessor flags
        override CXXPPFLAGS = $(subst -I$(CGCHDIR),-I$(CXXGCHDIR), $(CPPFLAGS))

        # Assembler preprocessor flags
        override APPFLAGS  += $(filter %, $(addprefix -D, $(ASMACROS)) \
                                          $(addprefix -I$(CONFIGPATH), $(filter-out /%, $(ASINCPATH))) \
                                          $(addprefix -I, $(filter /%, $(ASINCPATH))))

#
# Setup compilers flags
#

        # C compiler flags
        override CFLAGS    += $(filter %, $(FLAGSC))
        # C++ compiler flags
        override CXXFLAGS  += $(filter %, $(FLAGSCXX))
        # Assembler compiler flags
        override ASFLAGS   += $(filter %, $(FLAGSAS))

#
# Setup linker flags
#

        override LDFLAGS   += $(filter %, $(FLAGSLD) \
                                          $(addprefix -L$(CONFIGPATH), $(filter-out /%, $(LIBRARYPATH))) \
                                          $(addprefix -L, $(filter /%, $(LIBRARYPATH))) \
                                          $(PKGLIBPATH) \
                                          $(addprefix -l, $(LIBRARIES)) \
                                          $(PKGLIBS))
#
# Setup internal variables
#

        # Filenames conversion functions
        override inc2cgch   = $(foreach inc, $(1), $(addprefix $(CGCHDIR), $(notdir $(inc)).gch))
        override inc2cxxgch = $(foreach inc, $(1), $(addprefix $(CXXGCHDIR), $(notdir $(inc)).gch))
        override src2obj    = $(foreach src, $(1), $(addprefix $(OBJDIR), $(notdir $(src)).o))

        override cgchdep    = $(foreach gch, $(1), $(addprefix $(DEPDIR), c_$(notdir $(gch)).d))
        override cxxgchdep  = $(foreach gch, $(1), $(addprefix $(DEPDIR), cxx_$(notdir $(gch)).d))
        override objdep     = $(foreach obj, $(1), $(addprefix $(DEPDIR), $(notdir $(obj)).d))

        override dep2cgch   = $(filter %$(patsubst c_%, %, $(basename $(notdir $(1)))), $(GCHC))
        override dep2cxxgch = $(filter %$(patsubst cxx_%, %, $(basename $(notdir $(1)))), $(GCHCXX))
        override cgch2inc   = $(filter %$(patsubst c_%, %, $(basename $(notdir $(1)))), $(CGCHLIST))
        override cxxgch2inc = $(filter %$(patsubst cxx_%, %, $(basename $(notdir $(1)))), $(CXXGCHLIST))
        override dep2cinc   = $(filter %$(patsubst c_%, %, $(patsubst %.gch.d, %, $(notdir $(1)))), $(CGCHLIST))
        override dep2cxxinc = $(filter %$(patsubst cxx_%, %, $(patsubst %.gch.d, %, $(notdir $(1)))), $(CXXGCHLIST))

        override dep2src    = $(filter %$(notdir $(patsubst %.o.d, %, $(1))), $(SRCLIST))
        override dep2obj    = $(strip $(subst $(DEPDIR),$(OBJDIR), $(basename $(1))))
        override obj2src    = $(filter %$(notdir $(basename $(1))), $(SRCLIST))

        # Intermediate files
        override GCHC       = $(call inc2cgch, $(CGCHLIST))
        override GCHCXX     = $(call inc2cxxgch, $(CXXGCHLIST))
        override OBJECTS    = $(call src2obj, $(SRCLIST))

        override DEPENDS    = $(filter %, $(call cgchdep, $(GCHC)) \
                                          $(call cxxgchdep, $(GCHCXX)) \
                                          $(call objdep, $(OBJECTS)))

        # Output folder
        override OUTDIR     = $(BUILDROOT)$(OUTPUTDIR)
        # Target's full name
        override OUTPUT     = $(OUTDIR)$(TARGET)

        # Use YASM for asm compilation and preprocessing
        override AS         = yasm

        # Select linker
        override LINKER     = $(LD)
        ifneq ($(filter %$(CEXT), $(SRCLIST)), $(EMPTY))
            override LINKER = $(CC)
        endif
        ifneq ($(filter %$(CXXEXT), $(SRCLIST)), $(EMPTY))
            override LINKER = $(CXX)
        endif

################################################################################

#
# PART #3: make rules for PART #2
#

#
# Build targets
#

        # Dependency files generation rules
        c_%.gch.d:
			@[ -d $(DEPDIR) ] || mkdir -p $(DEPDIR)
			@echo "Updating dependency file: $(call dep2cgch, $@) -> $@"
			@echo $(patsubst %:, \
						$(call dep2cgch, $@) $@: $(CONFIGFILE), \
							$(shell $(CC) -M $(CPPFLAGS) $(call dep2cinc, $@))) > $@

        cxx_%.gch.d:
			@[ -d $(DEPDIR) ] || mkdir -p $(DEPDIR)
			@echo "Updating dependency file: $(call dep2cxxgch, $@) -> $@"
			@echo $(patsubst %:, \
						$(call dep2cxxgch, $@) $@: $(CONFIGFILE), \
							$(shell $(CXX) -M $(CXXPPFLAGS) $(call dep2cxxinc, $@))) > $@

        %$(CEXT).o.d:
			@[ -d $(DEPDIR) ] || mkdir -p $(DEPDIR)
			@echo "Updating dependency file: $(call dep2obj, $@) -> $@"
			@echo $(patsubst %:, \
						$(call dep2obj, $@) $@: $(CONFIGFILE), \
							$(shell $(CC) -M $(CPPFLAGS) $(call dep2src, $@))) > $@

        %$(CXXEXT).o.d:
			@[ -d $(DEPDIR) ] || mkdir -p $(DEPDIR)
			@echo "Updating dependency file: $(call dep2obj, $@) -> $@"
			@echo $(patsubst %:, \
						$(call dep2obj, $@) $@: $(CONFIGFILE), \
							$(shell $(CXX) -M $(CXXPPFLAGS) $(call dep2src, $@))) > $@

        %$(ASEXT).o.d:
			@[ -d $(DEPDIR) ] || mkdir -p $(DEPDIR)
			@echo "Updating dependency file: $(call dep2obj, $@) -> $@"
			@echo $(patsubst %:, \
						$(call dep2obj, $@) $@: $(CONFIGFILE), \
							$(shell $(AS) -M $(APPFLAGS) $(call dep2src, $@))) > $@

        # Object files generation rules
        $(GCHC): %:
			@[ -d $(CGCHDIR) ] || mkdir -p $(CGCHDIR)
			$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $(call cgch2inc, $@)

        $(GCHCXX): %:
			@[ -d $(CXXGCHDIR) ] || mkdir -p $(CXXGCHDIR)
			$(CXX) $(CXXFLAGS) $(CXXPPFLAGS) -o $@ $(call cxxgch2inc, $@)

        %$(CEXT).o:
			@[ -d $(OBJDIR) ] || mkdir -p $(OBJDIR)
			$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $(call obj2src, $@)

        %$(CXXEXT).o:
			@[ -d $(OBJDIR) ] || mkdir -p $(OBJDIR)
			$(CXX) $(CXXFLAGS) $(CXXPPFLAGS) -c -o $@ $(call obj2src, $@)

        %$(ASEXT).o:
			@[ -d $(OBJDIR) ] || mkdir -p $(OBJDIR)
			$(AS) $(ASFLAGS) $(APPFLAGS) -o $@ $(call obj2src, $@)

        # Main target rules
        ifeq ($(filter clean distclean, $(MAKECMDGOALS)), $(EMPTY))
            sinclude $(DEPENDS)
        endif

        $(filter %$(CEXT).o, $(OBJECTS)): $(GCHC)

        $(filter %$(CXXEXT).o, $(OBJECTS)): $(GCHCXX)

        $(OUTPUT): $(OBJECTS)
			@[ -d $(OUTDIR) ] || mkdir -p $(OUTDIR)
			$(LINKER) -o $@ $^ $(LDFLAGS)

#
# Build actions (phony targets)
#

        # Previously defined as .PHONY
        all: $(OUTPUT)

        .PHONY: exec
        exec: $(OUTPUT)
			@exec $(TERMINAL) $(OUTPUT)

        .PHONY: distclean
        distclean: clean
			@$(RM) -v $(GCHC)
			@$(RM) -v $(GCHCXX)
			@$(RM) -v $(OUTPUT)

        .PHONY: clean
        clean:
			@$(RM) -v .cpptags
			@find . -name *~ -exec rm -v {} +
			@$(RM) -v $(OBJECTS)
			@$(RM) -v $(DEPENDS)

    endif # ifeq ($(filter config, $(MAKECMDGOALS)), $(EMPTY))

    .PHONY: config
    config:
		@echo "Updating configuration file: $(CONFIGFILE)"
		@echo "#" > $(CONFIGFILE)
		@echo "# Files settings" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# C sources extension (default: .c)" >> $(CONFIGFILE)
		@echo "CEXT         = $(CEXT)" >> $(CONFIGFILE)
		@echo "# C++ sources extension (default: .cpp)" >> $(CONFIGFILE)
		@echo "CXXEXT       = $(CXXEXT)" >> $(CONFIGFILE)
		@echo "# Assembler sources extension (default: .asm)" >> $(CONFIGFILE)
		@echo "ASEXT        = $(ASEXT)" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# C precompiled headers list" >> $(CONFIGFILE)
		@echo "CGCH         = $(CGCH)" >> $(CONFIGFILE)
		@echo "# C++ precompiled headers list" >> $(CONFIGFILE)
		@echo "CXXGCH       = $(CXXGCH)" >> $(CONFIGFILE)
		@echo "# Source folders list" >> $(CONFIGFILE)
		@echo "SOURCEDIRS   = $(SOURCEDIRS)" >> $(CONFIGFILE)
		@echo "# Space delimited list of source files" >> $(CONFIGFILE)
		@echo "SOURCES      = $(SOURCES)" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# Toplevel output folder (default: current folder)" >> $(CONFIGFILE)
		@echo "BUILDROOT    = $(BUILDROOT)" >> $(CONFIGFILE)
		@echo "# Where to put target? (default: BUILDROOT)" >> $(CONFIGFILE)
		@echo "OUTPUTDIR    = $(OUTPUTDIR)" >> $(CONFIGFILE)
		@echo "# Target name (default: parent folder's name)" >> $(CONFIGFILE)
		@echo "TARGET       = $(TARGET)" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "# Terminal settings" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "TERMNAME     = $(TERMNAME)" >> $(CONFIGFILE)
		@echo "TERMOPTIONS  = $(TERMOPTIONS)" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "# Preprocessors settings" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# C/C++ preprocessor flags" >> $(CONFIGFILE)
		@echo "FLAGSCPP     = $(FLAGSCPP)" >> $(CONFIGFILE)
		@echo "# C/C++ preprocessor macros definitions" >> $(CONFIGFILE)
		@echo "CPPMACROS    = $(CPPMACROS)" >> $(CONFIGFILE)
		@echo "# C/C++ preprocessor include files path" >> $(CONFIGFILE)
		@echo "CPPINCPATH   = $(CPPINCPATH)" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# Assembler preprocessor flags" >> $(CONFIGFILE)
		@echo "FLAGSAPP     = $(FLAGSAPP)" >> $(CONFIGFILE)
		@echo "# Assembler preprocessor macros definitions" >> $(CONFIGFILE)
		@echo "ASMACROS     = $(ASMACROS)" >> $(CONFIGFILE)
		@echo "# Assembler preprocessor include files path" >> $(CONFIGFILE)
		@echo "ASINCPATH    = $(ASINCPATH)" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "# Compilers settings" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# C compiler flags" >> $(CONFIGFILE)
		@echo "FLAGSC       = $(FLAGSC)" >> $(CONFIGFILE)
		@echo "# C++ compiler flags" >> $(CONFIGFILE)
		@echo "FLAGSCXX     = $(FLAGSCXX)" >> $(CONFIGFILE)
		@echo "# Assembler compiler flags" >> $(CONFIGFILE)
		@echo "FLAGSAS      = $(FLAGSAS)" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "# Linker settings" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# Linker flags" >> $(CONFIGFILE)
		@echo "FLAGSLD      = $(FLAGSLD)">> $(CONFIGFILE)
		@echo "# Dynamic libraries path" >> $(CONFIGFILE)
		@echo "LIBRARYPATH  = $(LIBRARYPATH)">> $(CONFIGFILE)
		@echo "# Dynamic libraries" >> $(CONFIGFILE)
		@echo "LIBRARIES    = $(LIBRARIES)" >> $(CONFIGFILE)
		@echo "# Required 'pkg-config' packages list (format: pkgname[:==|<=|>=version])" >> $(CONFIGFILE)
		@echo "REQUIREPKGS  = $(REQUIREPKGS)" >> $(CONFIGFILE)

endif # ifeq ($(strip $(CONFIGFILE)), $(EMPTY))
