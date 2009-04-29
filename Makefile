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
    override CONFIGPATH = $(dir $(shell readlink -f $(CONFIGFILE)))
    # Project's short name
    override PROJECT    = $(basename $(notdir $(CONFIGFILE)))

#
# Process configuration settings
#

    sinclude $(CONFIGFILE)

    # Empty string constant (to be sure it is correct after inclusion)
    override EMPTY =

    # Trail argument with slash function
    override trgslash    = $(strip $(filter %/, $(1)) $(addsuffix /, $(filter-out %/, $(1))))
    # Remove all unneeded local prepending slashes function
    override rmprplslash = $(strip $(patsubst ./%, %, $(1)))
    # Remove all unneeded prepending slashes function
    override rmprpslash  = $(strip $(patsubst /%, %, $(call rmprplslash, $(1))))
    # Prepend argument with dot function
    override prpdot      = $(strip $(filter .%, $(1)) $(addprefix ., $(filter-out .%, $(1))))

    ifeq ($(strip $(CEXT)), $(EMPTY))
        override CEXT =  .c
    else
        override CEXT := $(strip $(call prpdot, $(firstword $(CEXT))))
    endif
    ifeq ($(strip $(CXXEXT)), $(EMPTY))
        override CXXEXT =  .cpp
    else
        override CXXEXT := $(strip $(call prpdot, $(firstword $(CXXEXT))))
    endif
    ifeq ($(strip $(ASEXT)), $(EMPTY))
        override ASEXT =  .asm
    else
        override ASEXT := $(strip $(call prpdot, $(firstword $(ASEXT))))
    endif
    ifeq ($(strip $(TARGET)), $(EMPTY))
        override TARGET =  $(notdir $(shell cd $(CONFIGPATH) && pwd))
    else
        override TARGET := $(notdir $(firstword $(TARGET)))
    endif
    override SOURCEDIRS := $(call rmprpslash, $(call trgslash, $(SOURCEDIRS)))
    override SOURCES    := $(call rmprpslash, $(SOURCES))
    override CPPINCPATH := $(call rmprplslash, $(call trgslash, $(CPPINCPATH)))
    override ASINCPATH  := $(call rmprplslash, $(call trgslash, $(ASINCPATH)))
    override BUILDROOT  := $(strip $(call trgslash, $(firstword $(BUILDROOT))))
    override OUTPUTDIR  := $(call rmprpslash, $(call trgslash, $(firstword $(OUTPUTDIR))))
    ifeq ($(strip $(DEPENDDIR)), $(EMPTY))
        override DEPENDDIR = .dep/
    else
        override DEPENDDIR := $(call rmprpslash, $(call trgslash, $(firstword $(DEPENDDIR))))
    endif
    ifeq ($(strip $(OBJECTDIR)), $(EMPTY))
        override OBJECTDIR = .obj/
    else
        override OBJECTDIR := $(call rmprpslash, $(call trgslash, $(firstword $(OBJECTDIR))))
    endif
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
                override pkgname = $(strip $(foreach package, $(1), $(firstword $(subst :, , $(package)))))
                override pkgvers = $(strip $(word 2, $(subst :, , $(firstword $(1)))))

                # First of all, we need to check each required 'pkg-config' package.
                override PKGLIST = $(subst >=,--atleast-version=, $(REQUIREPKGS))
                override PKGLIST := $(subst ==,--exact-version=, $(PKGLIST))
                override PKGLIST := $(subst <=,--max-version=, $(PKGLIST))
                override RESULT  = $(foreach package, $(PKGLIST), \
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

        override EXTLIST = $(CEXT) $(CXXEXT) $(ASEXT)
        override SRCLIST = $(foreach ext, $(EXTLIST), $(foreach srcdir, $(addprefix $(CONFIGPATH), $(SOURCEDIRS)), $(wildcard $(srcdir)*$(ext))))
        override SRCLIST += $(filter $(addprefix %, $(EXTLIST)), $(addprefix $(CONFIGPATH), $(SOURCES)))
        ifeq ($(strip $(SRCLIST)), $(EMPTY))
            override SRCLIST = $(foreach ext, $(EXTLIST), $(wildcard $(CONFIGPATH)*.$(ext)))
            ifeq ($(strip $(SRCLIST)), $(EMPTY))
                override MESS = "No sources files found. Update configuration file '$(CONFIGFILE)'."
                $(error $(MESS))
            endif
        endif

#
# Setup preprocessors flags
#

        # C/C++ preprocessor flags
        override CPPFLAGS += $(strip $(strip $(FLAGSCPP)) \
                                     $(addprefix -D, $(CPPMACROS)) \
                                     $(PKGMACROS) \
                                     $(addprefix -I$(CONFIGPATH), $(filter-out /%, $(CPPINCPATH))) \
                                     $(addprefix -I, $(filter /%, $(CPPINCPATH))) \
                                     $(PKGINCPATH) \
                               )
        # Assembler preprocessor flags
        override APPFLAGS += $(strip $(addprefix -D, $(ASMACROS)) \
                                     $(addprefix -I$(CONFIGPATH), $(filter-out /%, $(ASINCPATH))) \
                                     $(addprefix -I, $(filter /%, $(ASINCPATH))) \
                               )

#
# Setup compilers flags
#

        # C compiler flags
        override CFLAGS   += $(strip $(FLAGSC))
        # C++ compiler flags
        override CXXFLAGS += $(strip $(FLAGSCXX))
        # Assembler compiler flags
        override ASFLAGS  += $(strip $(FLAGSAS))

#
# Setup linker flags
#

        override LDFLAGS  += $(strip $(strip $(FLAGSLD)) \
                                     $(addprefix -L$(CONFIGPATH), $(filter-out /%, $(LIBRARYPATH))) \
                                     $(addprefix -L, $(filter /%, $(LIBRARYPATH))) \
                                     $(PKGLIBPATH) \
                                     $(addprefix -l, $(LIBRARIES)) \
                                     $(PKGLIBS) \
                               )
#
# Setup internal variables
#

        # Output folders
        override OUTDIR = $(BUILDROOT)$(OUTPUTDIR)
        override DEPDIR = $(BUILDROOT)$(DEPENDDIR)
        override OBJDIR = $(BUILDROOT)$(OBJECTDIR)

        # Filenames conversions functions
        override src2dep = $(strip $(addprefix $(DEPDIR), $(subst /,_, $(1)).d))
        override src2obj = $(strip $(addprefix $(OBJDIR), $(subst /,_, $(1)).o))
        override dep2src = $(strip $(patsubst %.d, %, $(subst _,/, $(notdir $(1)))))
        override obj2src = $(strip $(patsubst %.o, %, $(subst _,/, $(notdir $(1)))))
        override dep2obj = $(strip $(patsubst %.d, %.o, $(subst $(DEPDIR),$(OBJDIR), $(1))))
        override obj2dep = $(strip $(patsubst %.o, %.d, $(subst $(OBJDIR),$(DEPDIR), $(1))))

        # Intermediate files
        override DEPENDS = $(foreach src, $(SRCLIST), $(call src2dep, $(src)))
        override OBJECTS = $(foreach src, $(SRCLIST), $(call src2obj, $(src)))

        # Target's full name
        override OUTPUT = $(OUTDIR)$(TARGET)

        # We will use YASM for assembler cources compilation
        override AS = yasm

        # Select linker
        override LINKER = $(LD)
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

        $(OUTPUT): $(OBJECTS)
			@[ -d $(OUTDIR) ] || mkdir -p $(OUTDIR)
			$(LINKER) -o $@ $^ $(LDFLAGS)

        %$(CEXT).d:
			@[ -d $(DEPDIR) ] || mkdir -p $(DEPDIR)
			@echo "Updating dependency file: $(call dep2src, $@) -> $@"
			@echo $(patsubst %:, \
						$(call dep2obj, $@) $@: $(CONFIGFILE), \
							$(shell $(CC) -MM $(CPPFLASG) $(call dep2src, $@))) > $@

        %$(CXXEXT).d:
			@[ -d $(DEPDIR) ] || mkdir -p $(DEPDIR)
			@echo "Updating dependency file: $(call dep2src, $@) -> $@"
			@echo $(patsubst %:, \
						$(call dep2obj, $@) $@: $(CONFIGFILE), \
							$(shell $(CXX) -MM $(CPPFLAGS) $(call dep2src, $@))) > $@

        %$(ASEXT).d:
			@[ -d $(DEPDIR) ] || mkdir -p $(DEPDIR)
			@echo "Updating dependency file: $(call dep2src, $@) -> $@"
			@echo $(patsubst %:, \
						$(call dep2obj, $@) $@: $(CONFIGFILE), \
							$(shell $(AS) -MM $(APPFLAGS) $(call dep2src, $@))) > $@

        %$(CEXT).o:
			@[ -d $(OBJDIR) ] || mkdir -p $(OBJDIR)
			$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ -c $(call obj2src, $@)

        %$(CXXEXT).o:
			@[ -d $(OBJDIR) ] || mkdir -p $(OBJDIR)
			$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $(call obj2src, $@)

        %$(ASEXT).o:
			@[ -d $(OBJDIR) ] || mkdir -p $(OBJDIR)
			$(AS) $(ASFLAGS) $(APPFLAGS) -o $@ $(call obj2src, $@)

        ifeq ($(filter clean distclean, $(MAKECMDGOALS)), $(EMPTY))
            sinclude $(DEPENDS)
        endif


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
		@echo "# ALL PATH SETTINGS ARE TREATED RELATIVE TO THIS CONFIGURATION FILE!!!"  >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# C sources extension (default: .c)" >> $(CONFIGFILE)
		@echo "CEXT         = $(CEXT)" >> $(CONFIGFILE)
		@echo "# C++ sources extension (default: .cpp)" >> $(CONFIGFILE)
		@echo "CXXEXT       = $(CXXEXT)" >> $(CONFIGFILE)
		@echo "# Assembler sources extension (default: .asm)" >> $(CONFIGFILE)
		@echo "ASEXT        = $(ASEXT)" >> $(CONFIGFILE)
		@echo "# Source folders list" >> $(CONFIGFILE)
		@echo "SOURCEDIRS   = $(SOURCEDIRS)" >> $(CONFIGFILE)
		@echo "# Space delimited list of source files" >> $(CONFIGFILE)
		@echo "SOURCES      = $(SOURCES)" >> $(CONFIGFILE)
		@echo "# C/C++ preprocessor include files path" >> $(CONFIGFILE)
		@echo "CPPINCPATH   = $(CPPINCPATH)" >> $(CONFIGFILE)
		@echo "# Assembler preprocessor include files path" >> $(CONFIGFILE)
		@echo "ASINCPATH    = $(ASINCPATH)" >> $(CONFIGFILE)
		@echo "# Toplevel output folder (default: current folder" >> $(CONFIGFILE)
		@echo "BUILDROOT    = $(BUILDROOT)" >> $(CONFIGFILE)
		@echo "# Target name (default: parent folder's name)" >> $(CONFIGFILE)
		@echo "TARGET       = $(TARGET)" >> $(CONFIGFILE)
		@echo "# Where to put target? (default: BUILDROOT)" >> $(CONFIGFILE)
		@echo "OUTPUTDIR    = $(OUTPUTDIR)" >> $(CONFIGFILE)
		@echo "# Where to put dependency files? (default: BUILDROOT/.dep/)" >> $(CONFIGFILE)
		@echo "DEPENDDIR    = $(DEPENDDIR)" >> $(CONFIGFILE)
		@echo "# Where to put object files? (default: BUILDROOT/.obj/)" >> $(CONFIGFILE)
		@echo "OBJECTDIR    = $(OBJECTDIR)" >> $(CONFIGFILE)
		@echo "# Dynamic libraries path" >> $(CONFIGFILE)
		@echo "LIBRARYPATH  = $(LIBRARYPATH)">> $(CONFIGFILE)
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
		@echo "# Assembler preprocessor flags" >> $(CONFIGFILE)
		@echo "FLAGSAPP     = $(FLAGSAPP)" >> $(CONFIGFILE)
		@echo "# Assembler preprocessor macros definitions" >> $(CONFIGFILE)
		@echo "ASMACROS     = $(ASMACROS)" >> $(CONFIGFILE)
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
		@echo "# Dynamic libraries" >> $(CONFIGFILE)
		@echo "LIBRARIES    = $(LIBRARIES)" >> $(CONFIGFILE)
		@echo "# Required 'pkg-config' packages list (format: pkgname[:==|<=|>=version])" >> $(CONFIGFILE)
		@echo "REQUIREPKGS  = $(REQUIREPKGS)" >> $(CONFIGFILE)

endif # ifeq ($(strip $(CONFIGFILE)), $(EMPTY))
