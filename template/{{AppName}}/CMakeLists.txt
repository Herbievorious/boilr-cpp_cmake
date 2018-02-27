# Basic CMakeLists

cmake_minimum_required(VERSION 2.8)
project({{AppName}})

set(APPNAME {{AppName}})

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib)

# Compiler path
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
set(CMAKE_SYSTEM_INCLUDE_PATH /usr/include CACHE INTERNAL "Include path")
set(CMAKE_SYSTEM_LIBRARY_PATH /usr/lib CACHE INTERNAL "Library path")
set(CMAKE_SYSTEM_PROGRAM_PATH /usr/bin CACHE INTERNAL "Bin path")

set(BUILD_DIR build)

# --------------
# Debugging info
# --------------
message(STATUS "====================================================================")
message(STATUS "")
message(STATUS "Build settings:")
message(STATUS "Configuring build as  : ${CMAKE_BUILD_TYPE}")

message(STATUS "Compiler              : ${CMAKE_CXX_COMPILER}")
message(STATUS "Build target          : ${BUILD_TARGET}")

message(STATUS "====================================================================")

set(EXAMPLE_UNIX_LIBRARIES
    stdc++
    pthread
)

# ------------------------
# Add CMake subdirectories
# ------------------------
#add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/src/")

# --------------------
# Include CMake macros
# --------------------
#include("AddCompileLinkFlags.cmake")

include_directories("${CMAKE_CURRENT_SOURCE_DIR}")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/src")

link_directories("${CMAKE_BINARY_DIR}/lib")

set(SOURCES src/main.cpp)

add_executable(${APPNAME} ${SOURCES})

set(CMAKE_C_FLAGS_RELEASE "-pipe -Wall -Werror -O3 -DNDEBUG -std=c++11 ${EXTRA_LIN_FLAGS}")
set(CMAKE_CXX_FLAGS_RELEASE "-pipe -Wall -Werror -O3 -DNDEBUG -std=c++11 ${EXTRA_LIN_FLAGS}")

set(CMAKE_C_FLAGS_DEBUG "-pipe -Wall -Werror -g -O0 -D_DEBUG -std=c++11 ${EXTRA_LIN_FLAGS}")
set(CMAKE_CXX_FLAGS_DEBUG "-pipe -Wall -Werror -g -O0 -D_DEBUG -std=c++11 ${EXTRA_LIN_FLAGS}")

set_target_properties(${APPNAME} PROPERTIES DEBUG_POSTFIX -debug)

target_link_libraries(${APPNAME} ${EXAMPLE_UNIX_LIBRARIES})
