#
# CMake recipes
# https://github.com/eth-cscs/cmake-recipes
#
# Copyright (c) 2018-2019, ETH Zurich
# BSD 3-Clause License. All rights reserved.
#
# Author: Teodor Nikolov (teodor.nikolov22@gmail.com)
#
#[=======================================================================[.rst:
FindMKL
-------

The following conventions are used:

seq / SEQ      - sequential MKL
omp / OMP      - threaded MKL with OpenMP back end
tbb / TBB      - threaded MKL with TBB back end
32bit / 32BIT  - MKL 32 bit integer interface (used most often)
64bit / 64BIT  - MKL 64 bit integer interface
mpich / MPICH  - MPICH / IntelMPI BLACS back end
ompi / OMPI    - OpenMPI BLACS back end

The module attempts to define a target for each MKL configuration. The
configuration will not be available if there are missing library files or a
missing dependency.

Search variables
^^^^^^^^^^^^^^^^

``MKLROOT``
  Environment variable set to MKL's root directory

``MKL_ROOT``
  CMake variable set to MKL's root directory

Example usage
^^^^^^^^^^^^^

To Find MKL:

  find_package(MKL REQUIRED)

To check if target is available:

  if (TARGET mkl::scalapack_mpich_32bit_seq)
    ...
  endif()

To link to an available target (see list below):

  target_link_libraries(... mkl::scalapack_mpich_32bit_omp)

Note: dependencies are handled for you (MPI, OpenMP, ...)

Imported targets
^^^^^^^^^^^^^^^^

mkl::core

mkl::blas_32bit_seq
mkl::blas_32bit_omp
mkl::blas_32bit_tbb
mkl::blas_64bit_seq
mkl::blas_64bit_omp
mkl::blas_64bit_tbb

mkl::blacs_mpich_32bit_seq
mkl::blacs_mpich_32bit_omp
mkl::blacs_mpich_32bit_tbb
mkl::blacs_mpich_64bit_seq
mkl::blacs_mpich_64bit_omp
mkl::blacs_mpich_64bit_tbb
mkl::blacs_ompi_32bit_seq
mkl::blacs_ompi_32bit_omp
mkl::blacs_ompi_32bit_tbb
mkl::blacs_ompi_64bit_seq
mkl::blacs_ompi_64bit_omp
mkl::blacs_ompi_64bit_tbb

mkl::scalapack_mpich_32bit_seq
mkl::scalapack_mpich_32bit_omp
mkl::scalapack_mpich_32bit_tbb
mkl::scalapack_mpich_64bit_seq
mkl::scalapack_mpich_64bit_omp
mkl::scalapack_mpich_64bit_tbb
mkl::scalapack_ompi_32bit_seq
mkl::scalapack_ompi_32bit_omp
mkl::scalapack_ompi_32bit_tbb
mkl::scalapack_ompi_64bit_seq
mkl::scalapack_ompi_64bit_omp
mkl::scalapack_ompi_64bit_tbb

Result variables
^^^^^^^^^^^^^^^^

MKL_FOUND

Not supported
^^^^^^^^^^^^^

- F95 interfaces

Note: Mixing GCC and Intel OpenMP backends is a bad idea.

#]=======================================================================]

cmake_minimum_required(VERSION 3.12)

# Modules
#
include(FindPackageHandleStandardArgs)

# Functions
#
function(__mkl_find_library _name)
    find_library(${_name}
        NAMES ${ARGN}
        HINTS ${MKL_ROOT}
              ${MKL_ROOT}/mkl
        PATH_SUFFIXES ${_mkl_libpath_suffix}
                      lib
        )
    mark_as_advanced(${_name})
endfunction()

# Dependencies
#
find_package(Threads)
find_package(MPI COMPONENTS CXX)
find_package(OpenMP COMPONENTS CXX)

# Options
#
# The `NOT DEFINED` guards on CACHED variables are needed to make sure that
# normal variables of the same name always take precedence*.
#
# * In v3.12, both `option()` and `set(... CACHE ...)` override normal
#   variables if a) cached equivalents don't exist or b) their type is not 
#   specified (e.g. command line arguments: -DFOO=ON instead of
#   -DFOO:BOOL=ON). Since v3.13 with policy CMP0077, `option()` no longer overrides
#   normal variables of the same name. `set(... CACHE ...)` is still stuck with
#   the old behaviour.
#
#   https://cmake.org/cmake/help/v3.15/command/set.html#set-cache-entry
#   https://cmake.org/cmake/help/v3.15/policy/CMP0077.html
#
if(NOT DEFINED MKL_ROOT)
    set(MKL_ROOT $ENV{MKLROOT} CACHE PATH "MKL's root directory.")
endif()

# Determine MKL's library folder
#
set(_mkl_libpath_suffix "lib/intel64")
if(CMAKE_SIZEOF_VOID_P EQUAL 4) # 32 bit
    set(_mkl_libpath_suffix "lib/ia32")
endif()

if(WIN32)
    string(APPEND _mkl_libpath_suffix "_win")
elseif(APPLE)
    string(APPEND _mkl_libpath_suffix "_mac")
else()
    string(APPEND _mkl_libpath_suffix "_lin")
endif()

