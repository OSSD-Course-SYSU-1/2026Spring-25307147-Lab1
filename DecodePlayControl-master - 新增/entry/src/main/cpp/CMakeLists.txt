# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(DecodePlayControl)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
set(CMAKE_CXX_STANDARD 17)

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/player/include
                    ${NATIVERENDER_ROOT_PATH}/common/include
                    ${NATIVERENDER_ROOT_PATH}/capabilities/include
                    ${NATIVERENDER_ROOT_PATH}/render/include)

add_library(player SHARED player/src/PlayerNative.cpp
                          player/src/Player.cpp
                          capabilities/src/CodecCallback.cpp
                          capabilities/src/AudioDecoder.cpp
                          capabilities/src/VideoDecoder.cpp
                          capabilities/src/Demuxer.cpp
                          render/src/XComponentManager.cpp
                          render/src/XComponentRender.cpp)

target_link_libraries(player PUBLIC libace_napi.z.so
                                    libhilog_ndk.z.so
                                    libuv.so
                                    libohaudio.so
                                    libnative_media_codecbase.so
                                    libnative_media_core.so
                                    libnative_media_vdec.so
                                    libnative_media_acodec.so
                                    libnative_media_avdemuxer.so
                                    libnative_media_avsource.so
                                    libnative_window.so
                                    libace_ndk.z.so)