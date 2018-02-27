# Copyright 2018 MUSIC Group IP Ltd. All rights reserved.
#
# The information contained herein is the property of MUSIC Group IP Ltd
# and is supplied without liability for errors and omissions. No part
# may be reproduced or used except as authorised by contract or other written
# permission. The copyright and the foregoing restriction on production
# use and disclosure extend to all media in which this information may
# be embodied.
cmake_minimum_required(VERSION 2.8)

project({{AppName}})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
find_program(CCACHE_PROGRAM ccache)
if(NOT WIN32 AND CCACHE_PROGRAM AND NOT CCACHE_DISABLED)
    # speed up recompiling, look at ccache -p for settings, increasing cache size might be beneficial
    # apt-get install ccache
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
else()
    set(CCACHE_PROGRAM "DISABLED")
endif()

include(CTest)
include(ProcessorCount)
ProcessorCount(PROCESSORCOUNT)

# Check that $BUILD_TYPE has been set correctly in the makefile
if(NOT CMAKE_BUILD_TYPE MATCHES "^([Dd]ebug|[Rr]elease)$")
    message(FATAL_ERROR "Invalid BUILD_TYPE: ${CMAKE_BUILD_TYPE}. Use 'Debug' or 'Release'")
endif()

############################################################################################
# semantic versioning, www.semver.org
set(VERSION_MAJOR   0)
set(VERSION_MINOR   0)
set(VERSION_PATCH   1)
############################################################################################

set(CMAKE_MODULE_PATH  ${CMAKE_MODULE_PATH}  ${SCRIPTS_CMAKE})
set(CMAKE_INCLUDE_PATH ${CMAKE_INCLUDE_PATH} ${SCRIPTS_CMAKE})
set(VERSION_PREFIX     "mkt-")
set(VERSION_OUTPUT_DIR ${CMAKE_BINARY_DIR}/version)

find_file(VERSION_DOT_CMAKE  version.cmake)
find_file(CTESTRUN_DOT_CMAKE ctestrun.cmake)

if(NOT EXISTS ${VERSION_DOT_CMAKE})
    message(FATAL_ERROR "Can't find version.cmake in ${SCRIPTS_CMAKE}")
endif()

if(NOT EXISTS ${CTESTRUN_DOT_CMAKE})
    message(FATAL_ERROR "Can't find ctestrun.cmake in ${SCRIPTS_CMAKE}")
endif()

# ------------------------------
# check if we're cross compiling
# ------------------------------
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^arm.*$")
    if(NOT CMAKE_FIND_ROOT_PATH)
        message(WARNING "It looks like you are cross compiling but the rootfs location is not set")
    endif()

    if(NOT IS_ABSOLUTE ${CMAKE_FIND_ROOT_PATH})
        # force the rootfs path to be absolute. Packages will not be found otherwise.
        get_filename_component(ABS_ROOT_PATH ${CMAKE_FIND_ROOT_PATH} ABSOLUTE)
        set(CMAKE_FIND_ROOT_PATH ${ABS_ROOT_PATH})
        message(WARNING "Forcing rootfs location to be an absolute path: ${CMAKE_FIND_ROOT_PATH}")
    endif()
endif()

# ---------
# OSX Flags
# ---------
if(APPLE)
    add_definitions(
        -DTARGET_OSX
        -DLOG4CXX_STATIC
    )
endif()

# ---------
# Windows Flags
# ---------
if(WIN32)
    set(CMAKE_VS_PLATFORM_TOOLSET "v110")
    add_definitions(
        -DWIN32
        -D_WINDOWS
        -DNOMINMAX
    )
endif()

# ---------
# ARM Flags
# ---------
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^arm.*$")
    add_definitions(
        -DLINUX
        -D__ARM_LINUX__
    )
endif()

# ----------------------
# Build type based flags
# ----------------------
if(APPLE)
    # -Wall is not enabled on OSX builds for now, there are too many of them.
    set(CMAKE_C_FLAGS       "-pipe -Werror ${CMAKE_C_FLAGS}")
    set(CMAKE_CXX_FLAGS     "-pipe -Werror -std=c++11 -stdlib=libc++ ${CMAKE_CXX_FLAGS}")
