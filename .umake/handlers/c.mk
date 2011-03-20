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

# C compiler
override CC = gcc

# Get current filetype
override CURREXT := $(notdir $(basename $(lastword $(MAKEFILE_LIST))))
ifneq ($(CEXT), $(EMPTY))
    $(error "Mixing extensions for the same filetype is not allowed: $(CEXT), $(CURREXT)")
endif
override CEXT := $(CURREXT)

# Generate src/deps/obj lists
override CSRCLIST  = $(filter %.$(CEXT), $(SRCLIST))
override COBJECTS  = $(call src2obj, $(CSRCLIST))
override CDEPENDS  = $(call src2dep, $(CSRCLIST))
override CTAGS     = $(call src2tag, $(CSRCLIST))

ifeq ($(filter clean distclean, $(MAKECMDGOALS)), $(EMPTY))
    # C preprocessor flags
    override C_PPFLAGS = $(strip $(CPPFLAGS) \
                                 $(call mkMacro, $(CPPMACROS)) \
                                 $(PKGMACROS) \
                                 $(call mkIncDir, $(SRCDIRLIST)) \
                                 $(call mkIncDir, $(CPPINCPATH)) \
                                 $(PKGINCPATH))
    # C compiler flags
    override CFLAGS   := $(strip $(CFLAGS))

    # Dependency rule
    $(CDEPENDS): %:
		@echo "Updating dependency file: $(call dep2src, $@) -> $@"
		@mkdir -p $(dir $@)
		@echo $(patsubst %:, \
				$(call src2obj, $(call dep2src, $@)) $@: $(CONFIGFILE), \
					$(shell $(CC) -M $(C_PPFLAGS) $(call dep2src, $@))) > $@

    # Tags rule
    $(CTAGS): %: $(call src2dep, $(SOURCEFILE))
		@echo "Generating tags file: $(SOURCEFILE) -> $@"
		@mkdir -p $(dir $@)
		@ctags --sort=yes --c-kinds=+p --fields=+iaS --extra=+q --language-force=C -o $@ \
			$(shell grep -oP "(?<=$(CONFIGFILE)\s).*(?=$$)" $<)

    # Object rule
    $(COBJECTS): %:
		@mkdir -p $(dir $@)
		$(strip $(CC) $(CFLAGS) $(C_PPFLAGS) -c -o $@ $(call obj2src, $@))

    $(TARGET): $(COBJECTS)

    sinclude $(CDEPENDS)
else
    # Cleanup rules
    .PHONY: cclean
    cclean:
		@$(RM) -v $(CDEPENDS) $(CTAGS) $(COBJECTS)

    clean: cclean
endif
