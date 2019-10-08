#[=======================================================================[.rst:
FindMKL
-------

Example usage
^^^^^^^^^^^^^

  find_package(MKL REQUIRED OPTIONAL_COMPONENTS SCALAPACK)
  target_link_libraries(... MKL::MKL)
  target_link_libraries(... MKL::SCALAPACK)

Note: Targets linking to MKL::SCALAPACK need not link to MKL::MKL. It is NOT 
      an error if both targets are linked though.


Options
^^^^^^^

``MKLROOT``
  Environment variable set to MKL's root directory  

``MKL_ROOT``
  CMake variable set to MKL's root directory  

``MKL_PARALLEL``           
  ON|OFF   (default: ON / parallel)

``MKL_64BIT``
  ON|OFF   (default: OFF / 32bit interface)


Components
^^^^^^^^^^

``SCALAPACK``


Imported targets 
^^^^^^^^^^^^^^^^

``MKL::MKL``

``MKL::SCALAPACK``


Result variables
^^^^^^^^^^^^^^^^

``MKL_FOUND``
  Found MKL.

``MKL_SCALAPACK_FOUND``
  Found ScaLAPACK.

Not supported
^^^^^^^^^^^^^

- TBB threading back-end
- F95 interfaces

Note: Mixing GCC and Intel OpenMP backends is a bad idea.

#]=======================================================================]

# Modules
#
include(FindPackageHandleStandardArgs)

# Functions
#
function(__mkl_find_library _name)
    find_library(${_name}
        NAMES ${ARGN}
        HINTS ${MKL_ROOT}
        PATH_SUFFIXES ${_mkl_libpath_suffix}
                      lib
        )
    mark_as_advanced(${_name})
endfunction()

# Options
#
# The `NOT DEFINED` guards on CACHED variables are needed to make sure that 
# normal variables with of same name always take precedence*.
#
# * There are many caveats with CACHE variables in CMake. Before version 
#   3.12, both the `option()` command and `set(... CACHE ...)` would 
#   override normal variables if cached equivalents don't exist or they 
#   exisit but their type is not specified (e.g. command line arguments: 
#   -DFOO=ON instead of -DFOO:BOOL=ON). For 3.13 with policy CMP0077, 
#   `option()` no longer overrides normal variables of the same name.
#   `set(... CACHE ...)` is still stuck with the old behaviour. 
#
#   https://cmake.org/cmake/help/v3.15/command/set.html#set-cache-entry
#   https://cmake.org/cmake/help/v3.15/policy/CMP0077.html
#
if(NOT DEFINED MKL_ROOT)
    set(MKL_ROOT $ENV{MKLROOT} CACHE PATH "MKL's root directory.")
endif()

if(NOT DEFINED MKL_PARALLEL)
    set(MKL_PARALLEL ON CACHE BOOL "Toggles parallel and sequential versions.")
endif()

if(NOT DEFINED MKL_64BIT)
    set(MKL_64BIT OFF CACHE BOOL "Toggles 32bit/64bit MKL interfaces.")
endif()

# Determine MKL's library folder
#
set(_mkl_libpath_suffix "lib/intel64")
if(CMAKE_SIZEOF_VOID_P EQUAL 4) # 32 bit
    set(_mkl_libpath_suffix "lib/ia32")
endif()

if (WIN32)
    string(APPEND _mkl_libpath_suffix "_win")
elseif (APPLE)
    string(APPEND _mkl_libpath_suffix "_mac")
else ()
    string(APPEND _mkl_libpath_suffix "_lin")
endif ()

# Determine 32bit or 64bit interface is used
#
set(_mkl_lp "lp64")
if(MKL_64BIT)
    set(_mkl_lp "ilp64")
endif()

# Find MKL header
#
find_path(MKL_INCLUDE_DIR mkl.h
    HINTS ${MKL_ROOT}/include
    )
mark_as_advanced(MKL_INCLUDE_DIR)

# Find MKL core libraries
#
__mkl_find_library(MKL_CORE_LIB mkl_core)
__mkl_find_library(MKL_INTERFACE_LIB mkl_intel_${_mkl_lp})

