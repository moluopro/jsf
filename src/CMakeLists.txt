# Copyright (C) 2025 moluopro. All rights reserved.
# Github: https://github.com/moluopro

cmake_minimum_required(VERSION 3.10)

project(jsf_library VERSION 0.2.1 LANGUAGES C)

file(GLOB SOURCES "*.c")
file(GLOB HEADERS "*.h")

add_library(jsf SHARED
  ${SOURCES}
)

add_definitions(-DCONFIG_BIGNUM -DCONFIG_VERSION=\"2025-04-16\")

set_target_properties(jsf PROPERTIES
  PUBLIC_HEADER ${HEADERS}
  OUTPUT_NAME "jsf"
)

target_compile_definitions(jsf PUBLIC DART_SHARED_LIB)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

target_compile_options(jsf PRIVATE
  -O3
  -march=native
  -flto
  -fno-plt
)

target_link_options(jsf PRIVATE
  -flto
)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(jsf PRIVATE "-Wl,-z,max-page-size=16384")
endif()
