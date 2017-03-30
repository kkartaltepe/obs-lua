// Extra ease of use functions for the lua wrapper.

%define %list_from_enum($ENUM)
%luacode {
function obs.$ENUM()
	ok = false
	i = 0
	ret = {}
	repeat
		ok,source = obs.enum_ ## $ENUM ## (i)
		ret[i] = source
		i = i + 1
	until ok == false
	return ret
end	
}
%enddef

%luacode {
	function obs.semantic_version()
		v = math.floor(obs.get_version())
		return (v >> 24 & 0xFF), (v >> 16 & 0xFF), v & 0xFFFF
	end
}
%list_from_enum(source_types)
%list_from_enum(input_types)
%list_from_enum(filter_types)
%list_from_enum(transition_types)
%list_from_enum(output_types)
%list_from_enum(encoder_types)
%list_from_enum(service_types)