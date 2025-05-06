# Copyright (C) 2025 moluopro. All rights reserved.
# Github: https://github.com/moluopro

cmake_minimum_required(VERSION 3.10)

project(jsf_library VERSION 0.6.1 LANGUAGES C)

file(GLOB SOURCES "*.c")
file(GLOB HEADERS "*.h")

add_library(jsf SHARED
  ${SOURCES}
)

add_definitions(-DCONFIG_BIGNUM)

set_target_properties(jsf PROPERTIES
  PUBLIC_HEADER ${HEADERS}
  OUTPUT_NAME "jsf"
)

target_compile_definitions(jsf PUBLIC DART_SHARED_LIB)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(COMMON_COMPILE_OPTIONS
    -O3
    -flto
    -fno-plt
    -fomit-frame-pointer
)

if(NOT ANDROID)
    list(APPEND COMMON_COMPILE_OPTIONS -march=native)
endif()

target_compile_options(jsf PRIVATE ${COMMON_COMPILE_OPTIONS})

target_link_options(jsf PRIVATE
  -flto
)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(jsf PRIVATE "-Wl,-z,max-page-size=16384")
endif()
