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

ifeq ($(shell which ctags 2> /dev/null), $(EMPTY))
    $(error "No 'ctags' tool found")
endif

ifeq ($(SOURCEFILE), $(EMPTY))
    $(error "SOURCEFILE not specified, unable to generate tags file")
endif

define GCCMOD_SH
#!/usr/bin/env bash

[ $${#} != 3 ] && exit 1

CONFIG="$${1}"
DEPFILE="$${2}"
OUTDIR="$${3}include/"

for i in $$(grep -oP "(?<=:\s$${CONFIG}\s).*(?=$$)" $${DEPFILE}); do
    if grep -E "^_GLIBCXX_(BEGIN_|END_)" $${i} > /dev/null 2>&1 ; then
        MODFILE="$${OUTDIR}$$(basename $${i})"
        if [ ! -f "$${MODFILE}" ]; then
            umask u=rwx,g=,o=
            mkdir -p $$(dirname "$${MODFILE}")
            cat "$${i}" | sed -e 's/^_GLIBCXX_BEGIN_NAMESPACE(\([^\)]*\))/namespace \1 {/g' \
                        | sed -e 's/^_GLIBCXX_END_NAMESPACE/}/g' \
                        | sed -e 's/^_GLIBCXX_BEGIN_NESTED_NAMESPACE(\([^,]*\), [^)]*)/namespace \1 {/g' \
                        | sed -e 's/^_GLIBCXX_END_NESTED_NAMESPACE/}/g' \
                        | sed -e 's/^_GLIBCXX_BEGIN_NAMESPACE_TR1/namespace tr1 {/g' \
                        | sed -e 's/^_GLIBCXX_END_NAMESPACE_TR1/}/g' \
                        | sed -e 's/^_GLIBCXX_BEGIN_LDBL_NAMESPACE/namespace __gnu_cxx_ldbl128 {/g' \
                        | sed -e 's/^_GLIBCXX_END_LDBL_NAMESPACE/}/g' \
                        | sed -e 's/^_GLIBCXX_BEGIN_EXTERN_C/extern "C" {/g' \
                        | sed -e 's/^_GLIBCXX_END_EXTERN_C/}/g' > "$${MODFILE}"
        fi
        echo "$${MODFILE}"
    else
        echo "$${i}"
    fi
done
endef
export GCCMOD_SH

override GCCMOD = $(TMPDIR)gccmod.sh

$(GCCMOD):
	@umask u=rwx,g=,o=; \
	 mkdir -p $$(dirname $@); \
	 echo "$$GCCMOD_SH" > $@; \
	 chmod u+x $@

.PHONY: tags
tags: $(GCCMOD) $(call src2tag, $(filter $(SOURCEFILE), $(SRCLIST)))
