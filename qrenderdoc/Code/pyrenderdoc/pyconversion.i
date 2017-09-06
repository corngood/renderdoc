// this file is included from renderdoc.i, it's not a module in itself

// typemaps for more sensible fixed-array handling, based on typemaps from SWIG documentation

%define FIXED_ARRAY_TYPEMAPS(BaseType)

%typemap(out) BaseType [ANY] {
  $result = PyList_New($1_dim0);
  for(int i = 0; i < $1_dim0; i++)
  {
    PyObject *o = TypeConversion<BaseType>::ConvertToPy(self, $1[i]);
    if(!o)
    {
      snprintf(convert_error, sizeof(convert_error)-1, "in method '$symname' returning type '$1_basetype', encoding element %d", i);
      SWIG_exception_fail(SWIG_ValueError, convert_error);
    }
    PyList_SetItem($result,i,o);
  }
}

%typemap(arginit) BaseType [ANY] {
   $1 = NULL;
}

%typemap(in) BaseType [ANY] {
  if(!PySequence_Check($input))
  {
    SWIG_exception_fail(SWIG_TypeError, "in method '$symname' argument $argnum of type '$1_basetype'. Expected sequence"); 
  }
  if(PySequence_Length($input) != $1_dim0) {
    SWIG_exception_fail(SWIG_ValueError, "in method '$symname' argument $argnum of type '$1_basetype'. Expected $1_dim0 elements"); 
  }
  $1 = new BaseType[$1_dim0];
  for(int i = 0; i < $1_dim0; i++) {
    PyObject *o = PySequence_GetItem($input,i);

    int res = TypeConversion<BaseType>::ConvertFromPy(o, $1[i]);

    if(!SWIG_IsOK(res))
    {
      snprintf(convert_error, sizeof(convert_error)-1, "in method '$symname' argument $argnum of type '$1_basetype', decoding element %d", i);
      SWIG_exception_fail(SWIG_ArgError(res), convert_error);
    }
  }
}

%typemap(freearg) BaseType [ANY] {
   delete[] $1;
}

%enddef

%define SIMPLE_TYPEMAPS_VARIANT(BaseType, SimpleType)
%typemap(in, fragment="pyconvert") SimpleType (BaseType temp) {
  tempset($1, &temp);

  int res = ConvertFromPy($input, indirect($1));
  if(!SWIG_IsOK(res))
  {
    SWIG_exception_fail(SWIG_ArgError(res), "in method '$symname' argument $argnum of type '$1_basetype'"); 
  }
}

%typemap(out, fragment="pyconvert") SimpleType {
  $result = ConvertToPy(self, indirect($1));
}
%enddef

%define SIMPLE_TYPEMAPS(SimpleType)

SIMPLE_TYPEMAPS_VARIANT(SimpleType, SimpleType)
SIMPLE_TYPEMAPS_VARIANT(SimpleType, SimpleType *)
SIMPLE_TYPEMAPS_VARIANT(SimpleType, SimpleType &)

%enddef

%define CONTAINER_TYPEMAPS_VARIANT(ContainerType)

%typemap(in, fragment="pyconvert") ContainerType (unsigned char tempmem[32]) {
  static_assert(sizeof(tempmem) >= sizeof(std::remove_pointer<decltype($1)>::type), "not enough temp space for $1_basetype");
  
  tempalloc($1, tempmem);

  int failIdx = 0;
  int res = TypeConversion<std::remove_pointer<decltype($1)>::type>::ConvertFromPy($input, indirect($1), &failIdx);

  if(!SWIG_IsOK(res))
  {
    if(res == SWIG_TypeError)
    {
      SWIG_exception_fail(SWIG_ArgError(res), "in method '$symname' argument $argnum of type '$1_basetype'"); 
    }
    else
    {
      snprintf(convert_error, sizeof(convert_error)-1, "in method '$symname' argument $argnum of type '$1_basetype', decoding element %d", failIdx);
      SWIG_exception_fail(SWIG_ArgError(res), convert_error);
    }
  }
}

%typemap(freearg, fragment="pyconvert") ContainerType {
  tempdealloc($1);
}

%typemap(out, fragment="pyconvert") ContainerType {
  int failIdx = 0;
  $result = TypeConversion<std::remove_pointer<$1_basetype>::type>::ConvertToPy(self, indirect($1), &failIdx);
  if(!$result)
  {
    snprintf(convert_error, sizeof(convert_error)-1, "in method '$symname' returning type '$1_basetype', encoding element %d", failIdx);
    SWIG_exception_fail(SWIG_ValueError, convert_error);
  }
}

%enddef

%define CONTAINER_TYPEMAPS(ContainerType)

CONTAINER_TYPEMAPS_VARIANT(ContainerType)
CONTAINER_TYPEMAPS_VARIANT(ContainerType *)
CONTAINER_TYPEMAPS_VARIANT(ContainerType &)

%enddef