
#ifndef MPMATHINTERVAL_H
#define  MPMATHINTERVAL_H 1
#include "mplib.h"
#include "mpmp.h" 
#include <gmp.h> 
#include <mpfr.h> 
#include <mpfi.h> 
#include <mpfi_io.h> 

#ifdef HAVE_CONFIG_H
#define MP_STR_HELPER(x) #x
#define MP_STR(x) MP_STR_HELPER(x)



#endif

const char*COMPILED_MPFI_VERSION_STRING= MPFI_VERSION_STRING;





void*mp_initialize_interval_math(MP mp);

;
#endif

