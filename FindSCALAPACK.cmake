#
# CMake recipes
#
# Copyright (c) 2018-2021, ETH Zurich
# BSD 3-Clause License. All rights reserved.
#
# author: Alberto Invernizzi (a.invernizzi@cscs.ch)
#

# Find SCALAPACK library
#
# ScaLAPACK depends on MPI and LAPACK, so it depends on other modules for their respective
# targets LAPACK::LAPACK and MPI::MPI_<LANG>. In particular, for the latter one, this module checks
# which language is enabled in the project and it adds all needed dependencies.
#
# Users can manually specify next variables (even by setting them empty to force use of
# the compiler implicit linking) to control which implementation they want to use:
#   SCALAPACK_LIBRARY
#       ;-list of {lib name, lib filepath, -Llibrary_folder}
#
# This module sets the following variables:
#   SCALAPACK_FOUND - set to true if a library implementing the SCALAPACK interface is found
#
# If ScaLAPACK symbols got found, it creates target SCALAPACK::SCALAPACK

cmake_minimum_required(VERSION 3.12)

macro(_scalapack_check_is_working)
  include(CMakePushCheckState)
  cmake_push_check_state(RESET)

  set(CMAKE_REQUIRED_QUIET TRUE)
  set(CMAKE_REQUIRED_LIBRARIES ${_DEPS})
  if (NOT SCALAPACK_LIBRARY STREQUAL "SCALAPACK_LIBRARIES-PLACEHOLDER-FOR-EMPTY-LIBRARIES")
    list(APPEND CMAKE_REQUIRED_LIBRARIES ${SCALAPACK_LIBRARY})
  endif()

  include(CheckFunctionExists)

  unset(_SCALAPACK_CHECK CACHE)
  check_function_exists(pdpotrf_ _SCALAPACK_CHECK)

  unset(_SCALAPACK_CHECK_BLACS CACHE)
  check_function_exists(Cblacs_exit _SCALAPACK_CHECK_BLACS)

  cmake_pop_check_state()
endmacro()

if (SCALAPACK_LIBRARY STREQUAL "" OR NOT SCALAPACK_LIBRARY)
  set(SCALAPACK_LIBRARY "SCALAPACK_LIBRARIES-PLACEHOLDER-FOR-EMPTY-LIBRARIES")
endif()

# Dependencies
set(_DEPS "")

find_package(LAPACK QUIET REQUIRED)
list(APPEND _DEPS "LAPACK::LAPACK")

find_package(MPI QUIET REQUIRED)
# Enable MPI Target for all enabled languages
get_property(_ENABLED_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES)
foreach(_LANG ${_ENABLED_LANGUAGES})
  list(APPEND _DEPS "MPI::MPI_${_LANG}")
endforeach()

mark_as_advanced(
  SCALAPACK_LIBRARY
)

_scalapack_check_is_working()

### Package
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(SCALAPACK DEFAULT_MSG
  SCALAPACK_LIBRARY
  _SCALAPACK_CHECK_BLACS
  _SCALAPACK_CHECK
  LAPACK_FOUND
  MPI_FOUND
)

# Remove the placeholder
if (SCALAPACK_LIBRARY STREQUAL "SCALAPACK_LIBRARIES-PLACEHOLDER-FOR-EMPTY-LIBRARIES")
  set(SCALAPACK_LIBRARY "")
endif()

if (SCALAPACK_FOUND)
  if (NOT TARGET SCALAPACK::SCALAPACK)
    add_library(SCALAPACK::SCALAPACK INTERFACE IMPORTED)
  endif()

  if (SCALAPACK_LIBRARY)
    target_link_libraries(SCALAPACK::SCALAPACK INTERFACE
      ${SCALAPACK_LIBRARY}
      ${_DEPS}
    )
  endif()
endif()
