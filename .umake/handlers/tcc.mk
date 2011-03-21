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
ifneq ($(TCCEXT), $(EMPTY))
    $(error "Mixing extensions for the same filetype is not allowed: $(TCCEXT), $(CURREXT)")
endif
override TCCEXT := $(CURREXT)

# Generate src/deps/obj lists
override TCCSRCLIST  = $(filter %.$(TCCEXT), $(SRCLIST))
override TCCDEPENDS  = $(call src2dep, $(TCCSRCLIST))
override TCCTAGS     = $(call src2tag, $(TCCSRCLIST))

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
    $(TCCDEPENDS): %:
		@echo "Updating dependency file: $(call dep2src, $@) -> $@"; \
		mkdir -p $(dir $@); \
		echo $(patsubst %:, \
			$(call src2obj, $(call dep2src, $@)) $@: $(CONFIGFILE), \
				$(shell $(CXX) -M $(CXX_PPFLAGS) $(call dep2src, $@))) > $@

    # Tags rule
    $(TCCTAGS): %: $(call src2dep, $(SOURCEFILE))
		@echo "Generating tags file: $(SOURCEFILE) -> $@"; \
		mkdir -p $(dir $@); \
		ctags --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q \
			--language-force=C++ -o $@ \
				$$($(GCCMOD) $(CONFIGFILE) $< $(TMPDIR))

else
    # Cleanup rules
    .PHONY: tccclean
    tccclean:
		@$(RM) -v $(TCCTAGS) $(TCCDEPENDS)

    clean: tccclean
endif
