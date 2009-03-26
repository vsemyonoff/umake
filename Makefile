#
# Universal GNU Makefile
#    Author: Vladyslav Semyonov
#    E-mail: vsemyonoff@gmail.com
#
# Usage:
#    Copy this file to a project's directory, type 'make',
#    edit .prj file & type 'make' again. See .prj file for details.
#    Available targets: project(default if not exists .prj file), exec, clean, distclean.
#

# Default project settings
BINARY         = $(shell basename `pwd`)
BINARYDIR      = .
SOURCEDIR      = src
INCLUDEPATH    = inclue
DEPENDDIR      = .dep
OBJECTDIR      = .obj

# Default compiler flags
CXXFLAGS       := -ggdb -pipe -pedantic -Wall $(CXXFLAGS)

# Default project file
PROJECT        = $(firstword $(wildcard *.prj))
ifeq ($(strip $(PROJECT)),)
PROJECT        = $(shell basename `pwd`).prj
endif
# Override default from project file
sinclude $(PROJECT)

TARGET         = $(BINARYDIR)/$(BINARY)
FLAGSCPP       = $(CPPFLAGS) $(addprefix -D,$(DEFINITIONS)) $(addprefix -I,$(INCLUDEPATH))
FLAGSLD        = $(LDFLAGS) $(addprefix -L,$(LIBRARYPATH)) $(addprefix -l,$(LIBRARYES))
TERMINAL       = $(TERMNAME) $(TERMOPTIONS)

# Create sources list if not defined in project file
ifeq ($(strip $(SOURCES)),)
SOURCES        = $(notdir $(wildcard $(SOURCEDIR)/*.cpp))
endif
# Show warning about empty sources list
ifeq ($(strip $(SOURCES)),)
warning :
	@echo "No sources found in the '$(SOURCEDIR)' directory."
	@echo "Set correct values for 'SOURCEDIR' and/or 'SOURCES' in '$(PROJECT)'."
endif

OBJECTS        = $(addprefix $(OBJECTDIR)/,$(SOURCES:.cpp=.o))
DEPENDS        = $(addprefix $(DEPENDDIR)/,$(SOURCES:.cpp=.d))

################################################################################

.PHONY : all exec clean distclean project

all : $(TARGET) $(PROJECT)

$(TARGET) : $(OBJECTS)
	@mkdir -p $(BINARYDIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(FLAGSLD)

$(OBJECTDIR)/%.o : $(SOURCEDIR)/%.cpp $(PROJECT)
	@mkdir -p $(OBJECTDIR)
	$(CXX) $(CXXFLAGS) $(FLAGSCPP) -o $@ -c $<

$(DEPENDDIR)/%.d : $(SOURCEDIR)/%.cpp
	@mkdir -p $(DEPENDDIR)
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

$(PROJECT) project :
	@echo "Generating project file: $(PROJECT)"
	@echo "#" > $(PROJECT)
	@echo "#" Project settings >> $(PROJECT)
	@echo "#" >> $(PROJECT)
	@echo "" >> $(PROJECT)
	@echo "# Target binary name (default: project's directory name)" >> $(PROJECT)
	@echo "BINARY       = $(BINARY)" >> $(PROJECT)
	@echo "# Projects directoryes (default: current directory)" >> $(PROJECT)
	@echo "BINARYDIR    = $(BINARYDIR)" >> $(PROJECT)
	@echo "SOURCEDIR    = $(SOURCEDIR)" >> $(PROJECT)
	@echo "OBJECTDIR    = $(OBJECTDIR)" >> $(PROJECT)
	@echo "DEPENDDIR    = $(DEPENDDIR)" >> $(PROJECT)
	@echo "# Space delimited list of source files (default: *.cpp files in SOURCEDIR)" >> $(PROJECT)
	@echo "#SOURCES      = " >> $(PROJECT)
	@echo "# Terminal settings (default: run without terminal)" >> $(PROJECT)
	@echo "TERMNAME     = $(TERMNAME)" >> $(PROJECT)
	@echo "TERMOPTIONS  = $(TERMOPTIONS)" >> $(PROJECT)
	@echo "" >> $(PROJECT)
	@echo "#" >> $(PROJECT)
	@echo "# Preprocessor, compiler, linker settings" >> $(PROJECT)
	@echo "#" >> $(PROJECT)
	@echo "" >> $(PROJECT)
	@echo "# Compiler flags" >> $(PROJECT)
	@echo "CXXFLAGS     = $(CXXFLAGS)" >> $(PROJECT)
	@echo "# Preprocessor flags" >> $(PROJECT)
	@echo "CPPFLAGS     = $(CPPFLAGS)" >> $(PROJECT)
	@echo "# Macros definitions (space delimited)" >> $(PROJECT)
	@echo "DEFINITIONS  = $(DEFINITIONS)" >> $(PROJECT)
	@echo "# Include files path (space delimited)" >> $(PROJECT)
	@echo "INCLUDEPATH  = $(INCLUDEPATH)" >> $(PROJECT)
	@echo "# Linker flags" >> $(PROJECT)
	@echo "LDFLAGS      = $(LDFLAGS)">> $(PROJECT)
	@echo "# Dynamic libraryes path (space delimited)" >> $(PROJECT)
	@echo "LIBRARYPATH  = $(LIBRARYPATH)">> $(PROJECT)
	@echo "# Dynamic libraryes (space delimited)" >> $(PROJECT)
	@echo "LIBRARYES    = $(LIBRARYES)" >> $(PROJECT)
