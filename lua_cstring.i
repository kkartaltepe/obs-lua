%define %cstring_output_copy(TYPEMAP)
%typemap(in,noblock=1,numinputs=0) TYPEMAP($*1_ltype temp = NULL) {
    $1 = &temp;
}
%typemap(argout,noblock=1) TYPEMAP { 
    if ($1 && *$1) {
        lua_pushstring(L, *$1); SWIG_arg++;
    }
}
%enddef