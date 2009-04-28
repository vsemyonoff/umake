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

    sinclude depends.prg

else

    # Add trailing slash function
    trgslash = $(filter %/, $(1)) $(addsuffix /, $(filter-out %/, $(1)))
    # Configuration file's absolute path (resolve symlink if needed)
    override CONFIGPATH = $(dir $(shell readlink -f $(CONFIGFILE)))
    # Project's short name
    override PROJECT = $(basename $(notdir $(CONFIGFILE)))

    #
    # Some default values
    #
    DEPENDDIR = .dep
    OBJECTDIR = .obj
    FLAGSCXX  = -ggdb -pipe -pedantic -Wall

    sinclude $(CONFIGFILE)

    #
    # Process configuration file settings
    #
    ifeq ($(strip $(TARGET)), $(EMPTY))
        override TARGET =  $(notdir $(shell cd $(CONFIGPATH) && pwd))
    else
        override TARGET := $(patsubst /%, %, $(patsubst ./%, %, $(TARGET)))
    endif
    override SOURCEDIRS := $(patsubst /%, %, $(patsubst ./%, %, $(call trgslash, $(SOURCEDIRS))))
    override SOURCES := $(patsubst /%, %, $(patsubst ./%, %, $(SOURCES)))
    override INCLUDEPATH := $(patsubst /%, %, $(patsubst ./%, %, $(call trgslash, $(INCLUDEPATH))))
    override BUILDROOT := $(call trgslash, $(BUILDROOT))
    override OUTDPUTIR := $(patsubst /%, %, $(patsubst ./%, %, $(call trgslash, $(OUTPUTDIR))))
    override DEPENDDIR := $(patsubst /%, %, $(patsubst ./%, %, $(call trgslash, $(DEPENDDIR))))
    override OBJECTDIR := $(patsubst /%, %, $(patsubst ./%, %, $(call trgslash, $(OBJECTDIR))))
    override LIBRARYPATH := $(patsubst /%, %, $(patsubst ./%, %, $(call trgslash, $(LIBRARYPATH))))

    #
    # Generate sources list and process internal variables
    #
    ifeq ($(filter config, $(MAKECMDGOALS)), $(EMPTY))
        override SRCLIST = $(foreach srcdir, $(addprefix $(CONFIGPATH), $(SOURCEDIRS)), $(wildcard $(srcdir)*.cpp))
        override SRCLIST += $(addprefix $(CONFIGPATH), $(SOURCES))
        ifeq ($(strip $(SRCLIST)), $(EMPTY))
            override SRCLIST = $(wildcard $(CONFIGPATH)*.cpp)
            ifeq ($(strip $(SRCLIST)), $(EMPTY))
                MESS = "No sources found in '$(CONFIGPATH)'. Update configuration file '$(CONFIGFILE)'."
                $(error $(MESS))
            endif
        endif
    endif

    # Get 'pkg-config' information
    override PKGDEFINITIONS = $(foreach package, $(REQUIREPKGS), $(shell pkg-config --cflags-only-other $(package)))
    override PKGINCLUDEPATH = $(foreach package, $(REQUIREPKGS), $(shell pkg-config --cflags-only-I $(package)))
    override PKGLIBRARYPATH = $(foreach package, $(REQUIREPKGS), $(shell pkg-config --libs-only-L $(package)))
    override PKGLIBRARIES = $(foreach package, $(REQUIREPKGS), $(shell pkg-config --libs-only-l $(package)))

    # Extend system wide with configuration file's settings
    override CXXFLAGS += $(FLAGSCXX)
    override CPPFLAGS += $(FLAGSCPP) \
                         $(addprefix -D, $(DEFINITIONS)) \
                         $(PKGDEFINITIONS) \
                         $(addprefix -I$(CONFIGPATH), $(INCLUDEPATH)) \
                         $(PKGINCLUDEPATH)

    override LDFLAGS  += $(FLAGSLD) \
                         $(addprefix -L$(CONFIGPATH), $(LIBRARYPATH)) \
                         $(PKGLIBRARYPATH) \
                         $(addprefix -l, $(LIBRARIES)) \
                         $(PKGLIBRARIES)

    # Internal variables
    override OUTDIR = $(BUILDROOT)$(OUTPUTDIR)
    override DEPDIR = $(BUILDROOT)$(DEPENDDIR)
    override OBJDIR = $(BUILDROOT)$(OBJECTDIR)

    # Filenames conversions functions
    src2dep = $(addprefix $(DEPDIR), $(patsubst %.cpp, %.d, $(subst /,_, $(1))))
    dep2src = $(patsubst %.d, %.cpp, $(subst _,/, $(notdir $(1))))
    src2obj = $(addprefix $(OBJDIR), $(patsubst %.cpp, %.o, $(subst /,_, $(1))))
    obj2src = $(patsubst %.o, %.cpp, $(subst _,/, $(notdir $(1))))
    dep2obj = $(patsubst %.d, %.o, $(subst $(DEPDIR),$(OBJDIR), $(1)))
    obj2dep = $(patsubst %.o, %.d, $(subst $(OBJDIR),$(DEPDIR), $(1)))

    # Intermediate files
    DEPENDS = $(foreach src, $(SRCLIST), $(call src2dep, $(src)))
    OBJECTS = $(foreach src, $(SRCLIST), $(call src2obj, $(src)))

    # Fulle target name
    override OUTPUT = $(OUTDIR)$(TARGET)

    ################################################################################

    #
    # Build rules
    #
    $(OUTPUT): $(OBJECTS)
		@[ -d $(OUTDIR) ] || mkdir -p $(OUTDIR)
		$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

    %.d:
		@[ -d $(DEPDIR) ] || mkdir -p $(DEPDIR)
		@echo "Updating dependency file: $(call dep2src, $@) -> $@"
		@echo $(patsubst %.o:, $(call dep2obj, $@) $@: $(CONFIGFILE), $(shell $(CXX) -MM $(call dep2src, $@))) > $@

    %.o:
		@[ -d $(OBJDIR) ] || mkdir -p $(OBJDIR)
		$(CXX) $(CXXFLAGS) $(CPPFLAGS) -o $@ -c $(call obj2src, $@)

    ifeq ($(filter config clean distclean, $(MAKECMDGOALS)), $(EMPTY))
        sinclude $(DEPENDS)
    endif

    all: $(OUTPUT)

    #
    # Build actions
    #
    .PHONY: config
    config:
		@echo "Updating configuration file: $(CONFIGFILE)"
		@echo "#" > $(CONFIGFILE)
		@echo "# Files settings" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# ALL PATH SETTINGS ARE TREATED RELATIVE TO THIS CONFIGURATION FILE!!!"  >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# Project's target name" >> $(CONFIGFILE)
		@echo "TARGET       = $(TARGET)" >> $(CONFIGFILE)
		@echo "# Source folders list" >> $(CONFIGFILE)
		@echo "SOURCEDIRS   = $(SOURCEDIRS)" >> $(CONFIGFILE)
		@echo "# Space delimited list of source files" >> $(CONFIGFILE)
		@echo "SOURCES      = $(SOURCES)" >> $(CONFIGFILE)
		@echo "# Include files path" >> $(CONFIGFILE)
		@echo "INCLUDEPATH  = $(INCLUDEPATH)" >> $(CONFIGFILE)
		@echo "# Toplevel output folder (default: current directory)" >> $(CONFIGFILE)
		@echo "BUILDROOT    = $(BUILDROOT)" >> $(CONFIGFILE)
		@echo "# Where to put target? (default: current directory)" >> $(CONFIGFILE)
		@echo "OUTPUTDIR    = $(OUTPUTDIR)" >> $(CONFIGFILE)
		@echo "# Where to put dependency files? (default: current directory)" >> $(CONFIGFILE)
		@echo "DEPENDDIR    = $(DEPENDDIR)" >> $(CONFIGFILE)
		@echo "# Where to put object files? (default: current directory)" >> $(CONFIGFILE)
		@echo "OBJECTDIR    = $(OBJECTDIR)" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "# Terminal settings" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "TERMNAME     = $(TERMNAME)" >> $(CONFIGFILE)
		@echo "TERMOPTIONS  = $(TERMOPTIONS)" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "# Preprocessor, compiler, linker settings" >> $(CONFIGFILE)
		@echo "#" >> $(CONFIGFILE)
		@echo "" >> $(CONFIGFILE)
		@echo "# Preprocessor flags" >> $(CONFIGFILE)
		@echo "FLAGSCPP     = $(FLAGSCPP)" >> $(CONFIGFILE)
		@echo "# Preprocessor macros definitions" >> $(CONFIGFILE)
		@echo "DEFINITIONS  = $(DEFINITIONS)" >> $(CONFIGFILE)
		@echo "# Compiler flags" >> $(CONFIGFILE)
		@echo "FLAGSCXX     = $(FLAGSCXX)" >> $(CONFIGFILE)
		@echo "# Linker flags" >> $(CONFIGFILE)
		@echo "FLAGSLD      = $(FLAGSLD)">> $(CONFIGFILE)
		@echo "# Dynamic libraries path" >> $(CONFIGFILE)
		@echo "LIBRARYPATH  = $(LIBRARYPATH)">> $(CONFIGFILE)
		@echo "# Dynamic libraries" >> $(CONFIGFILE)
		@echo "LIBRARIES    = $(LIBRARIES)" >> $(CONFIGFILE)
		@echo "# Required 'pkg-config' packages list" >> $(CONFIGFILE)
		@echo "REQUIREPKGS  = $(REQUIREPKGS)" >> $(CONFIGFILE)

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

endif
