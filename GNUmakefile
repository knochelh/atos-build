#
# Copyright (C) STMicroelectronics Ltd. 2012
#
# This file is part of ATOS.
#
# ATOS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License v2.0
# as published by the Free Software Foundation
#
# ATOS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# v2.0 along with ATOS. If not, see <http://www.gnu.org/licenses/>.
#
# Makefile for full ATOS tools build
#
# Development mode usage:
#    cd atos-build
#    ./dependencies extract
#    make -j 4 all
#
# Release mode usage:
#    cd atos-build
#    ./dependencies -c releqse extract
#    make -j 4 release
#
SHELL=/bin/sh

srcdir=$(abspath $(dir $(MAKEFILE_LIST)))
currentdir=$(abspath .)
ifneq ($(srcdir),$(currentdir))
$(error "make must be run from the source directory: $(srcdir)")
endif

atos_version=$(shell cd $(srcdir)/atos-utils && config/get_version.sh)

installdir=$(currentdir)/devimage
builddir=$(currentdir)/build
distdir=$(currentdir)/distimage

SUBDIRS=talloc proot qemu jsonpath jsonlib argparse docutils pworker requests atos-utils

.PHONY: all default release $(addprefix all-, $(SUBDIRS)) dev $(addprefix dev-, $(SUBDIRS)) clean $(addprefix clean-, $(SUBDIRS)) distclean $(addprefix distclean-, $(SUBDIRS))

all: default

default:
	$(MAKE) dev-talloc
	$(MAKE) dev-proot
	$(MAKE) dev-qemu
	$(MAKE) dev-jsonpath
	$(MAKE) dev-jsonlib
	$(MAKE) dev-argparse
	$(MAKE) dev-docutils
	$(MAKE) dev-pworker
	$(MAKE) dev-requests
	$(MAKE) dev-atos-utils

all-atos-utils:
	$(MAKE) -C $(srcdir)/atos-utils all doc

clean-atos-utils distclean-atos-utils: %-atos-utils:
	$(MAKE) -C $(srcdir)/atos-utils $*

dev-atos-utils: all-atos-utils
	$(MAKE) -C $(srcdir)/atos-utils install install-doc install-shared PREFIX=$(installdir)

all-proot clean-proot distclean-proot: %-proot:
	mkdir -p $(builddir)/proot
	$(MAKE) -C $(builddir)/proot -f $(srcdir)/proot/src/GNUmakefile $* ENABLE_ADDONS="cc_opts" CFLAGS="-Wall -O2 -I$(installdir)/include" LDFLAGS="-static -L $(installdir)/lib -ltalloc" STATIC_BUILD=1

dev-proot: all-proot
	$(MAKE) -C $(builddir)/proot -f $(srcdir)/proot/src/GNUmakefile install PREFIX=$(installdir)

configure-talloc:
	mkdir -p $(builddir)
	cp -a $(srcdir)/talloc $(builddir)
	cd $(builddir)/talloc && ./configure --disable-python --prefix=$(installdir)

all-talloc: configure-talloc
	$(MAKE) -C $(builddir)/talloc all
	cd $(builddir)/talloc/bin/default && ar qf libtalloc.a talloc_3.o lib/replace/replace_2.o lib/replace/getpass_2.o

dev-talloc: all-talloc
	$(MAKE) -C $(builddir)/talloc install
	cp -a $(builddir)/talloc/bin/default/libtalloc.a $(installdir)/lib

clean-talloc distclean-talloc: %-talloc:
	$(MAKE) -C $(builddir)/talloc $*

configure-qemu:
	cd $(srcdir)/qemu && ./configure --target-list=i386-linux-user,x86_64-linux-user,sh4-linux-user,arm-linux-user --enable-tcg-plugin --prefix=$(installdir)

all-qemu: configure-qemu
	$(MAKE) -C $(srcdir)/qemu all

dev-qemu: all-qemu
	$(MAKE) -C $(srcdir)/qemu install

clean-qemu distclean-qemu: %-qemu:
	$(MAKE) -C $(srcdir)/qemu $*

all-jsonpath all-jsonlib all-argparse all-docutils all-pworker all-requests: all-%:
	cd $(srcdir)/$* && \
	sed -i 's/from setuptools import setup.*/from distutils.core import setup/' setup.py && \
	python setup.py build

dev-jsonpath dev-jsonlib dev-argparse dev-docutils dev-pworker dev-requests: dev-%: all-%
	cd $(srcdir)/$* && python setup.py install --prefix= --home=$(installdir)

clean-jsonpath clean-jsonlib clean-argparse clean-docutils clean-pworker clean-requests: clean-%:
	cd $(srcdir)/$* && python setup.py clean

distclean-jsonpath distclean-jsonlib distclean-argparse distclean-docutils distclean-pworker distclean-requests: distclean-%: clean-%

clean:
	-$(MAKE) -k $(addprefix clean-, $(SUBDIRS))

distclean:
	-$(MAKE) -k $(addprefix distclean-, $(SUBDIRS))
	rm -rf $(builddir) $(installdir) $(distdir) atos-$(atos_version)

release:
	$(MAKE) distclean
	$(MAKE) dev-talloc
	$(MAKE) dev-proot
	$(installdir)/bin/proot -r $(srcdir)/distros/rhlinux-i586-5el-rootfs -b $(srcdir) -b $(builddir) -b $(installdir) $(MAKE) builddir=$(builddir)/i386 installdir=$(installdir)/i386 dev-talloc
	$(installdir)/bin/proot -r $(srcdir)/distros/rhlinux-i586-5el-rootfs -b $(srcdir) -b $(builddir) -b $(installdir) $(MAKE) builddir=$(builddir)/i386 installdir=$(installdir)/i386 dev-proot
	$(installdir)/bin/proot -r $(srcdir)/distros/rhlinux-x86_64-5el-rootfs -b $(srcdir) -b $(builddir) -b $(installdir) $(MAKE) builddir=$(builddir)/x86_64 installdir=$(installdir)/x86_64 dev-talloc
	$(installdir)/bin/proot -r $(srcdir)/distros/rhlinux-x86_64-5el-rootfs -b $(srcdir) -b $(builddir) -b $(installdir) $(MAKE) builddir=$(builddir)/x86_64 installdir=$(installdir)/x86_64 dev-proot
	$(MAKE) dev-jsonpath
	$(MAKE) dev-jsonlib
	$(MAKE) dev-argparse
	$(MAKE) dev-docutils
	$(MAKE) dev-pworker
	$(MAKE) dev-requests
	$(MAKE) installdir=$(distdir) dev-atos-utils
	cp -a $(installdir)/lib/python $(distdir)/lib/atos
	mkdir -p $(distdir)/lib/atos/i386/bin
	cp -a $(installdir)/i386/bin/proot $(distdir)/lib/atos/i386/bin
	mkdir -p $(distdir)/lib/atos/x86_64/bin
	cp -a $(installdir)/x86_64/bin/proot $(distdir)/lib/atos/x86_64/bin
	env ROOT=$(distdir) $(MAKE) -C $(srcdir)/atos-utils tests
	cd $(distdir) && find * -type f | xargs sha1sum 2>/dev/null > $(srcdir)/RELEASE_MANIFEST.tmp
	mv $(srcdir)/RELEASE_MANIFEST.tmp $(distdir)/share/atos/RELEASE_MANIFEST
	./dependencies dump_actual > $(distdir)/share/atos/BUILD_MANIFEST
	cp -a $(distdir) atos-$(atos_version)
	tar czf atos-$(atos_version).tgz atos-$(atos_version)
	@echo "ATOS release package available in atos-$(version).tgz"
