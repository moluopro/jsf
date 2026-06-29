cmake_minimum_required(VERSION 3.10)

project(jsf_library VERSION 1.0.1 LANGUAGES C)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

set(JSF_SRC_DIR "${CMAKE_CURRENT_LIST_DIR}")
set(QUICKJS_DIR "${JSF_SRC_DIR}/quickjs")

file(READ "${QUICKJS_DIR}/VERSION" QUICKJS_VERSION)
string(STRIP "${QUICKJS_VERSION}" QUICKJS_VERSION)

set(QUICKJS_SOURCES
  "${QUICKJS_DIR}/quickjs.c"
  "${QUICKJS_DIR}/libregexp.c"
  "${QUICKJS_DIR}/libunicode.c"
  "${QUICKJS_DIR}/cutils.c"
  "${QUICKJS_DIR}/dtoa.c"
)

set(JSF_RELEASE_C_FLAGS)
set(JSF_RELEASE_LINK_FLAGS)
set(JSF_IS_DESKTOP_BUILD OFF)

if(WIN32
    OR CMAKE_SYSTEM_NAME STREQUAL "Darwin"
    OR CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(JSF_IS_DESKTOP_BUILD ON)
endif()

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  list(APPEND JSF_RELEASE_C_FLAGS -O3 -flto=auto -fomit-frame-pointer)
  list(APPEND JSF_RELEASE_LINK_FLAGS -flto=auto)
elseif(CMAKE_C_COMPILER_ID MATCHES "Clang|AppleClang")
  list(APPEND JSF_RELEASE_C_FLAGS -O3 -flto -fomit-frame-pointer)
  list(APPEND JSF_RELEASE_LINK_FLAGS -flto)
endif()

if(JSF_IS_DESKTOP_BUILD AND CMAKE_C_COMPILER_ID STREQUAL "AppleClang")
  list(APPEND JSF_RELEASE_C_FLAGS -mcpu=native)
elseif(JSF_IS_DESKTOP_BUILD AND CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  list(APPEND JSF_RELEASE_C_FLAGS -march=native)
endif()

if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang|AppleClang"
    AND (UNIX OR ANDROID)
    AND NOT APPLE
    AND NOT CMAKE_SYSTEM_NAME STREQUAL "OHOS")
  list(APPEND JSF_RELEASE_C_FLAGS -fno-plt)
endif()

if(MSVC)
  list(APPEND JSF_RELEASE_C_FLAGS /O2 /GL)
  list(APPEND JSF_RELEASE_LINK_FLAGS /LTCG)
endif()

if(WIN32 AND CMAKE_C_COMPILER_ID STREQUAL "GNU")
  list(APPEND JSF_RELEASE_LINK_FLAGS
    -static-libgcc
    -Wl,--export-all-symbols
  )
endif()

foreach(config RELEASE RELWITHDEBINFO MINSIZEREL)
  foreach(flag IN LISTS JSF_RELEASE_C_FLAGS)
    string(APPEND CMAKE_C_FLAGS_${config} " ${flag}")
  endforeach()

  foreach(flag IN LISTS JSF_RELEASE_LINK_FLAGS)
    string(APPEND CMAKE_SHARED_LINKER_FLAGS_${config} " ${flag}")
  endforeach()
endforeach()

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  find_program(JSF_GCC_AR NAMES gcc-ar)
  find_program(JSF_GCC_RANLIB NAMES gcc-ranlib)

  if(JSF_GCC_AR)
    set(CMAKE_AR "${JSF_GCC_AR}" CACHE FILEPATH "GNU LTO archiver" FORCE)
  endif()

  if(JSF_GCC_RANLIB)
    set(CMAKE_RANLIB "${JSF_GCC_RANLIB}" CACHE FILEPATH "GNU LTO ranlib" FORCE)
  endif()
endif()

add_library(quickjs OBJECT ${QUICKJS_SOURCES})
set_target_properties(quickjs PROPERTIES
  C_STANDARD 11
  C_STANDARD_REQUIRED YES
  POSITION_INDEPENDENT_CODE ON
)

target_include_directories(quickjs PUBLIC "${QUICKJS_DIR}")
target_compile_definitions(quickjs PRIVATE CONFIG_VERSION="${QUICKJS_VERSION}")

if(NOT MSVC)
  target_compile_definitions(quickjs PRIVATE _GNU_SOURCE)
  target_compile_options(quickjs PRIVATE -fwrapv)
endif()

add_library(jsf SHARED
  "${JSF_SRC_DIR}/jsf.c"
  $<TARGET_OBJECTS:quickjs>
)

set_target_properties(jsf PROPERTIES
  C_STANDARD 11
  C_STANDARD_REQUIRED YES
  PUBLIC_HEADER "${JSF_SRC_DIR}/jsf.h"
  OUTPUT_NAME "jsf"
  WINDOWS_EXPORT_ALL_SYMBOLS ON
)

if(WIN32)
  set_target_properties(jsf PROPERTIES PREFIX "")
endif()

target_include_directories(jsf PUBLIC
  "${JSF_SRC_DIR}"
  "${QUICKJS_DIR}"
)

target_compile_definitions(jsf PUBLIC
  DART_SHARED_LIB
)

if(NOT WIN32)
  target_compile_options(jsf PRIVATE -fvisibility=hidden)
endif()

if(UNIX OR ANDROID)
  target_link_libraries(jsf PRIVATE m)
endif()

if(ANDROID)
  # Support Android 15 16k page size
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.13")
    target_link_options(jsf PRIVATE "-Wl,-z,max-page-size=16384")
  else()
    set_property(TARGET jsf APPEND_STRING PROPERTY
      LINK_FLAGS " -Wl,-z,max-page-size=16384"
    )
  endif()
endif()
