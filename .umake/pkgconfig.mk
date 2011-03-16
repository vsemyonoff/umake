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

ifeq ($(shell which pkg-config 2> /dev/null), $(EMPTY))
    $(error "No 'pkg-config' tool found")
endif

# Package name manipulation functions
override pkgName  = $(strip $(foreach PACKAGE, $(1), $(firstword $(subst :, , $(PACKAGE)))))
override pkgVers  = $(strip $(word 2, $(subst :, , $(firstword $(1)))))

# First of all, we need to check each required 'pkg-config' package.
override PKGLIST  = $(subst >=,--atleast-version=, $(REQUIREPKGS))
override PKGLIST := $(subst ==,--exact-version=, $(PKGLIST))
override PKGLIST := $(subst <=,--max-version=, $(PKGLIST))
override RESULT   = $(foreach PACKAGE, $(PKGLIST), \
                        $(shell pkg-config $(call pkgVers, $(PACKAGE)) \
                            $(call pkgName, $(PACKAGE)); \
                                [ ! $$? == 0 ] &&  echo -n $(call pkgName, $(PACKAGE))))

ifneq ($(strip $(RESULT)), $(EMPTY))
    $(error "$(RESULT): package(s) not installed or has incompatible version number" )
else
    # Get packages information
    override PKGNAMES   = $(call pkgName, $(PKGLIST))
    override PKGMACROS  = $(shell pkg-config --cflags-only-other $(PKGNAMES))
    override PKGINCPATH = $(shell pkg-config --cflags-only-I $(PKGNAMES))
    override PKGLDFLAGS = $(shell pkg-config --libs-only-other $(PKGNAMES))
    override PKGLIBPATH = $(shell pkg-config --libs-only-L $(PKGNAMES))
    override PKGLIBS    = $(shell pkg-config --libs-only-l $(PKGNAMES))
endif
