#!/bin/bash -e

echo "---------------------------------------------------------------------"
echo "Now building      : {{AppName}}"

#*******************************************************************************
# Settings (can be overridden on the command line)
#*******************************************************************************

# TODO: wget the dependecies from our debian package repo, unpack and use that instead

# Debian package version
: ${VERSION_PACKAGE:=1}

# Target architecture, amd64, i386, armhf, ...
: ${ARCHITECTURE:=amd64}

# Build type is release or debug
: ${BUILD_TYPE:=release}

# Share release/debug build directory
: ${SHARED_BUILD_DIR:=false}

# Continuous Integration build number, for example ${bamboo.buildNumber}
: ${BUILD_NUMBER:=0}

# Target install directory
: ${INSTALL_DIR:=/opt/midas}

# Compile objects in parallel, the -jN flag in make
: ${PARALLEL:=$(expr $(getconf _NPROCESSORS_ONLN) + 1)}

# Verbose make ON/OFF
: ${VERBOSE_MAKEFILE:=OFF}

# Current working directory
: ${WORKING_DIR:=$(pwd)}

# The absolute directory location for this script
: ${SCRIPTS_DIR:=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )}

# cmake scripts and modules for find_package(...)
: ${SCRIPTS_CMAKE:=${SCRIPTS_DIR}/cmake}

# semantic version "pre-release" field
: ${VERSION_PRE:="local"}

# git options to make the version string less verbose
: ${NO_GIT_HASH:=false}
: ${NO_GIT_BRANCH:=false}

# {{AppName}} options

: ${DISTCLEAN:=false}                   # remove the build directory before the build starts?
: ${UNITTEST:=false}                    # build and run unit tests
: ${PACKAGE:=false}                     # package into .tar.gz and/or .deb
: ${CCACHE_DISABLED:=false}             # disable ccache when building

# Use either TPL_ARTIFACTS or DEPENDENCIES below. If the TPL_ARTIFACTS path is
# specified you can easily work with multiple architectures
#
# TPL_ARTIFACTS is the location where "./{amd64,armhf,i386}/opt/midas/{lib,include,bin}" exists.
# The architecture will be used to figure out the full path. For example,
#
#   /home/user/packages/amd64/opt/midas/lib
#                      ^
#                      |
#                      +-------- specify path up to here
#
# example: TPL_ARTIFACTS=/home/user/packages
#
# If you don't want to use the TPL_ARTIFACTS variable, use the DEPENDENCIES variable
# instead and set he full absolute path to all the dependencies for the given
# architecture, as in <DEPENDENCIES>/{lib,include,bin}
#
# example: DEPENDENCIES=/home/user/packages/amd64/opt/midas
#
: ${TPL_ARTIFACTS:=}
: ${DEPENDENCIES:=${TPL_ARTIFACTS}/${ARCHITECTURE}/opt/midas}

# Pure source dependecies
: ${TPL_SOURCE:=${WORKING_DIR}/submodules}

# when cross compiling we need a rootfs where for example X11 can be found.
: ${ROOTFS:=}

#*******************************************************************************
# Load some generic helper functions
#*******************************************************************************
source ${SCRIPTS_DIR}/helper_functions.sh

#*******************************************************************************
# Check that we can access dependencies
#*******************************************************************************
if [[ "$OSTYPE" != "darwin"* ]]; then
    helper_check_dependencies_dir ${DEPENDENCIES}
fi

