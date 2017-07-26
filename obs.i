%module obs

// Dont blow up on DEPRECATED
#define __attribute__(x) 
// Dont link deprecated functions
%ignore obs_get_default_rect_effect;
%ignore obs_duplicate_encoder_packet;
%ignore obs_free_encoder_packet;

// All register functions must be manually implemented to
// allow for target lang defined types
%ignore obs_register_;

// Cut the obs_ prefix since everything is under the 'obs' module already
%rename("%(regex:/^(?:OBS|obs)_(.*)/\\1/)s") "";

%include <stdint.i>
%include <typemaps.i>
// %include <cstring.i> NOT IMPLEMENTED. >:( 
%include "lua_cstring.i"

%cstring_output_copy(const char **id);
%cstring_output_copy(const char **name);

%cstringlist_return_allocate(char**, bfree)

%{
#include <util/c99defs.h>
#include <util/darray.h>
#include <obs.h>
#include <obs-module.h>
#include <obs-source.h>
#include <obs-encoder.h>
#include <obs-output.h>
#include <obs-service.h>
#include <obs-audio-controls.h>
#include <obs-hotkey.h>
#include <obs-data.h>
#include <obs-frontend-api.h>
#include <util/base.h>
#include <graphics/graphics.h>
#include <graphics/vec4.h>
%}
%include "util/c99defs.h"
%include <util/darray.h>
%include "obs.h"
%include "obs-source.h"
%include "obs-encoder.h"
%include "obs-output.h"
%include "obs-service.h"
%include "obs-audio-controls.h"
%include "obs-hotkey.h"
%include "obs-data.h"
%include "obs-frontend-api.h"
%include <util/base.h>
%include <graphics/graphics.h>
%include <graphics/vec4.h>


%include "obs-lua-extras.i"
%include "obs-source-wrap.i"