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
ifneq ($(OCXXEXT), $(EMPTY))
    $(error "Mixing extensions for the same filetype is not allowed: $(OCXXEXT), $(CURREXT)")
endif
override OCXXEXT := $(CURREXT)

# Generate src/deps/obj lists
override OCXXSRCLIST  = $(filter %.$(OCXXEXT), $(SRCLIST))
override OCXXOBJECTS  = $(call src2obj, $(OCXXSRCLIST))
override OCXXDEPENDS  = $(call src2dep, $(OCXXSRCLIST))

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
    $(OCXXDEPENDS): %:
		@echo "Updating dependency file: $(call dep2src, $@) -> $@"; \
		mkdir -p $(dir $@); \
		echo $(patsubst %:, \
			$(call src2obj, $(call dep2src, $@)) $@: $(CONFIGFILE), \
				$(shell $(CXX) -MM $(CXX_PPFLAGS) $(call dep2src, $@))) > $@

    # Object rule
    $(OCXXOBJECTS): %:
		@mkdir -p $(dir $@)
		$(strip $(CXX) $(CXXFLAGS) -fobjc-call-cxx-cdtors $(CXX_PPFLAGS) -c -o $@ $(call obj2src, $@))

    $(TARGET): $(OCXXOBJECTS)

    sinclude $(OCXXDEPENDS)
else
    # Cleanup rules
    .PHONY: ocxxclean
    ocxxclean:
		@$(RM) -rv $(OCXXOBJECTS) $(OCXXDEPENDS)

    clean: ocxxclean
endif
