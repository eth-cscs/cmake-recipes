#
# CMake recipes
# https://github.com/eth-cscs/cmake-recipes
#
# Copyright (c) 2018-2019, ETH Zurich
# BSD 3-Clause License. All rights reserved.
#
#[=======================================================================[.rst:
get_nlohmann_json
-----------------

Usage
^^^^^

``get_nlohmann_json(some_version)``

e.g. 


``get_nlohmann_json(3.7.3)``

Behavior
^^^^^^^^

Tries to find_package(nlohmann_json), if this fails,
we will download the single header version and will provide
the target nlohmann_json::nlohmann_json.

#]=======================================================================]

function(get_nlohmann_json nlohmann_json_version)
    if(NOT _nlohmann_json_already_fetched)
        find_package(nlohmann_json ${nlohmann_json_version} QUIET)
    endif()
    if(NOT nlohmann_json_FOUND)
        set(_dst_json_dir ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY})
        set(_dst_json_file ${_dst_json_dir}/nlohmann/json.hpp)
        if(NOT EXISTS ${_dst_json_file})
            file(DOWNLOAD
                https://github.com/nlohmann/json/releases/download/v${nlohmann_json_version}/json.hpp
                ${_dst_json_file}
                STATUS _json_download_status
            )
            list(GET _json_download_status 0 _json_download_status_code)
            if(_json_download_status_code EQUAL 0)
                message(STATUS "Successfully downloaded nlohmann_json (version ${nlohmann_json_version})")
            else()
                list(GET _json_download_status 1 _json_download_status_message)
                message(WARNING "Couldn't fetch JSON for Modern C++. ${_json_download_status_message}")
                file(REMOVE ${_dst_json_file})
            endif()
        endif()
        if(EXISTS ${_dst_json_file})
            add_library(nlohmann_json INTERFACE)
            target_include_directories(nlohmann_json INTERFACE ${_dst_json_dir})
            set(_nlohmann_json_already_fetched ON CACHE INTERNAL "")
            add_library(nlohmann_json::nlohmann_json ALIAS nlohmann_json)
        endif()
    endif()
endfunction()
