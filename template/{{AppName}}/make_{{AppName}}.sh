#!/bin/sh
: ${CXX:=/usr/bin/g++-4.8}
: ${CC:=/usr/bin/gcc-4.8}
export CXX=${CXX}
export CC=${CC}
TPL_ARTIFACTS={{TPLArtifacts}} \
ROOTFS=${TPL_ARTIFACTS}/sdk/sysroots/cortexa15hf-vfp-neon-poky-linux-gnueabi \
BUILDNR=$(date +%s) \
./scripts/build_{{AppName}}.sh