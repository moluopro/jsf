# Copyright (C) 2025 moluopro. All rights reserved.
# Github: https://github.com/moluopro

# Flutter Windows plugins are configured through CMake. JSF ships a
# prebuilt Windows DLL so users do not need a local C compiler.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "jsf")
project(${PROJECT_NAME} LANGUAGES NONE)

set(JSF_PREBUILT_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/jsf.dll")

if(NOT EXISTS "${JSF_PREBUILT_LIBRARY}")
  message(FATAL_ERROR
    "Missing windows/jsf.dll. Reinstall the package or restore the prebuilt "
    "Windows library."
  )
endif()

set(jsf_bundled_libraries
  "${JSF_PREBUILT_LIBRARY}"
)

if(NOT CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  set(jsf_bundled_libraries
    ${jsf_bundled_libraries}
    PARENT_SCOPE
  )
endif()
