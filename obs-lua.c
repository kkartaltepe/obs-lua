#include <obs-module.h>

#include "swig-lua-runtime.h"
#include <lualib.h>

// // Wrapper functions
extern int luaopen_obs(lua_State *L); 
extern int lua_obs_register_source(lua_State *L);

#define INIT_LUA_FILE "exec.lua"

OBS_DECLARE_MODULE();

MODULE_EXPORT bool obs_module_load(void) {
	lua_State *L = luaL_newstate();  /* create state */
	luaL_checkversion(L);  /* check that interpreter has correct version */
	luaL_openlibs(L);  /* open standard libraries */
	luaopen_obs(L); /* open obs */
	SWIG_Lua_add_function(L,"register_source", lua_obs_register_source); // After opening obs the obs module is still on the stack.

	if(luaL_loadfile(L, obs_find_module_file(obs_current_module(), INIT_LUA_FILE)) != LUA_OK) {
		blog(LOG_ERROR, "[obs-lua]: Failed to execute init script '%s'\n", INIT_LUA_FILE);
		return false;
	}
	lua_pcall(L, 0, 0, 0);
	return true;
}