if (MKL_PARALLEL)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND NOT APPLE)
        __mkl_find_library(MKL_THREADING_LIB mkl_gnu_thread)
    else ()
        __mkl_find_library(MKL_THREADING_LIB mkl_intel_thread)
    endif ()
else ()
    __mkl_find_library(MKL_THREADING_LIB mkl_sequential)
endif ()

# Find ScaLAPACK
#
set(MPI_DETERMINE_LIBRARY_VERSION ON)
find_package(MPI)
if (MPI_FOUND)
    __mkl_find_library(MKL_SCALAPACK_LIB mkl_scalapack_${_mkl_lp})

    string(FIND "${MPI_CXX_LIBRARY_VERSION_STRING}" "Open MPI" OMPI_POS)
    if(OMPI_POS STREQUAL "-1")  # MPICH
        if(APPLE)
            __mkl_find_library(MKL_BLACS_LIB mkl_blacs_mpich_${_mkl_lp})
        else()
            __mkl_find_library(MKL_BLACS_LIB mkl_blacs_intelmpi_${_mkl_lp})
        endif()
    else()                      # OpenMPI
        if(APPLE)
            message(FATAL_ERROR "Only MPICH is supported on Apple.")
        endif()
         __mkl_find_library(MKL_BLACS_LIB mkl_blacs_openmpi_${_mkl_lp})
    endif()

    find_package_handle_standard_args(MKL_SCALAPACK REQUIRED_VARS MKL_BLACS_LIB
                                                                  MKL_SCALAPACK_LIB)
endif()

find_package_handle_standard_args(MKL REQUIRED_VARS MKL_CORE_LIB 
                                                    MKL_THREADING_LIB 
                                                    MKL_INTERFACE_LIB 
                                                    MKL_INCLUDE_DIR
                                      HANDLE_COMPONENTS)


# Define the MKL::MKL targets
#
if (MKL_FOUND AND NOT TARGET MKL::MKL)
    find_package(Threads REQUIRED)

    set(_mkl_threading_backend "")
    if(MKL_PARALLEL)
        find_package(OpenMP REQUIRED)
        set(_mkl_threading_backend "OpenMP::OpenMP_CXX")
    endif()

    add_library(MKL::CORE UNKNOWN IMPORTED)
    set_target_properties(MKL::CORE PROPERTIES IMPORTED_LOCATION ${MKL_CORE_LIB})

    add_library(MKL::THREADING UNKNOWN IMPORTED)
    set_target_properties(MKL::THREADING PROPERTIES IMPORTED_LOCATION ${MKL_THREADING_LIB})

    add_library(MKL::BLAS_INTERFACE UNKNOWN IMPORTED)
    set_target_properties(MKL::BLAS_INTERFACE PROPERTIES IMPORTED_LOCATION ${MKL_INTERFACE_LIB})

    add_library(MKL::MKL INTERFACE IMPORTED)
    set_target_properties(MKL::MKL PROPERTIES 
        INTERFACE_INCLUDE_DIRECTORIES "${MKL_INCLUDE_DIR}"
        INTERFACE_LINK_LIBRARIES "MKL::BLAS_INTERFACE;MKL::THREADING;MKL::CORE;${_mkl_threading_backend};Threads::Threads")

    # Define the MKL::SCALAPACK targets
    #
    if (MKL_SCALAPACK_FOUND AND NOT TARGET MKL::SCALAPACK)
        add_library(MKL::BLACS UNKNOWN IMPORTED)
        set_target_properties(MKL::BLACS PROPERTIES IMPORTED_LOCATION ${MKL_BLACS_LIB})

        add_library(MKL::SCALAPACK UNKNOWN IMPORTED)
        set_target_properties(MKL::SCALAPACK PROPERTIES 
          IMPORTED_LOCATION "${MKL_SCALAPACK_LIB}"
          INTERFACE_LINK_LIBRARIES "MKL::BLAS_INTERFACE;MKL::THREADING;MKL::CORE;MKL::BLACS;${_mkl_threading_backend};Threads::Threads"
          )
    endif()
endif()
