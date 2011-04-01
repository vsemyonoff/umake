################################################################################
# Version: 20110314
#
# Umake - GNU Make based automation build system
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

# Get current filetype
override CURREXT := $(notdir $(basename $(lastword $(MAKEFILE_LIST))))
ifneq ($(CXXEXT), $(EMPTY))
    $(error "Mixing extensions for the same filetype is not allowed: $(CXXEXT), $(CURREXT)")
endif
override CXXEXT := $(CURREXT)

# Generate src/deps/obj lists
override CXXSRCLIST  = $(filter %.$(CXXEXT), $(SRCLIST))
override CXXOBJECTS  = $(call src2obj, $(CXXSRCLIST))
override CXXDEPENDS  = $(call src2dep, $(CXXSRCLIST))

ifeq ($(filter clean distclean, $(MAKECMDGOALS)), $(EMPTY))
    # C++ preprocessor flags
    override CXX_PPFLAGS = $(strip $(CPPFLAGS) \
                                   $(call mkMacro, $(CPPMACROS)) \
                                   $(PKGMACROS) \
                                   $(call mkIncDir, $(CPPINCPATH)) \
                                   $(PKGINCPATH))
    # C++ compiler flags
    override CXXFLAGS   := $(strip $(CXXFLAGS))

    # Dependency rule
    $(CXXDEPENDS): %:
		@echo "Updating dependency file: $(call dep2src, $@) -> $@"; \
		 mkdir -p $(dir $@); \
		 echo $(patsubst %:, \
			$(call src2obj, $(call dep2src, $@)) $@: $(CONFIGFILE), \
				$(shell $(CXX) -MM $(CXX_PPFLAGS) $(call dep2src, $@))) > $@

    # Object rule
    $(CXXOBJECTS): %:
		@mkdir -p $(dir $@)
		$(strip $(CXX) $(CXXFLAGS) $(CXX_PPFLAGS) -c -o $@ $(call obj2src, $@))

    $(TARGET): $(CXXOBJECTS)

    sinclude $(CXXDEPENDS)
else
    # Cleanup rules
    .PHONY: cxxclean
    cxxclean:
		@$(RM) -rv $(CXXOBJECTS) $(CXXDEPENDS)

    clean: cxxclean
endif
