#!/usr/bin/env bash
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

set -e

dir=`cd \`dirname $0\`; pwd`
srcroot=`dirname $dir`

pwd=$PWD
uname=`uname -m`
case $uname in
    i386|i486|i586|i686) arch=i386
	;;
    x86_64) arch=$uname
	;;
    *) arch=$uname
	;;
esac

version=`cd $srcroot/atos-utils; ./config/get_version.sh`

atosfiles=gnx5855.gnb.st.com:/home/compwork/projects/atos/

echo "Building atos version $version..."
rm -rf build distimage distro atos-$version atos-$version.tgz
mkdir -p build distimage distro devimage/lib/python

export PYTHONPATH=$pwd/devimage/lib/python
export PATH=$pwd/devimage/bin:$PATH

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_PROOT" = "" ]; then
    echo
    echo "Building proot..."
    mkdir build/proot
    pushd build/proot >/dev/null
    make -f $srcroot/proot/src/GNUmakefile clean all install PREFIX=$pwd/devimage
    popd >/dev/null
fi

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_QEMU" = "" ]; then
    echo
    echo "Building qemu-user-mode..."
    mkdir build/qemu
    pushd build/qemu >/dev/null
    $srcroot/qemu/configure --disable-system --target-list=i386-linux-user,x86_64-linux-user --prefix=$pwd/devimage
    make -j 4 all
    make install
    popd >/dev/null
fi

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_JSONPATH" = "" ]; then
    echo
    echo "Building jsonpath..."
    mkdir build/jsonpath
    pushd build/jsonpath >/dev/null
    scp $atosfiles/jsonpath-0.53.tar.gz .
    tar xzf jsonpath-0.53.tar.gz
    cd ./jsonpath-0.53
    ./setup.py install --prefix= --home=$pwd/devimage
    popd >/dev/null
fi

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_JSONLIB" = "" ]; then
    echo
    echo "Building jsonlib..."
    mkdir build/jsonlib
    pushd build/jsonlib >/dev/null
    scp $atosfiles/jsonlib-0.1.tar.gz .
    tar xzf jsonlib-0.1.tar.gz
    cd ./jsonlib-0.1
    ./setup.py install --prefix= --home=$pwd/devimage
    popd >/dev/null
fi

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_ARGPARSE" = "" ]; then
    echo
    echo "Building argparse..."
    mkdir build/argparse
    pushd build/argparse >/dev/null
    scp $atosfiles/argparse-1.2.1.tar.gz .
    tar xzf argparse-1.2.1.tar.gz
    cd ./argparse-1.2.1
    # Use distutils.core setup module instead of setuptools
    sed -i 's/from setuptools import setup.*/from distutils.core import setup/' setup.py
    python ./setup.py install --prefix= --home=$pwd/devimage
    popd >/dev/null
fi

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_DOCUTILS" = "" ]; then
    echo
    echo "Building docutils..."
    mkdir build/docutils
    pushd build/docutils >/dev/null
    scp $atosfiles/docutils-0.9.1.tar.gz .
    tar xzf docutils-0.9.1.tar.gz
    cd ./docutils-0.9.1
    python ./setup.py install --prefix= --home=$pwd/devimage
    popd >/dev/null
fi

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_DISTRO_I386" = "" ]; then
    echo
    echo "Creating rhlinux-i586-5el distro in distro/rhlinux-i586-5el-rootfs..."
    mkdir distro/rhlinux-i586-5el-rootfs
    scp $atosfiles/opensuse.org.repo.RHEL_5.i586.tgz .
    tar xzf opensuse.org.repo.RHEL_5.i586.tgz -C distro/rhlinux-i586-5el-rootfs 2>/dev/null || true
fi

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_DISTRO_X86_64" = "" ]; then
    echo
    echo "Creating rhlinux-x86_64-5el distro in distro/rhlinux-rhlinux-x86_64-5el-rootfs..."
    mkdir distro/rhlinux-x86_64-5el-rootfs
    scp $atosfiles/opensuse.org.repo.RHEL_5.x86_64.tgz .
    tar xzf opensuse.org.repo.RHEL_5.x86_64.tgz -C distro/rhlinux-x86_64-5el-rootfs 2>/dev/null || true
fi

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_PROOT_ATOS_I386" = "" ]; then
    echo
    echo "Building proot atos for i386 on RHEL_5 distro..."
    mkdir build/proot-atos-i386
    pushd build/proot-atos-i386 >/dev/null
    $pwd/devimage/bin/proot -W -Q $pwd/devimage/bin/qemu-i386 -b $pwd/devimage -b $srcroot/proot $pwd/distro/rhlinux-i586-5el-rootfs /usr/bin/make -f $srcroot/proot/src/GNUmakefile clean all install ENABLE_ADDONS="cc_deps cc_opts" PREFIX=$pwd/devimage/i386 CFLAGS="-Wall -O2" STATIC_BUILD=1
    popd >/dev/null
fi

if [ "$NO_BUILD_DEPS" = "" -a "$NO_BUILD_PROOT_ATOS_X86_64" = "" ]; then
    echo
    echo "Building proot atos for x86_64 on RHEL_5 distro..."
    mkdir build/proot-atos-x86_64
    pushd build/proot-atos-x86_64 >/dev/null
    $pwd/devimage/bin/proot -W -Q $pwd/devimage/bin/qemu-x86_64 -b $pwd/devimage -b $srcroot/proot $pwd/distro/rhlinux-x86_64-5el-rootfs /usr/bin/make -f $srcroot/proot/src/GNUmakefile clean all install ENABLE_ADDONS="cc_deps cc_opts" PREFIX=$pwd/devimage/x86_64 CFLAGS="-Wall -O2" STATIC_BUILD=1
    popd >/dev/null
fi

echo
echo "Building atos..."
pushd $srcroot/atos-utils >/dev/null
make -j 4 PREFIX=$pwd/distimage all doc install install-doc install-shared
popd >/dev/null
mkdir -p distimage/lib/atos
cp -a devimage/lib/python distimage/lib/atos/
for arch in i386 x86_64; do
    cp -a devimage/$arch distimage/lib/atos/
done

echo
echo "Testing atos..."
unset PYTHONPATH
pushd $srcroot/atos-utils >/dev/null
ROOT=$pwd/distimage make -C tests -j 4
popd >/dev/null

echo
echo "Packaging atos..."
cp -a distimage atos-$version
tar czf atos-$version.tgz atos-$version

echo
echo "ATOS package available in atos-$version.tgz."
echo "Completed."