#*******************************************************************************
# CMake flags
#*******************************************************************************
CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_VERBOSE_MAKEFILE=${VERBOSE_MAKEFILE}"
CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
# versioning
CMAKE_FLAGS="${CMAKE_FLAGS} -DVERSION_PRE=${VERSION_PRE}"
CMAKE_FLAGS="${CMAKE_FLAGS} -DVERSION_BUILD=${BUILD_NUMBER}"
CMAKE_FLAGS="${CMAKE_FLAGS} -DVERSION_PACKAGE_RELEASE=${VERSION_PACKAGE}"
CMAKE_FLAGS="${CMAKE_FLAGS} -DNO_GIT_HASH=${NO_GIT_HASH}"
CMAKE_FLAGS="${CMAKE_FLAGS} -DNO_GIT_BRANCH=${NO_GIT_BRANCH}"
# cmake scripts and toolchains
CMAKE_FLAGS="${CMAKE_FLAGS} -DCCACHE_DISABLED=${CCACHE_DISABLED}"
CMAKE_FLAGS="${CMAKE_FLAGS} -DSCRIPTS_CMAKE=${SCRIPTS_CMAKE}"
# generate compile_commands.json file
CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_EXPORT_COMPILE_COMMANDS=1"

if [[ "$OSTYPE" == "darwin"* ]]; then
    if [ -z ${MINIMUM_OSX_VERSION} ]; then
        echo "$(basename $0): missing MINIMUM_OSX_VERSION variable"
        exit 1
    fi
    CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_OSX_DEPLOYMENT_TARGET=${MINIMUM_OSX_VERSION}"
fi


if [ ${ARCHITECTURE} == "amd64" ] || [ ${ARCHITECTURE} == "x86_64" ]; then
    :

elif [ ${ARCHITECTURE} == "i386" ]; then
    CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_TOOLCHAIN_FILE=${SCRIPTS_CMAKE}/TOOLCHAIN_x86_32.cmake"

elif [ ${ARCHITECTURE} == "armhf" ]; then
    CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_TOOLCHAIN_FILE=${SCRIPTS_CMAKE}/TOOLCHAIN_arm_tegra.cmake"
    CMAKE_FLAGS="${CMAKE_FLAGS} -DCMAKE_FIND_ROOT_PATH=${ROOTFS}"

elif [ ${ARCHITECTURE} == "osx" ]; then
    :

else
    >&2 echo "*** Error: Architecture '${ARCHITECTURE}' unknown."
    exit 1
fi

#*******************************************************************************
# Target specific settings
#*******************************************************************************
if [ ${SHARED_BUILD_DIR} == true ]; then
    BUILD_ARCH_DIR=build-${ARCHITECTURE}
else
    BUILD_ARCH_DIR=build-${ARCHITECTURE}-${BUILD_TYPE}
fi

echo "--- Pre-cmake ---"
echo "script dir        : ${SCRIPTS_DIR}"
echo "install dir       : ${INSTALL_DIR}"
echo "deb package       : ${VERSION_PACKAGE}"
echo "build number      : ${BUILD_NUMBER}"
echo "build type        : ${BUILD_TYPE}"
echo "build dir         : ${BUILD_ARCH_DIR}"
echo "distclean         : ${DISTCLEAN}"
echo "architecture      : ${ARCHITECTURE}"
echo "parallel          : ${PARALLEL}"
echo "dependencies dir  : ${DEPENDENCIES}"
echo "cmake flags       : ${CMAKE_FLAGS}"
echo "---------------------------------------------------------------------"

helper_time_measure_start

#*******************************************************************************
# Build
#*******************************************************************************
if [ ${DISTCLEAN} == true ]; then
    >&2 echo "*********************************************************************"
    >&2 echo "*** removing build directory: ${BUILD_ARCH_DIR}"
    >&2 echo "*********************************************************************"
    rm -rf ${BUILD_ARCH_DIR}
fi

# setup cmake
cmake -H. -B${BUILD_ARCH_DIR} ${CMAKE_FLAGS}

# build
make -C ${BUILD_ARCH_DIR} -j${PARALLEL} --no-print-directory

if [[ ${UNITTEST} == true ]]; then
    make -C ${BUILD_ARCH_DIR} -j${PARALLEL} --no-print-directory test-run
fi

if [[ ${PACKAGE} == true ]]; then
    make -C ${BUILD_ARCH_DIR} --no-print-directory package
fi

helper_time_measure_stop
