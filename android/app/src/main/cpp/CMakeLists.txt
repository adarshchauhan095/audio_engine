cmake_minimum_required(VERSION 3.22)
find_package(oboe REQUIRED CONFIG)

add_library(native_audio SHARED
  ffi/bridge.cpp
  engine/AudioEngine.cpp
  engine/Oscillator.cpp
)

target_include_directories(native_audio PRIVATE engine ffi)
target_link_libraries(native_audio oboe::oboe log)
