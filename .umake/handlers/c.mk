################################################################################
# Version: 20110314
#
# Umake - GNU Make based automation build system
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

# C preprocessor flags
override C_PPFLAGS = $(strip $(CPPFLAGS) \
                             $(call mkMacro, $(CPPMACROS)) \
                             $(PKGMACROS) \
                             $(call mkIncDir, $(CPPINCPATH)) \
                             $(PKGINCPATH))
# C++ compiler flags
override CFLAGS   := $(strip $(CFLAGS))

# Generate src/deps/obj lists
override CSRCLIST  = $(filter %.c, $(SRCLIST))
override COBJS     = $(call src2obj, $(CSRCLIST))
override CDEPS     = $(call src2dep, $(CSRCLIST))

# Update global variables
override OBJECTS  += $(COBJS)
override DEPENDS  += $(CDEPS)

# Dependency rule
$(CDEPS): %:
	@echo "Updating dependency file: $(call dep2src, $@) -> $@"
	@mkdir -p $(dir $@)
	@echo $(patsubst %:, \
			$(call src2obj, $(call dep2src, $@)) $@: $(CONFIGFILE), \
				$(shell $(CC) -MM $(C_PPFLAGS) $(call dep2src, $@))) > $@

# Object rule
$(COBJS): %:
	@mkdir -p $(dir $@)
	$(CC) $(strip $(CFLAGS) $(C_PPFLAGS) -c -o $@ $(call obj2src, $@))
