/**
 Custom extension to SWIG wrappers
 **/

%{

#include <lualib.h>
#include <pthread.h>

// function for opening the swig library. Defined further down the wrapper code
SWIGEXPORT int SWIG_init(lua_State* L);
// For use inside of a module, this should be defined by OBS_DECLARE_MODULE
extern obs_module_t *obs_current_module(void);

typedef struct {
	char *name;
	char *filename;
} lua_source_meta_t;

typedef struct {
	lua_State *L;
	pthread_mutex_t lock;
} lua_source_data_t;

char *obs_lua_source_get_name(void *type_data) {
	if(type_data)
		return ((lua_source_meta_t*)type_data)->name;
	else
		return NULL;
}

void obs_lua_source_free_type_data(void *type_data) {
	lua_source_meta_t *t = (lua_source_meta_t *)type_data;
	if(t) {
		if(t->filename)
			free(t->filename);
		if(t->name)
			free(t->name);
		free(t);
	}
}

void *obs_lua_source_create(obs_data_t *settings, obs_source_t *source) {
	lua_source_meta_t *type_data = (lua_source_meta_t *)obs_source_get_type_data(source);
	lua_source_data_t *data = (lua_source_data_t *)malloc(sizeof(lua_source_data_t));
	memset(data, 0, sizeof(lua_source_data_t));
	lua_State *L = luaL_newstate();  /* create state */
	luaL_checkversion(L);  /* check that interpreter has correct version */
	luaL_openlibs(L);  /* open standard libraries */
	SWIG_init(L); /* open obs, leaves the module table on the stack */

	pthread_mutexattr_t mutex_attr;

	pthread_mutexattr_init(&mutex_attr);
	// Make this reentrant so calls from lua into C code backed by more lua
	// will not deadlock trying to aquire the lock. Since lua is reentrant
	// but not thread safe this is safe enough.
	pthread_mutexattr_settype(&mutex_attr, PTHREAD_MUTEX_RECURSIVE);
	pthread_mutex_init(&data->lock, &mutex_attr);

	if (luaL_loadfile(L, obs_find_module_file(obs_current_module(), type_data->filename)) != LUA_OK) {
		blog(LOG_ERROR, "[obs-lua]: Failed to load '%s' error: %s", type_data->filename, lua_tostring(L, -1));
		lua_close(L);
		return NULL;
	};
	lua_pcall(L, 0, 1, 0);  // Do file
	lua_setfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");
	lua_pop(L, 1); // Clean source table off stack.

	lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");
	lua_getfield(L, -1, "create");
	lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");
	SWIG_NewPointerObj(L,settings,SWIGTYPE_p_obs_data,0);
	SWIG_NewPointerObj(L,source,SWIGTYPE_p_obs_source,0);
	if(lua_pcall(L, 3, 1, 0) != LUA_OK) {
		blog(LOG_ERROR, "[obs-lua] Failed to call 'create' error: %s", lua_tostring(L, -1));
		lua_close(L);
		return NULL;
	}
	lua_pop(L, 1); // Clean stack

	data->L = L;
	return (void *)data;
}

void obs_lua_source_destroy(void *sdata) {
	lua_source_data_t *data = (lua_source_data_t *)sdata;
	pthread_mutex_lock(&data->lock);
	lua_State *L = data->L;
	if (L) {
		lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");
		lua_getfield(L, -1, "destroy");
		lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");

		if(lua_pcall(L, 1, 0, 0) != LUA_OK) {
			blog(LOG_ERROR, "[obs-lua] Failed to call 'destory' error: %s", lua_tostring(L, -1));
		}
	}
	lua_close(L);
	pthread_mutex_destroy(&data->lock);
}

uint32_t obs_lua_source_get_width(void *sdata) {
	lua_source_data_t *data = (lua_source_data_t *)sdata;
	pthread_mutex_lock(&data->lock);
	lua_State *L = data->L;
	lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");
	lua_getfield(L, -1, "get_width");
	lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");

	if(lua_pcall(L, 1, 1, 0) != LUA_OK) {
		blog(LOG_ERROR, "[obs-lua] Failed to call 'get_width' error: %s", lua_tostring(L, -1));
	}
	lua_Integer width = lua_tointeger(L, -1);
	lua_pop(L, 2); // Clean up stack
	pthread_mutex_unlock(&data->lock);
	return (uint32_t)width;
}

uint32_t obs_lua_source_get_height(void *sdata) {
	lua_source_data_t *data = (lua_source_data_t *)sdata;
	pthread_mutex_lock(&data->lock);
	lua_State *L = data->L;
	lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");
	lua_getfield(L, -1, "get_height");
	lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");

	if( lua_pcall(L, 1, 1, 0) != LUA_OK) {
		blog(LOG_ERROR, "[obs-lua] Failed to call 'get_height' error: %s", lua_tostring(L, -1));
	}
	lua_Integer height = lua_tointeger(L, -1);
	lua_pop(L, 2); //Clean up stack
	pthread_mutex_unlock(&data->lock);
	return (uint32_t)height;
}

void obs_lua_source_video_render(void *sdata, gs_effect_t *effect) {
	lua_source_data_t *data = (lua_source_data_t *)sdata;
	pthread_mutex_lock(&data->lock);
	lua_State *L = data->L;
	lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");
	lua_getfield(L, -1, "video_render");
	lua_getfield(L, LUA_REGISTRYINDEX, "obs_source_lua_data");
	SWIG_NewPointerObj(L,effect,SWIGTYPE_p_gs_effect,0);

	if(lua_pcall(L, 2, 0, 0) != LUA_OK) {
		blog(LOG_ERROR, "[obs-lua] Failed to call 'video_render' error: %s", lua_tostring(L, -1));
	}
	lua_pop(L, 1); //Clean up stack
	pthread_mutex_unlock(&data->lock);
}

int lua_obs_register_source(lua_State *L) {
	int n = lua_gettop(L);
	if(n != 4) {
		lua_pushliteral(L, "Expecting 4 arguments, File, Id/Name, Source type, Output flags");
		lua_error(L);
		return 0;
	}

	struct obs_source_info s = {0};
	lua_source_meta_t *t = (lua_source_meta_t *)malloc(sizeof(lua_source_meta_t));
	memset(t, 0, sizeof(lua_source_meta_t));

	size_t filename_len = -1;
	const char *lua_filename = luaL_checklstring(L, 1, &filename_len); // use obs bstrings
	char *filename = (char *) malloc(sizeof(char)*(filename_len+1));
	memset(filename, 0, sizeof(sizeof(char)*(filename_len+1)));
	memcpy(filename, lua_filename, filename_len);
	filename[filename_len] = 0; // Set terminal byte in case.
	t->filename = filename;

	size_t id_len = -1;
	const char *id_temp = luaL_tolstring(L, 2, &id_len);
	char *id = (char *) malloc(sizeof(char)*(id_len+1));
	memset(id, 0, sizeof(sizeof(char)*(id_len+1)));
	memcpy(id, id_temp, id_len);
	id[id_len] = 0; // Set terminal byte in case.
	s.id = id; // lua get source name,
	t->name = id;
	
	lua_Integer type = lua_tointeger(L, 3);
	s.type = (enum obs_source_type) type; // Do some more validation someone used obs.source_type_x isntead of a random integer.

	lua_Integer output_flags = lua_tointeger(L, 4);
	s.output_flags = output_flags;

	s.get_name = obs_lua_source_get_name;
	s.free_type_data = obs_lua_source_free_type_data;

	s.create = obs_lua_source_create;
	s.destroy = obs_lua_source_destroy;
	s.get_width = obs_lua_source_get_width;
	s.get_height = obs_lua_source_get_height;
	s.video_render = obs_lua_source_video_render;
	// s.get_defaults = obs_lua_source_get_defaults;
	// s.get_properties = obs_lua_source_get_properties;
	// s.update = obs_lua_source_update;
	// s.activate = obs_lua_source_activate;
	// s.deactivate = obs_lua_source_deactivate;
	// s.show = obs_lua_source_show;
	// s.hide = obs_lua_source_hide;
	// s.video_tick = obs_lua_source_video_tick;
	// s.filter_video = obs_lua_source_filter_video;
	// s.filter_audio = obs_lua_source_filter_audio;
	// s.enum_active_sources = obs_lua_source_enum_active_sources;
	// s.enum_all_sources = obs_lua_source_enum_all_sources;
	// s.save = obs_lua_source_save;
	// s.load = obs_lua_source_load;
	// s.filter_remove = obs_lua_source_filter_remove;
	s.type_data = t;

	obs_register_source(&s);

	return 0;
}

	
%}