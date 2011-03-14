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

# C++ preprocessor flags
override CXX_PPFLAGS = $(strip $(CPPFLAGS) \
                               $(call mkMacro, $(CPPMACROS)) \
                               $(PKGMACROS) \
                               $(call mkIncDir, $(CPPINCPATH)) \
                               $(PKGINCPATH))
# C++ compiler flags
override CXXFLAGS   := $(strip $(CXXFLAGS))

# Generate src/deps/obj lists
override CXXSRCLIST  = $(filter %.cpp, $(SRCLIST))
override CXXOBJS     = $(call src2obj, $(CXXSRCLIST))
override CXXDEPS     = $(call src2dep, $(CXXSRCLIST))

# Update global variables
override OBJECTS    += $(CXXOBJS)
override DEPENDS    += $(CXXDEPS)

# Dependency rule
$(CXXDEPS): %:
	@echo "Updating dependency file: $(call dep2src, $@) -> $@"
	@mkdir -p $(dir $@)
	@echo $(patsubst %:, \
				$(call src2obj, $(call dep2src, $@)) $@: $(CONFIGFILE), \
					$(shell $(CXX) -MM $(CXX_PPFLAGS) $(call dep2src, $@))) > $@

# Object rule
$(CXXOBJS): %:
	@mkdir -p $(dir $@)
	$(CXX) $(strip $(CXXFLAGS) $(CXX_PPFLAGS) -c -o $@ $(call obj2src, $@))
