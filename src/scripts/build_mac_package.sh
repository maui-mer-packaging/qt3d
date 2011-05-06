#!/bin/bash

set -e

APP=QtQuick3D

PRO=quick3d.pro

if [[ -z "$1" ]]; then
    echo "Usage: build_bundle.sh 1.2.3"
    echo "(where 1.2.3 is the version number)"
    exit 1;
fi

if [[ ! -f ./quick3d.pro ]]; then
    echo "Could not find quick3d.pro in current directory."
    echo "This script should be run from the root of a Qt3D source tree."
    exit 1;
fi

VER=$1

echo "Building ${APP}..."
qmake -makefile -spec macx-g++ -r CONFIG+=release CONFIG+=package quick3d.pro
make $(JOBS)

DIST=dist
DEV=dev
DEV_PKG_ROOT="$DIST/$DEV/Pkg_Root"
mkdir -p $DEV_PKG_ROOT
INSTALL_ROOT=$PWD/dist/dev/Pkg_Root make $(JOBS) install

make docs
DOC_LOC="Developer/Documentation/QtQuick3D"
mkdir -p "$DEV_PKG_ROOT/$DOC_LOC"
mv doc/html "$DEV_PKG_ROOT/$DOC_LOC"

DEV_PKG_RES="$DIST/$DEV/Resources"
mkdir -p $DEV_PKG_RES
cp src/scripts/mac_installer_background.png $DEV_PKG_RES/background.png

XMPL=examples
XMPL_PKG_ROOT="$DIST/$XMPL/Pkg_Root"
mkdir -p "$XMPL_PKG_ROOT"

XMPL_PKG_RES="$DIST/$XMPL/Resources"
mkdir -p $XMPL_PKG_RES
cp src/scripts/mac_installer_background.png $XMPL_PKG_RES/background.png

XMPL_LOC="Applications/QtQuick3D Examples"
mkdir -p "${XMPL_PKG_ROOT}/$XMPL_LOC"
mv "${DEV_PKG_ROOT}/Developer/Tools/Qt" "${XMPL_PKG_ROOT}/$XMPL_LOC"

RELEASE_DIR="../${APP}-${VER}"
mkdir -p "${RELEASE_DIR}"

# http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/packagemaker.1.html
# ...or see $PKGMKR -help for options
# some useful tips at http://homepage.mac.com/simx/technonova/tips/packagemaker_and_installer.html
# but a bit out of date - eg options now have --switch syntax and plist files are not used

PKGMGR="/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker"

## TODO: create VolumeCheck script to ensure 4.7.2 is installed
PKG="${RELEASE_DIR}/${APP}-${VER}-${DEV}.pkg"
$PKGMGR --root "$DEV_PKG_ROOT" \
    --id "com.nokia.qtquick3d.${DEV}" \
    --resources "$DEV_PKG_RES" \
    --title "Core Developer Tools" \
    --target 10.5 --version "$VER" --verbose --out "$PKG"

PKG="${RELEASE_DIR}/${APP}-${VER}-${XMPL}.pkg"
$PKGMGR --root "$XMPL_PKG_ROOT" \
    --id "com.nokia.qtquick3d.${XMPL}" \
    --resources "$XMPL_PKG_RES" \
    --title "Example Applications" \
    --target 10.5 --version "$VER" --verbose --out "$PKG"

DMG="../${APP}-${VER}.dmg"

echo "Placing packages into disk image"
hdiutil create -srcfolder ${RELEASE_DIR} ${DMG}
hdiutil internet-enable -yes ${DMG}

echo "New distributable ready in ${DMG}"