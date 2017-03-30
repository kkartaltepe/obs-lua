t = {w = 128, h = 128}

function t:create(settings, source)
	obs.blog(obs.LOG_INFO, "[obs-lua:lua]: Wow we called into lua from lua")
	-- obs.blog(obs.LOG_INFO, string.format("[obs-lua:lua] returning lua height %s", self.h))
end

function t:destroy()
	obs.blog(obs.LOG_INFO, "[obs-lua:lua]: Bye Bye~")
end

function t:get_width()
	return self.w
end

function t:get_height()
	return self.h
end

function t:video_render(effect)
	solid = obs.get_base_effect(obs.EFFECT_SOLID)
	color = obs.gs_effect_get_param_by_name(solid, "color")
	tech  = obs.gs_effect_get_technique(solid, "Solid")

	colorVal = obs.vec4()
	obs.vec4_set(colorVal, 0.5, 0.5, 0.5, 0.5)
	obs.gs_effect_set_vec4(color, colorVal);

	obs.gs_technique_begin(tech);
	obs.gs_technique_begin_pass(tech, 0);

	obs.gs_draw_sprite(nil, 0, self.w, self.h);

	obs.gs_technique_end_pass(tech);
	obs.gs_technique_end(tech);
end

return t