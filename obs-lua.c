#include <obs-module.h>

#include "swig-lua-runtime.h"
#include <lualib.h>

// // Wrapper functions
extern int luaopen_obs(lua_State *L); 
extern int lua_obs_register_source(lua_State *L);
extern void InitLuaConsole();

#define INIT_LUA_FILE "exec.lua"

OBS_DECLARE_MODULE();

MODULE_EXPORT bool obs_module_load(void) {
	lua_State *L = luaL_newstate();  /* create state */
	luaL_checkversion(L);  /* check that interpreter has correct version */
	luaL_openlibs(L);  /* open standard libraries */
	luaopen_obs(L); /* open obs */
	SWIG_Lua_add_function(L,"register_source", lua_obs_register_source); // After opening obs the obs module is still on the stack.
	lua_pop(L, lua_gettop(L)); // clean the stack

	if(luaL_loadfile(L, obs_find_module_file(obs_current_module(), INIT_LUA_FILE)) != LUA_OK) {
		blog(LOG_ERROR, "[obs-lua]: Failed to load init script '%s'\n", INIT_LUA_FILE);
		return false;
	}
	if (lua_pcall(L, 0, 0, 0) != LUA_OK) {
    	blog(LOG_INFO, "[obs-lua]: error in '" INIT_LUA_FILE "':\n (%s)", lua_tostring(L, -1));
    	lua_pop(L, 2);
    }
	InitLuaConsole(L);
	return true;
}

