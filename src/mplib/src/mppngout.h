/*3:*/

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
/*6:*/

cairo_surface_t*surface;
cairo_t*cr;

/*:6*//*7:*/

integer dx;
integer dy;

/*:7*//*23:*/

mp_edge_object**psfonts;
int font_max;
int last_fnum;

/*:23*/

}pngout_data_struct;
/*4:*/

void mp_png_backend_initialize(MP mp);
void mp_png_backend_free(MP mp);

/*:4*//*30:*/

int mp_png_gr_ship_out(mp_edge_object*hh,const char*options,int standalone);

/*:30*/

#endif

/*:3*/
