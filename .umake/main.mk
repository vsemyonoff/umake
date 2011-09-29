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

.PHONY: $(PROJECTS) $(ACTIONS)

# Projects rule (skip actions for symlinked projects)
$(CONFIGSLIST:%.prj=%): %: %.prj
	@cd $(dir $(shell test -L $< && readlink $< || echo $<)) && \
		$(MAKE) \
			$(shell [ ! -z "$(call filterLocal, $<)" ] && echo $(ACTIONS)) \
				CONFIGFILE=$(notdir $(shell test -L $< && readlink $< || echo $<))

# Actions rule (skip symlinked projects)
$(ACTIONS): $(patsubst %.prj, %, $(call filterLocal, $(patsubst %, %.prj, $(PROJECTS))))
	@echo "Reached target: $@"