else()
    set(CMAKE_C_FLAGS       "-fPIC -pipe -Wall -Werror ${CMAKE_C_FLAGS}")
    set(CMAKE_CXX_FLAGS     "-fPIC -pipe -Wall -Werror -std=c++11 ${CMAKE_CXX_FLAGS}")
endif()

set(CMAKE_C_FLAGS_RELEASE   "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")

set(CMAKE_C_FLAGS_DEBUG     "-g -O0 -D_DEBUG -fmessage-length=0")
set(CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_C_FLAGS_DEBUG}")


# --------------------------
# Print configuration
# --------------------------

message(STATUS "====================================================================")
message(STATUS "Project               : ${PROJECT_NAME}")
message(STATUS "-- Features --")
message(STATUS "-- Options --")
message(STATUS "")
message(STATUS "-- Libraries --")
message(STATUS "")
message(STATUS "-- Includes --")
message(STATUS "")
message(STATUS "-- Resources --")
message(STATUS "")
message(STATUS "Configuring build as  : ${CMAKE_BUILD_TYPE}")
message(STATUS "Verbose makefiles     : ${CMAKE_VERBOSE_MAKEFILE}")
message(STATUS "")
message(STATUS "Compiler              : ${CMAKE_CXX_COMPILER}")
message(STATUS "System Name           : ${CMAKE_SYSTEM_NAME}")
message(STATUS "System Processor      : ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "rootfs                : ${CMAKE_FIND_ROOT_PATH}")
message(STATUS "ProcessorCount        : ${PROCESSORCOUNT}")
message(STATUS "====================================================================")
message(STATUS "Compiler flags:")
message(STATUS "CMAKE_C_FLAGS           : ${CMAKE_C_FLAGS}")
message(STATUS "CMAKE_C_FLAGS_DEBUG     : ${CMAKE_C_FLAGS_DEBUG}")
message(STATUS "CMAKE_C_FLAGS_RELEASE   : ${CMAKE_C_FLAGS_RELEASE}")
message(STATUS "CMAKE_CXX_FLAGS         : ${CMAKE_CXX_FLAGS}")
message(STATUS "CMAKE_CXX_FLAGS_DEBUG   : ${CMAKE_CXX_FLAGS_DEBUG}")
message(STATUS "CMAKE_CXX_FLAGS_RELEASE : ${CMAKE_CXX_FLAGS_RELEASE}")
message(STATUS "====================================================================")
message(STATUS "Compiler version        : ${CMAKE_CXX_COMPILER_VERSION}")
message(STATUS "====================================================================")

# --------------------------
# Add subdirectories
# --------------------------
# Pass the configuration down the tree for the source
add_subdirectory(src)

# --------------------------
# Get version target
# --------------------------
add_custom_target(
    get_version
    ${CMAKE_COMMAND}    -D VERSION_MAJOR=${VERSION_MAJOR}
                        -D VERSION_MINOR=${VERSION_MINOR}
                        -D VERSION_PATCH=${VERSION_PATCH}
                        -D VERSION_PRE=${VERSION_PRE}
                        -D VERSION_BUILD=${VERSION_BUILD}
                        -D VERSION_PREFIX=${VERSION_PREFIX}
                        -D NO_GIT_HASH=${NO_GIT_HASH}
                        -D NO_GIT_BRANCH=${NO_GIT_BRANCH}
                        -D OUTPUT_FOLDER=${VERSION_OUTPUT_DIR}
                        -P ${VERSION_DOT_CMAKE}
    COMMENT "Assembling version string"
)



############################################################################################
# Unit testing
############################################################################################

# ----------------------------------------------------
# Target to build all test binaries without executing
# ----------------------------------------------------
add_custom_target(test-build
    DEPENDS get_version
    # DEPENDS <-- add more executables here-->
)

# ----------------------------------------------------
# Target to run unit tests and memory checks
# ----------------------------------------------------
add_custom_target(
    test-run
    ${CMAKE_CTEST_COMMAND}
    -D SOURCE_DIRECTORY=${CMAKE_SOURCE_DIR}
    -D BINARY_DIRECTORY=${CMAKE_BINARY_DIR}
    -S ${CTESTRUN_DOT_CMAKE}
    --parallel ${PROCESSORCOUNT}
    #--output-on-failure
    -V
    COMMENT "Running unit tests and memory checks"
    DEPENDS test-build
)
