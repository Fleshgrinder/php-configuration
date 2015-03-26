#!/bin/sh

# ------------------------------------------------------------------------------
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or distribute
# this software, either in source code form or as a compiled binary, for any
# purpose, commercial or non-commercial, and by any means.
#
# In jurisdictions that recognize copyright laws, the author or authors of this
# software dedicate any and all copyright interest in the software to the public
# domain. We make this dedication for the benefit of the public at large and to
# the detriment of our heirs and successors. We intend this dedication to be an
# overt act of relinquishment in perpetuity of all present and future rights to
# this software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org>
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Makefile to create symbolic links and directories/files with proper
# permissions. Especially php-fpm will fail to create a log file that can be
# tailed by normal users. Whether this is a good thing or not is for you to
# decide; I prefer it to be readable for all my users.
#
# @author Richard Fussenegger <richard@fussenegger.info>
# @copyright (c) 2015 Richard Fussenegger
# @license http://unlicense.org/ PD
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#                                                                      Variables
# ------------------------------------------------------------------------------


SHELL = /bin/sh
.SUFFIXES:

PHP_FPM_LOG    := /var/log/php-fpm.log
PHP_FPM_CHDIR  := /var/www
PHP_FPM_USER   := www-data
PHP_FPM_GROUP  := $(PHP_FPM_USER)
XDEBUG_WEIGHT  := 001
OPCACHE_WEIGHT := 010
DEFAULT_WEIGHT := 050


# ------------------------------------------------------------------------------
#                                                                 User Functions
# ------------------------------------------------------------------------------


# Enable extension.
#
# ARGS:
#  $1 - The type to enable (either "cli" or "fpm").
#  $2 - The name of the extension.
#  $3 - The weight of the extension.
define ENABLE
    cd ./$(strip $1)-enabled && ln --force --symbolic -- ../available/$(strip $2).ini $(strip $3)-$(strip $2).ini
endef

# Enable extension for CLI.
#
# ARGS:
#  $1 - The name of the extension.
#  $2 - The weight of the extension.
define ENABLE_CLI
    $(call ENABLE, cli, $1, $2)
endef

# Enable extension for FPM.
#
# ARGS:
#  $1 - The name of the extension.
#  $2 - The weight of the extension.
define ENABLE_FPM
    $(call ENABLE, fpm, $1, $2)
endef

# Enable extension for CLI and FPM.
#
# ARGS:
#  $1 - The name of the extension.
#  $2 - The weight of the extension.
define ENABLE_CLI_AND_FPM
    $(call ENABLE_CLI, $1, $2)
    $(call ENABLE_FPM, $1, $2)
endef

# Enable extension for CLI with default weight.
#
# ARGS:
#  $1 - The name of the extension.
define ENABLE_CLI_DEFAULT
    $(call ENABLE, cli, $1, $(DEFAULT_WEIGHT))
endef

# Enable extension for FPM with default weight.
#
# ARGS:
#  $1 - The name of the extension.
define ENABLE_FPM_DEFAULT
    $(call ENABLE, fpm, $1, $(DEFAULT_WEIGHT))
endef

# Enable extension for CLI and FPM with default weight.
#
# ARGS:
#  $1 - The name of the extension.
define ENABLE_CLI_AND_FPM_DEFAULT
    $(call ENABLE_CLI_DEFAULT, $1)
    $(call ENABLE_FPM_DEFAULT, $1)
endef

# Install PECL extension and enable for CLI and FPM with default weight.
define PECL_INSTALL
    $(eval EXTENSION := $(strip $@))
    yes '' | pecl install --force --soft -- $(EXTENSION)
    printf -- '; @see https://php.net/$(EXTENSION).configuration\nextension = $(EXTENSION).so\n' > ./available/$(EXTENSION).ini
    $(call ENABLE_CLI_AND_FPM_DEFAULT, $(EXTENSION))
endef

# Uninstall PECL extension.
define PECL_UNINSTALL
    $(eval EXTENSION := $(basename $(strip $@)))
    pecl uninstall -- $(EXTENSION)
    rm --force -- ./*-enable/$(DEFAULT_WEIGHT)-$(EXTENSION).ini ./available/$(EXTENSION).ini
endef


# ------------------------------------------------------------------------------
#                                                                        Targets
# ------------------------------------------------------------------------------


all:
	make install xdebug

install:
	$(call ENABLE_FPM, opcache, $(OPCACHE_WEIGHT))
	$(call ENABLE_CLI_AND_FPM_DEFAULT, intl)
	$(call ENABLE_CLI_AND_FPM_DEFAULT, tidy)
	echo '' > $(PHP_FPM_LOG)
	chown -- root:root $(PHP_FPM_LOG)
	chmod -- 0644 $(PHP_FPM_LOG)
	[ -d $(PHP_FPM_CHDIR) ] || mkdir --parents -- $(PHP_FPM_CHDIR)
	chown -- $(PHP_FPM_USER):$(PHP_FPM_GROUP) $(PHP_FPM_CHDIR)
	chmod -- 0755 $(PHP_FPM_CHDIR)
	chmod -- g+s $(PHP_FPM_CHDIR)

uninstall:
	make bbcode.uninstall mongo.uninstall xdebug.uninstall
	rm --force -- ./*-enabled/*.ini $(PHP_FPM_LOG) $(PHP_FPM_LOG)
	-rmdir -- $(PHP_FPM_CHDIR)

bbcode:
	$(PECL_INSTALL)

bbcode.uninstall:
	$(PECL_UNINSTALL)

mongo:
	$(PECL_INSTALL)

mongo.uninstall:
	$(PECL_UNINSTALL)

xdebug:
	pecl install --force --soft -- xdebug
	printf -- '; @see http://xdebug.org/docs/all_settings\nzend_extension = xdebug.so\n\n[xdebug]\nxdebug.cli_color = 1\n' > ./available/xdebug.ini
	$(call ENABLE_CLI, xdebug, $(XDEBUG_WEIGHT))

xdebug.uninstall:
	$(PECL_UNINSTALL)
