#
# CMake recipes
#
# Copyright (c) 2018-2021, ETH Zurich
# BSD 3-Clause License. All rights reserved.
#
# author: Alberto Invernizzi (a.invernizzi@cscs.ch)
#

# Find ELPA library
#
# This module finds the ELPA library specified with ELPA_MODULE_SPEC variable with pkg-config.
# If you don't know how to set the ELPA_MODULE_SPEC variable, please check the output of
#
# pkg-config --list-all | grep elpa
#
# and pick the one you want.
# If found, this module creates the CMake target ELPA::ELPA

cmake_minimum_required(VERSION 3.12)

### Detect
if (NOT DEFINED ELPA_MODULE_SPEC)
  message(FATAL_ERROR "You should set ELPA_MODULE_SPEC to pkg-config module name")
endif()

find_package(PkgConfig)
pkg_search_module(PC_ELPA ${ELPA_MODULE_SPEC})

find_path(ELPA_INCLUDE_DIR
  NAMES elpa/elpa.h
  PATHS ${PC_ELPA_INCLUDE_DIRS}
)

find_library(ELPA_LIBRARY
  NAMES elpa elpa_openmp
  PATHS ${PC_ELPA_LIBRARY_DIRS}
)

### TEST
include(CMakePushCheckState)
cmake_push_check_state(RESET)

# Note:
# If the project does not enable the C language, check_symbol_exists may fail because the compiler,
# by looking at the file extension of the test, may decide to build it as CXX and not as C.
# For this reason, here it just checks that the symbol is available at linking.
set(CMAKE_REQUIRED_LIBRARIES
  ${ELPA_LIBRARY}
  ${PC_ELPA_LDFLAGS}
  ${PC_ELPA_LDFLAGS_OTHER})

include(CheckFunctionExists)

unset(ELPA_CHECK CACHE)
check_function_exists(elpa_allocate ELPA_CHECK)

cmake_pop_check_state()

### Package
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ELPA DEFAULT_MSG
  ELPA_LIBRARY
  ELPA_INCLUDE_DIR
  ELPA_CHECK
)

mark_as_advanced(
  ELPA_INCLUDE_DIR
  ELPA_LIBRARY
)

### CMake Target
if (ELPA_FOUND)
  if (NOT TARGET ELPA::ELPA)
    add_library(ELPA::ELPA UNKNOWN IMPORTED)
  endif()

  set_target_properties(ELPA::ELPA PROPERTIES
    IMPORTED_LOCATION ${ELPA_LIBRARY}
    INTERFACE_COMPILE_OPTIONS ${PC_ELPA_CFLAGS_OTHER}
    INTERFACE_INCLUDE_DIRECTORIES ${ELPA_INCLUDE_DIR}
    INTERFACE_LINK_LIBRARIES "${PC_ELPA_LDFLAGS};${PC_ELPA_LDFLAGS_OTHER}"
  )
endif()
