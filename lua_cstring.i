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

/*
 * %cstring_output_allocate(TYPEMAP, FREEFUN)
 *
 * This macro is used to return char* array data that was
 * allocated with (bz)malloc.
 *
 *     }
 */
 
%define %cstringlist_return_allocate(TYPEMAP, FREEFUN)           
%typemap(out,noblock=1) TYPEMAP($1_ltype temp = 0) ""
%typemap(ret,noblock=1) TYPEMAP { 
  if ($1) {
  	lua_createtable(L, 10, 0); SWIG_arg++;
  	$1_ltype curr = $1; lua_Integer i = 0;
  	while(*curr != NULL) {
  		lua_pushstring(L, *curr);
  		lua_seti(L, -2, i);
  		curr += 1; i += 1;
  	}
    FREEFUN($1);					  	     
  }					  	     
}							     
%enddef