# Find MKL header
#
find_path(MKL_INCLUDE_DIR mkl.h
    HINTS ${MKL_ROOT}/include
          ${MKL_ROOT}/mkl/include
    )
mark_as_advanced(MKL_INCLUDE_DIR)

# Core MKL
#
__mkl_find_library(MKL_CORE_LIB mkl_core)

# BLAS
#
__mkl_find_library(MKL_INTERFACE_32BIT_LIB mkl_intel_lp64)
__mkl_find_library(MKL_INTERFACE_64BIT_LIB mkl_intel_ilp64)

__mkl_find_library(MKL_SEQ_LIB mkl_sequential)
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND NOT APPLE)
    __mkl_find_library(MKL_OMP_LIB mkl_gnu_thread)
else()
    __mkl_find_library(MKL_OMP_LIB mkl_intel_thread)
endif()
__mkl_find_library(MKL_TBB_LIB mkl_tbb_thread)

# BLACS
#
if(APPLE)
    __mkl_find_library(MKL_BLACS_MPICH_32BIT_LIB mkl_blacs_mpich_lp64)
    __mkl_find_library(MKL_BLACS_MPICH_64BIT_LIB mkl_blacs_mpich_ilp64)
else()
    __mkl_find_library(MKL_BLACS_MPICH_32BIT_LIB mkl_blacs_intelmpi_lp64)
    __mkl_find_library(MKL_BLACS_MPICH_64BIT_LIB mkl_blacs_intelmpi_ilp64)
endif()
__mkl_find_library(MKL_BLACS_OMPI_32BIT_LIB mkl_blacs_openmpi_lp64)
__mkl_find_library(MKL_BLACS_OMPI_64BIT_LIB mkl_blacs_openmpi_ilp64)

# ScaLAPACK
#
__mkl_find_library(MKL_SCALAPACK_32BIT_LIB mkl_scalapack_lp64)
__mkl_find_library(MKL_SCALAPACK_64BIT_LIB mkl_scalapack_ilp64)

# Check if core libs were found
#
find_package_handle_standard_args(MKL REQUIRED_VARS MKL_INCLUDE_DIR
                                                    MKL_CORE_LIB
                                                    Threads_FOUND)

if (MKL_FOUND AND NOT TARGET mkl::core)
    add_library(mkl::core INTERFACE IMPORTED)
    set_target_properties(mkl::core PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${MKL_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "${MKL_CORE_LIB}")
endif()

# Define all blas, blacs and scalapack
#
foreach(_bits "32BIT" "64BIT")
    set(_mkl_interface_lib ${MKL_INTERFACE_${_bits}_LIB})
    set(_mkl_scalapack_lib ${MKL_SCALAPACK_${_bits}_LIB})

    foreach(_threading "SEQ" "OMP" "TBB")
        string(TOLOWER "${_bits}_${_threading}" _tgt_config)
        set(_blas_tgt mkl::blas_${_tgt_config})
        set(_mkl_threading_lib ${MKL_${_threading}_LIB})

        set(_mkl_threading_deps "Threads::Threads")
        if(${_threading} STREQUAL "OMP" )
            if(TARGET OpenMP::OpenMP_CXX)
                set(_mkl_deps "OpenMP::OpenMP_CXX;Threads::Threads")
            else()
                continue() # skip all OMP targets
            endif()
        endif()

        set(_mkl_prefix_libs "${_mkl_interface_lib};${_mkl_threading_lib};mkl::core")
        if(MKL_FOUND
           AND _mkl_interface_lib
           AND _mkl_threading_lib
           AND NOT TARGET ${_blas_tgt})
            add_library(${_blas_tgt} INTERFACE IMPORTED)
            set_target_properties(${_blas_tgt} PROPERTIES
              INTERFACE_LINK_LIBRARIES "${_mkl_prefix_libs};${_mkl_threading_deps}")
        endif()

        foreach(_mpi_impl "MPICH" "OMPI")
            string(TOLOWER "${_mpi_impl}_${_bits}_${_threading}" _tgt_config)
            set(_blacs_tgt mkl::blacs_${_tgt_config})
            set(_scalapack_tgt mkl::scalapack_${_tgt_config})
            set(_mkl_blacs_lib ${MKL_BLACS_${_mpi_impl}_${_bits}_LIB})

            if(_mkl_blacs_lib
               AND TARGET MPI::MPI_CXX
               AND TARGET ${_blas_tgt}
               AND NOT TARGET ${_blacs_tgt})
                add_library(${_blacs_tgt} INTERFACE IMPORTED)
                set_target_properties(${_blacs_tgt} PROPERTIES
                    INTERFACE_LINK_LIBRARIES "${_mkl_prefix_libs};${_mkl_blacs_lib};${_mkl_threading_deps};MPI::MPI_CXX")
            endif()

            if(_mkl_scalapack_lib
               AND TARGET ${_blacs_tgt}
               AND NOT TARGET ${_scalapack_tgt})
                add_library(${_scalapack_tgt} INTERFACE IMPORTED)
                set_target_properties(${_scalapack_tgt} PROPERTIES
                    INTERFACE_LINK_LIBRARIES "${_mkl_scalapack_lib};${_blacs_tgt}")
            endif()
      endforeach()
    endforeach()
endforeach()

