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
PHP_FPM_GROUP  := www-data
XDEBUG_WEIGHT  := 001
OPCACHE_WEIGHT := 010
INTL_WEIGHT    := 050
MONGO_WEIGHT   := 050
TIDY_WEIGHT    := 050


# ------------------------------------------------------------------------------
#                                                                 User Functions
# ------------------------------------------------------------------------------


# Create symbolic link and enable additional PHP configuration file.
#
# ARGS:
#  $1 - The name of the file.
#  $2 - The weight of the file.
define SYMLINK
cd ./$(strip $(1))-enabled && ln --force --symbolic -- ../available/$(strip $(2)).ini $(strip $(3))-$(strip $(2)).ini
endef


# ------------------------------------------------------------------------------
#                                                                        Targets
# ------------------------------------------------------------------------------


all:
	make install xdebug

install:
# FPM
	$(call SYMLINK, fpm, opcache, $(OPCACHE_WEIGHT))
	$(call SYMLINK, fpm, intl, $(INTL_WEIGHT))
	$(call SYMLINK, fpm, tidy, $(TIDY_WEIGHT))
	echo '' > $(PHP_FPM_LOG)
	chown -- root:root $(PHP_FPM_LOG)
	chmod -- 0644 $(PHP_FPM_LOG)
	[ -d $(PHP_FPM_CHDIR) ] || mkdir --parents -- $(PHP_FPM_CHDIR)
	chown -- $(PHP_FPM_USER):$(PHP_FPM_GROUP) $(PHP_FPM_CHDIR)
	chmod -- 0755 $(PHP_FPM_CHDIR)
	chmod -- g+s $(PHP_FPM_CHDIR)
# CLI
	$(call SYMLINK, cli, intl, $(INTL_WEIGHT))
	$(call SYMLINK, cli, tidy, $(TIDY_WEIGHT))

uninstall:
	rm --force -- ./*-enabled/*.ini $(PHP_FPM_LOG) $(PHP_FPM_LOG)
	-rmdir -- $(PHP_FPM_CHDIR)
	make uninstall-mongo
	make uninstall-xdebug

mongo:
	yes '' | pecl install --force --soft -- mongo
	printf -- '; @see https://php.net/mongo.configuration\nextension = mongo.so' > ./available/mongo.ini
	$(call SYMLINK, fpm, mongo, $(MONGO_WEIGHT))
	$(call SYMLINK, cli, mongo, $(MONGO_WEIGHT))

uninstall-mongo:
	pecl uninstall -- mongo
	rm --force -- ./*-enabled/$(MONGO_WEIGHT)-mongo.ini ./available/mongo.ini

xdebug:
	pecl install --force --soft -- xdebug
	printf -- '; @see http://xdebug.org/docs/all_settings\nzend_extension   = xdebug.so\n\n[xdebug]\nxdebug.cli_color = 1' > ./available/xdebug.ini
	$(call SYMLINK, cli, xdebug, $(XDEBUG_WEIGHT))

uninstall-xdebug:
	pecl uninstall -- xdebug
	rm --force -- ./*-enabled/$(XDEBUG_WEIGHT)-xdebug.ini ./available/xdebug.ini
