# Specifies the minimum version of CMake required to build this project.
cmake_minimum_required(VERSION 3.22)

# Finds the Oboe library, which is a C++ library for building high-performance
# audio applications on Android. 'REQUIRED' means CMake will abort if Oboe is not found.
find_package(oboe REQUIRED CONFIG)

# Adds a shared library target named 'native_audio'.
# This library will be linked against the main application and will expose
# functions to the Dart/Flutter side via FFI (Foreign Function Interface).
# The source files for this library are listed below.
add_library(native_audio SHARED
  ffi/bridge.cpp          # C++ code for bridging Dart FFI calls to native audio logic.
  engine/AudioEngine.cpp  # Implements the core audio engine functionality.
  engine/EventScheduler.cpp # Stores timed parameter events (passive scaffold for now).
  engine/ParameterSmoother.cpp # Smooth parameter transitions to prevent clicks.
  engine/Oscillator.cpp   # Implements the audio oscillator for generating tones.
  engine/VoiceManager.cpp # Voice container for optional multi-oscillator rendering.
  engine/TherapyRouter.cpp
        engine/advance_engine/AdvanceEngineRouter.cpp
  engine/modules/SubthresholdModule.cpp
  engine/modules/RMPModule.cpp
  engine/modules/PIPModule.cpp
  engine/modules/SidebandModule.cpp
  engine/modules/BinauralModule.cpp
)

# Specifies private include directories for the 'native_audio' library.
# These directories contain header files needed by the source files of 'native_audio'.
target_include_directories(native_audio PRIVATE engine ffi)

# Links the 'native_audio' library with other necessary libraries.
# 'oboe::oboe' is the Oboe audio library.
# 'log' is the Android logging library (used for debugging output).
target_link_libraries(native_audio oboe::oboe log)
