
#ifndef MPPNGOUT_H
#define MPPNGOUT_H 1
#include "cairo.h"
const char*COMPILED_CAIRO_VERSION_STRING= CAIRO_VERSION_STRING;
#include "pixman.h"
const char*COMPILED_PIXMAN_VERSION_STRING= PIXMAN_VERSION_STRING;
#define PNG_SKIP_SETJMP_CHECK 1
#include "png.h"
#include "mplib.h"
#include "mpmp.h"
#include "mplibps.h"
typedef struct pngout_data_struct{

cairo_surface_t*surface;
cairo_t*cr;


integer dx;
integer dy;


mp_edge_object**psfonts;
int font_max;
int last_fnum;


}pngout_data_struct;

void mp_png_backend_initialize(MP mp);
void mp_png_backend_free(MP mp);


int mp_png_gr_ship_out(mp_edge_object*hh,const char*options,int standalone);


#endif

