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

define CONFIG_TEMPLATE
#########################################################################
# Files settings
#
# Source folders list
SRCDIRLIST   = src
# Source files list
SRCLIST      =
# Toplevel output folder (default: current folder)
BUILDROOT    =
# Where to put target under BUILDROOT? (default: BUILDROOT/)
BINDIR       =
# Target name (default: config file's name w/o extension)
TARGET       = $$(PROJECT)

#########################################################################
#
# Terminal settings
#
TERMNAME     = urxvtc
TERMOPTIONS  = -e

#########################################################################
#
# Preprocessors settings
#
# C/C++ preprocessor flags
CPPFLAGS     =
# C/C++ preprocessor macros definitions
CPPMACROS    =
# C/C++ preprocessor include files path
CPPINCPATH   = include

#########################################################################
#
# Compilers settings
#
# C compiler flags
CFLAGS       = -ggdb -pipe -pedantic -Wall
# C++ compiler flags
CXXFLAGS     = $$(CFLAGS)

#########################################################################
#
# Linker settings
#
# Static archive creation flags
ARFLAGS      = rucs
# Linker flags
LDFLAGS      =
# Libraries search path
LIBRARYPATH  =
# Required libraries list
LIBRARIES    =
# Raw object files lists to be linked before and after target object
# files (used with -nostdlib), usually empty
LDPRELIBS    =
LDPOSTLIBS   =

# Required 'pkg-config' packages list. Format: pkgname[:==|<=|>=version]
REQUIREPKGS  =
endef

export CONFIG_TEMPLATE

$(TPLSLIST): %.prj:
	@[ ! -f "$@" ] && \
		echo "Generating target template: $@" && \
			echo "$$CONFIG_TEMPLATE" > $@; \
	echo "Now edit '$@' and type 'make'..."
