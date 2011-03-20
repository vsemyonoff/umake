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

# C++ compiler
override CXX = g++

# Get current filetype
override CURREXT := $(notdir $(basename $(lastword $(MAKEFILE_LIST))))
ifneq ($(HEXT), $(EMPTY))
    $(error "Mixing extensions for the same filetype is not allowed: $(HEXT), $(CURREXT)")
endif
override HEXT := $(CURREXT)

# Generate src/deps/obj lists
override HSRCLIST  = $(filter %.$(HEXT), $(SRCLIST))
override HDEPENDS  = $(call src2dep, $(HSRCLIST))
override HTAGS     = $(call src2tag, $(HSRCLIST))

ifeq ($(filter clean distclean, $(MAKECMDGOALS)), $(EMPTY))
    ifeq ($(CXX_PPFLAGS), $(EMPTY))
        # C++ preprocessor flags
        override CXX_PPFLAGS = $(strip $(CPPFLAGS) \
                                       $(call mkMacro, $(CPPMACROS)) \
                                       $(PKGMACROS) \
                                       $(call mkIncDir, $(SRCDIRLIST)) \
                                       $(call mkIncDir, $(CPPINCPATH)) \
                                       $(PKGINCPATH))
    endif

    # Dependency rule
    $(HDEPENDS): %:
		@echo "Updating dependency file: $(call dep2src, $@) -> $@"
		@mkdir -p $(dir $@)
		@echo $(shell $(CXX) -M $(CXX_PPFLAGS) $(call dep2src, $@)) > $@

    # Tags rule
    $(HTAGS): %: $(call src2dep, $(SOURCEFILE))
		@echo "Generating tags file: $(SOURCEFILE) -> $@"
		@mkdir -p $(dir $@)
		@ctags --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q --language-force=C++ -o $@ \
			$(shell grep -oP "(?<=:\s).*(?=$$)" $<)

else
    # Cleanup rules
    .PHONY: hclean
    hclean:
		@$(RM) -v $(HDEPENDS) $(HTAGS)

    clean: hclean
endif
