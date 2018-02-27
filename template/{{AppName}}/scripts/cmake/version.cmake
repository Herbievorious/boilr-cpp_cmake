# Copyright 2015 MUSIC Group IP Ltd. All rights reserved.
#
# The information contained herein is the property of MUSIC Group IP Ltd
# and is supplied without liability for errors and omissions. No part
# may be reproduced or used except as authorised by contract or other written
# permission. The copyright and the foregoing restriction on production
# use and disclosure extend to all media in which this information may
# be embodied.
#
# The purpose of this file is to generate a version string that is
# compatible with semantic versioning, www.semver.org
#
# The version string should, if possible, contain the current git
# hash. This string can then be used to build a file called version.h
# which can be included in an application.

if(NOT OUTPUT_FOLDER)
    set(OUTPUT_FOLDER ${CMAKE_BINARY_DIR})
endif()

file(MAKE_DIRECTORY ${OUTPUT_FOLDER})

# always generate a .txt file
file(WRITE ${OUTPUT_FOLDER}/${VERSION_PREFIX}version.txt.in \@VERSION_FULL\@\n)

# recursively list "submodule status" used at build time
file(WRITE ${OUTPUT_FOLDER}/submodule_status.txt.in \@GIT_SUBMODULE_STATUS\@\n)

# generate a c/c++ compatible header file
if(VERSION_IN_ROM)
    # Create the version in ROM (useful for embedded applications that need
    # to store the version in flash instead of RAM
    file(WRITE ${OUTPUT_FOLDER}/${VERSION_PREFIX}version.h.in
        "const char * mkt_version = \"\@VERSION_FULL\@\";\n")
else()
    # Create the version in RAM (default behaviour appropriate for most cases)
    file(WRITE ${OUTPUT_FOLDER}/${VERSION_PREFIX}version.h.in
        "const char mkt_version[] = \"\@VERSION_FULL\@\";\n")
endif()

# alternative pure c++ style header file
#file(WRITE ${OUTPUT_FOLDER}/${VERSION_PREFIX}version.h.in
#    "const std::string mkt_version = \"\@VERSION_FULL\@\";\n")

find_package(Git QUIET)

if(GIT_FOUND) # true if the command line client was found
    # List all submodules. It is important to go into them to list untracked changes
    execute_process(
        COMMAND ${GIT_EXECUTABLE} submodule foreach --recursive ${GIT_EXECUTABLE} status
        RESULT_VARIABLE GIT_RETURNCODE
        OUTPUT_VARIABLE GIT_SUBMODULE_STATUS
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    # If the command failed we quietly do nothing
    if(GIT_RETURNCODE)
        unset(GIT_SUBMODULE_STATUS)
    endif()
endif()

if(NOT NO_GIT_HASH AND GIT_FOUND) # true if the command line client was found
    
    # extract the current sha hash from the current branch
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
        RESULT_VARIABLE GIT_RETURNCODE
        OUTPUT_VARIABLE GIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    # If the command failed we quietly do nothing
    if(GIT_RETURNCODE)
        unset(GIT_HASH)
    endif()
    
    # extract the current branch name
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
        RESULT_VARIABLE GIT_RETURNCODE
        OUTPUT_VARIABLE GIT_BRANCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    # If the command failed we quietly do nothing
    if(GIT_RETURNCODE)
        unset(GIT_BRANCH)
    else()
        # Only alphanumeric and - is allowed in the build metadata, therefore replace with -
        string(REPLACE "/" "-" GIT_BRANCH ${GIT_BRANCH})
        string(REPLACE "." "-" GIT_BRANCH ${GIT_BRANCH})
    endif()
    
    # check if we have modified files
    execute_process(
        #TODO: use "diff-index --quiet HEAD" instead?
        COMMAND ${GIT_EXECUTABLE} status --untracked-files=no --porcelain
        RESULT_VARIABLE GIT_RETURNCODE
        OUTPUT_VARIABLE GIT_DIRTY
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    # If the command failed we quietly do nothing
    if(GIT_RETURNCODE)
        unset(GIT_DIRTY)
    endif()
    
    # change the string of modified files into something more useful
    if(GIT_DIRTY)
        set(GIT_DIRTY "-dirty")
    endif()
    
    if(NO_GIT_BRANCH)
        # Don't use the branch information but do use other git information
        unset(GIT_BRANCH)
    endif()
endif()

# add the "pre-release" section, prefixed with a dash (-)
if(VERSION_PRE)
    # example: 1.2.3-beta.1
    set(VERSION_PRE "-${VERSION_PRE}")
endif()

if(VERSION_BUILD)
    # We have a build number. In order for file name sorting to work we
    # want to have the build number _after_ the branch information
    
    set(VERSION_BUILD_METADATA "+")
    if(NO_GIT_HASH)
        # example: "1.2.3+56"
        set(VERSION_BUILD_METADATA "${VERSION_BUILD_METADATA}${VERSION_BUILD}")
    else()
        # we have *some* git information
        
        if(GIT_BRANCH)
            # example: "feature-SAN-234-some-things-to-fix.678"
            set(GIT_INFORMATION "${GIT_BRANCH}.${VERSION_BUILD}")
        else()
            # start the string with the build number instead
            # example: "678"
            set(GIT_INFORMATION "${VERSION_BUILD}")
        endif()
        
        if(GIT_HASH)
            # example: feature-SAN-234-some-things-to-fix.678.08a2495-dirty
            # example: 678.08a2495
            set(GIT_INFORMATION "${GIT_INFORMATION}.${GIT_HASH}${GIT_DIRTY}")
        endif()
        
        # example: "1.2.3+feature-SAN-234-some-things-to-fix.678.08a2495-dirty"
        # example: "1.2.3+678.08a2495"
        set(VERSION_BUILD_METADATA "${VERSION_BUILD_METADATA}${GIT_INFORMATION}")
    endif()
else()
    # We do _not_ have a build number. We may have some git information.
    if(NOT NO_GIT_HASH)
        set(VERSION_BUILD_METADATA "+")
        if(GIT_BRANCH)
            # example: "feature-SAN-234-some-things-to-fix"
            set(GIT_INFORMATION "${GIT_BRANCH}")
            
            if(GIT_HASH)
                # example: "feature-SAN-234-some-things-to-fix.08a2495-dirty"
                set(GIT_INFORMATION "${GIT_INFORMATION}.${GIT_HASH}${GIT_DIRTY}")
            endif()
        else()
            if(GIT_HASH)
                # example: "08a2495"
                set(GIT_INFORMATION "${GIT_HASH}${GIT_DIRTY}")
            endif()
        endif()
        
        # example: 1.2.3+feature-SAN-234-some-things-to-fix.08a2495-dirty
        # example: 1.2.3+08a2495
        set(VERSION_BUILD_METADATA "${VERSION_BUILD_METADATA}${GIT_INFORMATION}")
    endif()
endif()

# assemble the full semantic version compatible version string
set(VERSION_FULL "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}${VERSION_PRE}${VERSION_BUILD_METADATA}")

configure_file(${OUTPUT_FOLDER}/${VERSION_PREFIX}version.h.in     ${OUTPUT_FOLDER}/${VERSION_PREFIX}version.h)
configure_file(${OUTPUT_FOLDER}/${VERSION_PREFIX}version.txt.in   ${OUTPUT_FOLDER}/${VERSION_PREFIX}version.txt)
configure_file(${OUTPUT_FOLDER}/submodule_status.txt.in           ${OUTPUT_FOLDER}/submodule_status.txt)

message(STATUS "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
message(STATUS "Project application version : ${VERSION_FULL}")
message(STATUS "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
