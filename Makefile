################################################################################
# Version: 20110314
#
# MakeIt - GNU Make based automation build system
#
# Copyright © 2009 Vladyslav Semyonov [vsemyonoff on gmail dot com]
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

# Slash functions
override trailSlash  = $(strip $(filter %/, $(1)) $(addsuffix /, $(filter-out %/, $(1))))
override rmSlash     = $(strip $(patsubst ./%, %, $(1)))
# Source file name -> intermediate file name conversion functions
override src2dep     = $(addprefix $(DEPDIR), $(addsuffix .d, $(1)))
override src2tag     = $(addprefix $(TAGDIR), $(addsuffix .t, $(1)))
override src2obj     = $(addprefix $(OBJDIR), $(addsuffix .o, $(1)))
# Intermediate file name -> source file name conversion functions
override dep2src     = $(strip $(patsubst $(DEPDIR)%.d, %, $(1)))
override tag2src     = $(strip $(patsubst $(TAGDIR)%.t, %, $(1)))
override obj2src     = $(strip $(patsubst $(OBJDIR)%.o, %, $(1)))
# Preprocessor and linker arguments functions
override mkMacro     = $(strip $(filter -D%, $(1)) $(addprefix -D, $(filter-out -D%, $(1))))
override mkIncDir    = $(strip $(filter -I%, $(1)) $(addprefix -I, $(filter-out -I%, $(1))))
override mkLibDir    = $(strip $(filter -L%, $(1)) $(addprefix -L, $(filter-out -L%, $(1))))
override mkLib       = $(strip $(filter -l%, $(1)) $(addprefix -l, $(filter-out -l%, $(1))))
# Filter symlinked files function
override filterLocal = $(shell for i in $(1); do [ ! -L "$$i" ] && echo "$$i"; done)

# Makefile's name and path
override MAKEFILE = $(shell readlink -f $(firstword $(MAKEFILE_LIST)))
# Umake modules folder
override MODULESDIR = $(call trailSlash, $(dir $(MAKEFILE)).umake)

ifeq ($(CONFIGFILE), $(EMPTY))

################################################################################
#
# PART #1: search for configuration files & run submake
#
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
    override TPLSLIST := $(strip $(TPLSLIST) $(filter %.prj, $(MAKECMDGOALS)))
    override ACTIONS = $(filter-out all $(PROJECTS) $(TPLSLIST), $(MAKECMDGOALS))

    ifeq ($(TPLSLIST), $(EMPTY))
        all: $(PROJECTS)
        include $(MODULESDIR)main.mk
        ifeq ($(filter tags clean distclean, $(ACTIONS)), $(EMPTY))
            sinclude depends.prg
        endif
    else
        all: $(TPLSLIST)
        include $(MODULESDIR)config.mk
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
# Validate common variables
#
    ifneq ($(filter /%, $(BINDIR) $(SRCDIRLIST) $(SRCLIST)), $(EMPTY))
        $(error "Absolute pathes (/*) are not allowed, use relative file names")
    endif
    ifneq ($(filter ../%, $(BINDIR) $(SRCDIRLIST) $(SRCLIST)), $(EMPTY))
        $(error "External pathes (../*) are not allowed, use symlinks to include external files")
    endif

    # Check output folders
    override BUILDROOT := $(call trailSlash, $(firstword $(BUILDROOT)))
    override BINDIR := $(call trailSlash, $(BUILDROOT)$(firstword $(BINDIR)))
    override DEPDIR  = $(call trailSlash, $(BUILDROOT).dep/$(PROJECT))
    override TAGDIR  = $(call trailSlash, $(BUILDROOT).tag/$(PROJECT))
    override OBJDIR  = $(call trailSlash, $(BUILDROOT).obj/$(PROJECT))
    override TMPDIR  = $(call trailSlash, /tmp/umake-$(USER))

    # Check source dirs list and sources list
    override SRCDIRLIST := $(strip $(SRCDIRLIST))
    override SRCLIST := $(sort $(SRCLIST))

    # Check target name
    override TARGET := $(notdir $(firstword $(TARGET)))
    ifeq ($(TARGET), $(EMPTY))
        override TARGET = $(PROJECT)
    endif
    override TARGET := $(BINDIR)$(TARGET)
#
# Run pkg-config tests
#
    # Do not check packages while cleaning folders or creating project template
    ifeq ($(filter clean distclean, $(MAKECMDGOALS)), $(EMPTY))
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
        $(error "No source files found. Please, update configuration file '$(CONFIGFILE)'")
    endif

    # Generate extensions list from sources list
    override EXTLIST = $(sort $(patsubst .%, %, $(suffix $(SRCLIST))))

################################################################################
#
# PART #3: make rules for PART #2
#
    all: $(TARGET)
    sinclude $(addprefix $(MODULESDIR)handlers/, $(addsuffix .mk, $(EXTLIST)))
    ifeq ($(filter clean distclean, $(MAKECMDGOALS)), $(EMPTY))
        include $(MODULESDIR)link.mk
    else
        include $(MODULESDIR)clean.mk
        include $(MODULESDIR)distclean.mk
    endif
    ifneq ($(filter tags, $(MAKECMDGOALS)), $(EMPTY))
        include $(MODULESDIR)tags.mk
    endif
    ifneq ($(filter exec, $(MAKECMDGOALS)), $(EMPTY))
        include $(MODULESDIR)exec.mk
    endif

endif # ifeq ($(strip $(CONFIGFILE)), $(EMPTY))
