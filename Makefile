################################################################################
# Version: 20110314
#
# MakeIt - GNU Make based automation build system
#
# Copyright © 2009 Vladyslav Semyonov <vsemyonoff@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

.SUFFIXES:

# Defalut phony target allow to add user defined targets in config file
.PHONY: all
all :

# Empty string constant
override EMPTY =
# Default command interpreter
override SHELL = bash

ifeq ($(CONFIGFILE), $(EMPTY))

################################################################################
#
# PART #1: search for configuration files & run submake
#
    # Makefile's name and path
    override MAKEFILE = $(strip $(shell readlink -f $(firstword $(MAKEFILE_LIST))))
    # Extend MAKE variable with proper makefile name
    override MAKE += --makefile $(MAKEFILE) --no-print-directory

    # Project templates list to be created
    override TPLSLIST = $(EMPTY)
    # Search all config files in makefile's folder and 'make' arguments (target templates)
    override CONFIGSLIST = $(wildcard *.prj)
    ifeq ($(CONFIGSLIST), $(EMPTY))
        override TPLSLIST += $(notdir $(shell pwd)).prj
    endif

    # Divide input arguments to templates, projects and actions
    override PROJECTS = $(filter $(CONFIGSLIST:%.prj=%), $(MAKECMDGOALS))
    ifeq ($(PROJECTS), $(EMPTY))
        override PROJECTS = $(CONFIGSLIST:%.prj=%)
    endif
    override TPLSLIST += $(filter %.prj, $(MAKECMDGOALS))
    override ACTIONS = $(filter-out $(PROJECTS) $(TPLSLIST), $(MAKECMDGOALS))

    .PHONY: $(PROJECTS) $(ACTIONS)

    all: $(TPLSLIST) $(PROJECTS)

    # Actions rule
    $(ACTIONS): $(PROJECTS)
		@echo "Reached target: $@"

    # Make projects rule
    $(PROJECTS): %: %.prj
		@cd $(dir $(shell readlink -f $<)) && \
			$(MAKE) $(ACTIONS) CONFIGFILE=$(notdir $(shell readlink -f $<))

    # Create project templates rule
    $(TPLSLIST): %.prj:
		@$(MAKE) config CONFIGFILE=$@
		@echo "Now edit '$@' and type 'make'..."

    # Do not resolve depends while cleaning or generating template
    ifeq ($(strip $(ACTIONS) $(TPLSLIST)), $(EMPTY))
        sinclude depends.prg
    endif
else

################################################################################
#
# PART #2: process configuration files managed by PART #1
#
    # Inlcude configuration file
    sinclude $(CONFIGFILE)

    # Project's short name
    override PROJECT = $(notdir $(basename $(CONFIGFILE)))
#
# Process configuration settings
#
    # Objects and depends list to be extended by file type handlers
    override OBJECTS = $(EMPTY)
    override DEPENDS = $(EMPTY)
#
# Validate common variables
#
    ifneq ($(filter /%, $(BUILDROOT) $(BINDIR) $(SRCDIRLIST) $(SRCLIST)), $(EMPTY))
        $(error "Absolute file names are not supported, use relative file names")
    endif

    override trailSlash = $(strip $(filter %/, $(1)) $(addsuffix /, $(filter-out %/, $(1))))
    override rmSlash    = $(strip $(patsubst ./%, %, $(1)))
    override src2obj    = $(addprefix $(OBJDIR), $(addsuffix .o, $(1)))
    override src2dep    = $(addprefix $(DEPDIR), $(addsuffix .d, $(1)))
    override obj2src    = $(patsubst $(OBJDIR)%.o, %, $(1))
    override dep2src    = $(patsubst $(DEPDIR)%.d, %, $(1))
    override mkMacro    = $(strip $(filter -D%, $(1)) $(addprefix -D, $(filter-out -D%, $(1))))
    override mkIncDir   = $(strip $(filter -I%, $(1)) $(addprefix -I, $(filter-out -I%, $(1))))
    override mkLibDir   = $(strip $(filter -L%, $(1)) $(addprefix -L, $(filter-out -L%, $(1))))
    override mkLib      = $(strip $(filter -l%, $(1)) $(addprefix -l, $(filter-out -l%, $(1))))

    # Check output folders
    override BUILDROOT := $(call trailSlash, $(firstword $(BUILDROOT)))
    override DEPDIR  = $(call trailSlash, $(BUILDROOT).dep/$(PROJECT))
    override OBJDIR  = $(call trailSlash, $(BUILDROOT).obj/$(PROJECT))
    override BINDIR := $(call trailSlash, $(BUILDROOT)$(firstword $(BINDIR)))

    # Check source dirs list and sources list
    override SRCDIRLIST := $(sort $(SRCDIRLIST))
    override SRCLIST := $(sort $(SRCLIST))

    # Check target name
    override TARGET := $(firstword $(TARGET))
    ifeq ($(TARGET), $(EMPTY))
        override TARGET = $(PROJECT)
    endif
    override TARGET := $(BINDIR)$(TARGET)

    # Umake modules folder
    override MODULESDIR = $(call trailSlash, $(dir $(firstword $(MAKEFILE_LIST))).umake)
#
# Run pkg-config tests
#
    # Do not check packages while cleaning folders or creating project template
    ifeq ($(filter config clean distclean, $(MAKECMDGOALS)), $(EMPTY))
        ifneq ($(strip $(REQUIREPKGS)), $(EMPTY))
            # Inlude linker rules
            include $(MODULESDIR)pkgconfig.mk
        endif
    endif
#
# Generate sources list
#
    # Generate sources list
    override SRCLIST += $(foreach SRCDIR, $(SRCDIRLIST), \
                            $(call rmSlash, \
                                $(shell find $(SRCDIR) -type f -print)))
    override SRCLIST := $(sort $(SRCLIST))
    ifeq ($(SRCLIST), $(EMPTY))
        $(error "No source files found. Update configuration file '$(CONFIGFILE)'")
    endif

    # Generate extensions list from sources list
    override EXTLIST = $(sort $(patsubst .%, %, $(suffix $(SRCLIST))))

################################################################################
#
# PART #3: make rules for PART #2
#
    all: $(TARGET)
    ifeq ($(filter config, $(MAKECMDGOALS)), $(EMPTY))
        sinclude $(addprefix $(MODULESDIR)handlers/, $(addsuffix .mk, $(EXTLIST)))
        ifeq ($(filter clean distclean, $(MAKECMDGOALS)), $(EMPTY))
            sinclude $(DEPENDS)
            include $(MODULESDIR)linker.mk
            include $(MODULESDIR)exec.mk
            include $(MODULESDIR)tags.mk
        else
            include $(MODULESDIR)clean.mk
            include $(MODULESDIR)distclean.mk
        endif
    else
        include $(MODULESDIR)config.mk
    endif
endif # ifeq ($(strip $(CONFIGFILE)), $(EMPTY))
