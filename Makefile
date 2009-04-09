################################################################################
#
# Makefile
#
# Author: Vladyslav Semyonov
# E-mail: vsemyonoff [at] gmail.com
#
################################################################################

ifeq ($(strip $(CONFIG)),)

# Toplevel build folder
BUILDROOT      = $(shell pwd)

CONFIGS        = $(wildcard *.prj)
ifeq ($(strip $(CONFIGS)),)
CONFIGS        = debug.prj
endif

TARGETS        = $(filter $(CONFIGS:%.prj=%), $(MAKECMDGOALS))
ifeq ($(strip $(TARGETS)),)
TARGETS        = $(CONFIGS:%.prj=%)
endif

ACTIONS        = $(filter-out $(TARGETS), $(MAKECMDGOALS))

.PHONY : all $(TARGETS) $(ACTIONS)
all $(ACTIONS) : $(TARGETS)

$(TARGETS) : % : %.prj
	@$(MAKE) --makefile $(BUILDROOT)/Makefile --no-print-directory \
		-C `readlink -m $< | xargs dirname` CONFIG=$< $(ACTIONS)

#%.prj :
#	@$(MAKE) CONFIG=$@ config

else

# Project name
PROJECT        = $(basename $(CONFIG))

# Default project settings
BINARY         = $(shell basename `pwd`)
BINARYDIR      = .
SOURCEDIR      = .
INCLUDEPATH    = .
DEPENDDIR      = .dep
OBJECTDIR      = .obj

# Default compiler flags
CXXFLAGS       := -ggdb -pipe -pedantic -Wall $(CXXFLAGS)

# Defalut target
all :

# Override default from project file
sinclude $(CONFIG)

#vpath %.cpp $(SOURCEDIR)
#vpath %.d $(DEPENDDIR)
#vpath %.o $(OBJECTDIR)

TARGET         = $(BINARYDIR)/$(BINARY)
FLAGSCPP       = $(CPPFLAGS) $(addprefix -D,$(DEFINITIONS)) $(addprefix -I,$(INCLUDEPATH))
FLAGSLD        = $(LDFLAGS) $(addprefix -L,$(LIBRARYPATH)) $(addprefix -l,$(LIBRARYES))

# Create sources list if not defined in project file
ifeq ($(strip $(SOURCES)),)
SOURCES        = $(notdir $(wildcard $(SOURCEDIR)/*.cpp))
endif
# Show warning about empty sources list
ifeq ($(strip $(SOURCES)),)
all : error
error :
	@echo "No sources found in the '$(SOURCEDIR)' directory."
	@echo "Set correct values for 'SOURCEDIR' and/or 'SOURCES' in '$(CONFIG)'."
endif

OBJECTS        = $(addprefix $(OBJECTDIR)/,$(SOURCES:%.cpp=%.o))
DEPENDS        = $(addprefix $(DEPENDDIR)/,$(SOURCES:%.cpp=%.d))

################################################################################

.PHONY : $(PROJECT) all config exec clean distclean

all : $(TARGET)

$(TARGET) $(PROJECT) : $(OBJECTS)
	@mkdir -p $(BINARYDIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(FLAGSLD)

$(OBJECTDIR)/%.o : $(SOURCEDIR)/%.cpp $(CONFIG)
	@mkdir -p $(OBJECTDIR)
	$(CXX) $(CXXFLAGS) $(FLAGSCPP) -o $@ -c $<

$(DEPENDDIR)/%.d : $(SOURCEDIR)/%.cpp
	@mkdir -p $(DEPENDDIR)
	@echo "Generating dependency: $< -> $@"
	@set -e; $(CPP) -MM $(FLAGSCPP) $< | \
	  sed 's/\($*\)\.o[ :]*/$(subst /,\/,$(OBJECTDIR))\/\1.o $(subst /,\/,$(DEPENDDIR))\/$(@F) : /g' \
	  > $@;

sinclude $(DEPENDS)

exec : $(TARGET)
	@exec $(TERMINAL) $(TARGET)

distclean : clean
	@$(RM) -v $(TARGET)
	@if [ ! $(BINARYDIR) == "." ]; then $(RM) -rv $(BINARYDIR); fi

clean :
	@$(RM) -v .cpptags
	@find . -name *~ -exec rm -v {} +
	@$(RM) -v $(OBJECTS)
	@if [ ! $(OBJECTDIR) == "." ]; then $(RM) -rv $(OBJECTDIR); fi
	@$(RM) -v $(DEPENDS)
	@if [ ! $(DEPENDDIR) == "." ]; then $(RM) -rv $(DEPENDDIR); fi

$(CONFIG) config :
	@echo "Generating project file: $(CONFIG)"
	@echo "#" > $(CONFIG)
	@echo "#" Project settings >> $(CONFIG)
	@echo "#" >> $(CONFIG)
	@echo "" >> $(CONFIG)
	@echo "# Target binary name (default: project's directory name)" >> $(CONFIG)
	@echo "BINARY       = $(BINARY)" >> $(CONFIG)
	@echo "# Projects directoryes (default: current directory)" >> $(CONFIG)
	@echo "BINARYDIR    = $(BINARYDIR)" >> $(CONFIG)
	@echo "SOURCEDIR    = $(SOURCEDIR)" >> $(CONFIG)
	@echo "OBJECTDIR    = $(OBJECTDIR)" >> $(CONFIG)
	@echo "DEPENDDIR    = $(DEPENDDIR)" >> $(CONFIG)
	@echo "# Space delimited list of source files (default: *.cpp files in SOURCEDIR)" >> $(CONFIG)
	@echo "#SOURCES      = " >> $(CONFIG)
	@echo "# Terminal settings (default: run without terminal)" >> $(CONFIG)
	@echo "TERMNAME     = $(TERMNAME)" >> $(CONFIG)
	@echo "TERMOPTIONS  = $(TERMOPTIONS)" >> $(CONFIG)
	@echo "" >> $(CONFIG)
	@echo "#" >> $(CONFIG)
	@echo "# Preprocessor, compiler, linker settings" >> $(CONFIG)
	@echo "#" >> $(CONFIG)
	@echo "" >> $(CONFIG)
	@echo "# Compiler flags" >> $(CONFIG)
	@echo "CXXFLAGS     = $(CXXFLAGS)" >> $(CONFIG)
	@echo "# Preprocessor flags" >> $(CONFIG)
	@echo "CPPFLAGS     = $(CPPFLAGS)" >> $(CONFIG)
	@echo "# Macros definitions (space delimited)" >> $(CONFIG)
	@echo "DEFINITIONS  = $(DEFINITIONS)" >> $(CONFIG)
	@echo "# Include files path (space delimited)" >> $(CONFIG)
	@echo "INCLUDEPATH  = $(INCLUDEPATH)" >> $(CONFIG)
	@echo "# Linker flags" >> $(CONFIG)
	@echo "LDFLAGS      = $(LDFLAGS)">> $(CONFIG)
	@echo "# Dynamic libraryes path (space delimited)" >> $(CONFIG)
	@echo "LIBRARYPATH  = $(LIBRARYPATH)">> $(CONFIG)
	@echo "# Dynamic libraryes (space delimited)" >> $(CONFIG)
	@echo "LIBRARYES    = $(LIBRARYES)" >> $(CONFIG)

endif
