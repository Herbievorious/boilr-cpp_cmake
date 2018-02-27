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

# --------------------------
# Add executables and libraries
# --------------------------
add_executable(${PROJECT_NAME}
    main.cpp
)

# ------------------
# Executable dependencies
# ------------------
add_dependencies(${PROJECT_NAME} get_version)

# --------------------------
# Link
# --------------------------
# Platform specific
if(WIN32)
    target_link_libraries(${PROJECT_NAME}
        version
        mswsock
        winmm
        ws2_32
        kernel32
        odbc32
        Imm32)
else()
    target_link_libraries(${PROJECT_NAME}
        pthread
        stdc++
        dl)
endif()

# Linux and ARM specific
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(${PROJECT_NAME} rt)
endif()

# ---------------------
# Post build steps
# ---------------------
set_target_properties(${PROJECT_NAME}
    PROPERTIES
    OUTPUT_NAME ${PROJECT_NAME}
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)

install(TARGETS ${PROJECT_NAME}
    RUNTIME
    DESTINATION opt/midas/bin/
)

############################################################################################
# use cpack to package distribution files
############################################################################################
set(CPACK_PACKAGE_NAME                  mkt-{{AppName}})
set(CPACK_GENERATOR                     "TGZ")

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(CPACK_GENERATOR "${CPACK_GENERATOR};DEB")
endif()

set(CPACK_DEB_COMPONENT_INSTALL         OFF)
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY    OFF)
set(CPACK_OUTPUT_FILE_PREFIX            packages)

if(CMAKE_BUILD_TYPE MATCHES "^([Dd]ebug)$")
    set(DESCRIPTION_SUMMARY_WARNING "** This is a debug build ** ")
else()
    # release builds have stripped binaries in the package
    set(CPACK_STRIP_FILES TRUE)
endif()

# ---------------------------------------------------------------
set(CPACK_PACKAGE_CONTACT               "Music Group Research UK (Linux Packages) <linux-packages@music-group.com>")
set(CPACK_PACKAGE_VENDOR                "Music Group Research UK")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY
    "${DESCRIPTION_SUMMARY_WARNING}{{AppName}}")
set(CPACK_PACKAGING_INSTALL_PREFIX      "/")
set(CPACK_DEBIAN_PACKAGE_PRIORITY       "optional")
set(CPACK_DEBIAN_PACKAGE_SECTION        "midas")

# Dependencies, alphabetical
#set(CPACK_DEBIAN_PACKAGE_DEPENDS "${CPACK_DEBIAN_PACKAGE_DEPENDS} boost-runtime (>= ${BOOST_VERSION}),")
#set(CPACK_DEBIAN_PACKAGE_DEPENDS "${CPACK_DEBIAN_PACKAGE_DEPENDS} log4cxx-runtime (>= ${LOG4CXX_VERSION}),")

# The last dependency should _not_ have a comma at the end
#set(CPACK_DEBIAN_PACKAGE_DEPENDS "${CPACK_DEBIAN_PACKAGE_DEPENDS} libzmq-runtime (>= ${LIBZMQ_VERSION})")

# ---------------------------------------------------------------

set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA
    "${CMAKE_CURRENT_SOURCE_DIR}/debian/preinst;${CMAKE_CURRENT_SOURCE_DIR}/debian/postinst;${CMAKE_CURRENT_SOURCE_DIR}/debian/prerm;${CMAKE_CURRENT_SOURCE_DIR}/debian/postrm;"
)

if(NOT VERSION_PACKAGE_RELEASE)
    set(VERSION_PACKAGE_RELEASE 1)
endif()

# set the cpack version. This doesn't have to contain any pre-release or build metadata information
set(CPACK_PACKAGE_RELEASE ${VERSION_PACKAGE_RELEASE})
set(CPACK_PACKAGE_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-${CPACK_PACKAGE_RELEASE}")

# add the apropriate architecture to the package name
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64")
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")

elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_32")
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")

elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^arm.*$")
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "armhf")

else()
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "all")
    message(WARNING "Unable to determine architecture for packaging")

endif()

