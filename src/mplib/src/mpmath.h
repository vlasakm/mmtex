
#ifndef MPMATH_H
#define MPMATH_H 1
#include "mplib.h"
#include "mpmp.h" 

void*mp_initialize_scaled_math(MP mp);
void mp_set_number_from_double(mp_number*A,double B);
void mp_pyth_add(MP mp,mp_number*r,mp_number a,mp_number b);
double mp_number_to_double(mp_number A);



integer mp_take_fraction(MP mp,integer q,int f);



int mp_make_scaled(MP mp,integer p,integer q);

;
#endif

