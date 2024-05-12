
#ifndef MPSVGOUT_H
#define MPSVGOUT_H 1
#include "mplib.h"
#include "mpmp.h"
#include "mplibps.h"
typedef struct svgout_data_struct{

size_t file_offset;


char*buf;
unsigned loc;
unsigned bufsize;


int level;


double dx;
double dy;



int clipid;


}svgout_data_struct;

void mp_svg_backend_initialize(MP mp);
void mp_svg_backend_free(MP mp);


int mp_svg_gr_ship_out(mp_edge_object*hh,int prologues,int standalone);


#endif