set(CPACK_SOURCE_IGNORE_FILES
    "^${PROJECT_SOURCE_DIR}/.git/"
    "^${PROJECT_SOURCE_DIR}/build.*/"
)

# **********************************************************************
# cpack is configured before anything is built, which makes build-time
# dependencies tricky. We can generate some template files and configure
# cpack with add_custom_targets() and add_dependencies()
file(WRITE ${CMAKE_BINARY_DIR}/CPackOptions.cmake.in
"# -------- Start generated file
set(CPACK_PACKAGE_FILE_NAME
    \"\${CPACK_PACKAGE_NAME}_\@VERSION_FULL_READBACK\@.\${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}\"
)
# -------- End generated file\n"
)

file(WRITE ${CMAKE_BINARY_DIR}/CPackOptions-create.cmake
"# -------- Start generated file
file(STRINGS \${VERSION_OUTPUT_DIR}/${VERSION_PREFIX}version.txt VERSION_FULL_READBACK LIMIT_COUNT 1)
configure_file(${CMAKE_BINARY_DIR}/CPackOptions.cmake.in
               ${CMAKE_BINARY_DIR}/CPackOptions.cmake
               @ONLY
)
# -------- End generated file\n"
)

add_custom_target(modify_cpack_package_name
    COMMAND ${CMAKE_COMMAND}
    -D VERSION_OUTPUT_DIR=${VERSION_OUTPUT_DIR}
    -P ${CMAKE_BINARY_DIR}/CPackOptions-create.cmake
    DEPENDS get_version
)

add_dependencies(${PROJECT_NAME} modify_cpack_package_name)

set(CPACK_PROJECT_CONFIG_FILE ${CMAKE_BINARY_DIR}/CPackOptions.cmake)
# **********************************************************************

if(NOT WIN32)
    include(CPack)
endif()

message(STATUS "--------------------------------------------------------------------")
message(STATUS "CPACK_DEBIAN_PACKAGE_ARCHITECTURE   : ${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}")
message(STATUS "CPACK_PACKAGE_VERSION               : ${CPACK_PACKAGE_VERSION}")
message(STATUS "CPACK_PACKAGING_INSTALL_PREFIX      : ${CPACK_PACKAGING_INSTALL_PREFIX}")
message(STATUS "CMAKE_INSTALL_PREFIX                : ${CMAKE_INSTALL_PREFIX}")
message(STATUS "====================================================================")

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Generate a file that keeps track of the current build config (debug or release)
# and the version string so we can package this inside the deb/zip/rpm
file(WRITE ${CMAKE_BINARY_DIR}/buildconf.txt.in
"\${BUILD_TYPE}
\${VERSION_FULL_READBACK}
\${BUILD_ARCH}
"
)

file(WRITE ${CMAKE_BINARY_DIR}/CPackBuildConf.cmake
"# -------- Start generated file
file(STRINGS \${VERSION_OUTPUT_DIR}/${VERSION_PREFIX}version.txt VERSION_FULL_READBACK LIMIT_COUNT 1)
configure_file(${CMAKE_BINARY_DIR}/buildconf.txt.in ${CMAKE_BINARY_DIR}/buildconf.txt)
# -------- End generated file\n"
)

add_custom_target(generate_buildconf_file
    COMMAND ${CMAKE_COMMAND}
    -D BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -D BUILD_ARCH=${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}
    -D VERSION_OUTPUT_DIR=${VERSION_OUTPUT_DIR}
    -P ${CMAKE_BINARY_DIR}/CPackBuildConf.cmake
    DEPENDS get_version
)

add_dependencies(${PROJECT_NAME} generate_buildconf_file)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------
# install targets, used by cpack
# ---------------------------------------------------------------

#install(FILES
#        ${CMAKE_BINARY_DIR}/buildconf.txt
#        DESTINATION opt/midas/resources/{{AppName}}/
#)
#install(DIRECTORY
#        ${CMAKE_SOURCE_DIR}/config
#        DESTINATION opt/midas/resources/{{AppName}}/
#)

#install(FILES
#        debian/lib/systemd/system/mkt-{{AppName}}.service
#        DESTINATION lib/systemd/system/
#)

