cmake_minimum_required(VERSION 3.4)
project(obs-lua)

find_package(SWIG REQUIRED 3.0)
include(${SWIG_USE_FILE})

set(Qt5Widgets_DIR "C:/Qt/Qt5.7.0/5.7/msvc2015_64/lib/cmake/Qt5Widgets")
# find_package(Qt5Core)
# find_package(Qt5Gui)
find_package(Qt5Widgets)

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(GUI_FILES
	lua-console.hpp
	lua-console.cpp)
qt5_wrap_ui(QT_UI_HEADERS forms/lua-console.ui)

# for building seperate from obs
include_directories(../../libobs/)
include_directories(../../UI/obs-frontend-api/)
include_directories(../../deps/w32-pthreads/)
link_directories(../../deps/w32-pthreads/lib)
link_directories(../../build/libobs)
link_directories(../../build/UI/obs-frontend-api)

set(SWIG_MODULE_obs-lua-wrap_EXTRA_DEPS obs-lua-extras.i lua_cstring.i obs-source-wrap.i)
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

add_library(obs-lua SHARED obs-lua.c lua-console.cpp ${SWIG_RUNTIME_HEADER} ${QT_UI_HEADERS})
target_compile_features(obs-lua PRIVATE cxx_lambdas)
target_link_libraries(obs-lua obs obs-frontend-api obs-lua-wrap lua53 w32-pthreads Qt5::Widgets)

# Old test code
# add_executable(obs-lua-console old/lua.c )
# target_link_libraries(obs-lua-console obs libobs-lua lua53 w32-pthreads)

# install_obs_plugin_with_data(obs-lua scripts)
