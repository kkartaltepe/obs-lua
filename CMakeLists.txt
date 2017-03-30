cmake_minimum_required(VERSION 3.4)
project(obs-lua)

find_package(SWIG REQUIRED 3.0)
include(${SWIG_USE_FILE})

# for building seperate from obs
include_directories(../../libobs/)
include_directories(../../deps/w32-pthreads/)
link_directories(../../deps/w32-pthreads/lib)

set(SWIG_MODULE_obs-lua-wrap_EXTRA_DEPS lua_extensions.i lua_cstring.i obs-source-wrap.i)
swig_add_library(obs-lua-wrap
	TYPE USE_BUILD_SHARED_LIBS
	LANGUAGE lua
	SOURCES obs.i)
set(SWIG_RUNTIME_HEADER swig-lua-runtime.h)
add_custom_command(
    OUTPUT ${SWIG_RUNTIME_HEADER}
    COMMAND "${SWIG_EXECUTABLE}" -lua -external-runtime "${SWIG_RUNTIME_HEADER}"
    MAIN_DEPENDENCY obs.i
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
)

add_library(obs-lua SHARED obs-lua.c ${SWIG_RUNTIME_HEADER})
target_link_libraries(obs-lua obs obs-lua-wrap lua53 w32-pthreads)

# Old test code
# add_executable(obs-lua-console old/lua.c )
# target_link_libraries(obs-lua-console obs libobs-lua lua53 w32-pthreads)

# install_obs_plugin_with_data(obs-lua scripts)
