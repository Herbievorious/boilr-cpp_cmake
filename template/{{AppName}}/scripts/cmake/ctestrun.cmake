# Copyright 2015 MUSIC Group IP Ltd. All rights reserved.
#
# The information contained herein is the property of MUSIC Group IP Ltd
# and is supplied without liability for errors and omissions. No part
# may be reproduced or used except as authorised by contract or other written
# permission. The copyright and the foregoing restriction on production
# use and disclosure extend to all media in which this information may
# be embodied.
#
# This file should be called using ctest from another CMakeLists.txt
#
# This file will:
#   * run unit tests
#   * perform memory checks using valgrind
#   * output results in .xml for Bamboo to parse
#
# If a test starts its name with "memtest" we assume that it is targeted
# to run with valgrind. Since these tests takes some time to perform we
# exclude them in unit test runs and include only these in memtest runs.

# a file called CTestConfig.cmake must be present
file(WRITE ${BINARY_DIRECTORY}/CTestConfig.cmake
"set(CTEST_PROJECT_NAME \"not_set\")\n"
"set(CTEST_DROP_SITE_CDASH FALSE)\n"
)

SET(CTEST_SOURCE_DIRECTORY ${SOURCE_DIRECTORY})
SET(CTEST_BINARY_DIRECTORY ${BINARY_DIRECTORY})
SET(CTEST_CMAKE_GENERATOR "Unix Makefiles")

if(WITH_MEMCHECK)
    find_program(CTEST_MEMORYCHECK_COMMAND NAMES valgrind)
    
    set(TMP_CMD "")
    set(TMP_CMD "${TMP_CMD} --tool=memcheck")
    set(TMP_CMD "${TMP_CMD} --error-exitcode=1")
    set(TMP_CMD "${TMP_CMD} --leak-check=full")
    set(TMP_CMD "${TMP_CMD} --show-reachable=yes")
    set(TMP_CMD "${TMP_CMD} --num-callers=50")
    #set(TMP_CMD "${TMP_CMD} --errors-for-leak-kinds=definite")
    #set(TMP_CMD "${TMP_CMD} --verbose")
    
    set(CTEST_MEMORYCHECK_COMMAND_OPTIONS ${TMP_CMD})
    
endif()

# A new subfolder might be created under /Testing, this makes Bamboo confused. 
file(REMOVE_RECURSE "${CTEST_BINARY_DIRECTORY}/Testing")

# Run the tests
ctest_start("Experimental")
ctest_test(SCHEDULE_RANDOM ON EXCLUDE "^memtest*.")

if(WITH_MEMCHECK)
    ctest_memcheck(INCLUDE "^memtest*.")
endif()
