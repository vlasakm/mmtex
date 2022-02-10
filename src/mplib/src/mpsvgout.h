/*3:*/

#ifndef MPSVGOUT_H
#define MPSVGOUT_H 1
#include "mplib.h"
#include "mpmp.h"
#include "mplibps.h"
typedef struct svgout_data_struct{
/*6:*/

size_t file_offset;

/*:6*//*12:*/

char*buf;
unsigned loc;
unsigned bufsize;

/*:12*//*20:*/

int level;

/*:20*//*27:*/

integer dx;
integer dy;

/*:27*//*56:*/

int clipid;

/*:56*/

}svgout_data_struct;
/*4:*/

void mp_svg_backend_initialize(MP mp);
void mp_svg_backend_free(MP mp);

/*:4*//*60:*/

int mp_svg_gr_ship_out(mp_edge_object*hh,int prologues,int standalone);

/*:60*/

#endif

/*:3*/
