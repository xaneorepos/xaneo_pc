cmake_minimum_required(VERSION 3.14)
project(xaneo_pc LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Linux macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "_FILE_OFFSET_BITS=64")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_custom_target(flutter_assemble
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL} --quiet assemble
  DEPENDS ${FLUTTER_LIBRARY}
  WORKING_DIRECTORY ${PROJECT_DIR}
  COMMENT "Assembling Flutter assets"
  VERBATIM
)
add_dependencies(${BINARY_NAME} flutter_assemble)

# Wrapper script for the Linux executable.
# It sets the environment and runs the binary.
configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/../../wrapper.sh"
  "${CMAKE_BINARY_DIR}/wrapper"
  USE_SOURCE_PERMISSIONS
)