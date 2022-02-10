/*173:*/

#ifndef MPLIBPS_H
#define MPLIBPS_H 1
#include "mplib.h"
/*182:*/

typedef struct{
double a_val,b_val,c_val,d_val;
}mp_color;

/*:182*//*183:*/

typedef struct{
double offset;
double*array;
}mp_dash_object;


/*:183*//*188:*/

#define GRAPHIC_BODY                      \
  int type;                               \
  struct mp_graphic_object * next

typedef struct mp_graphic_object{
GRAPHIC_BODY;
}mp_graphic_object;

typedef struct mp_text_object{
GRAPHIC_BODY;
char*pre_script;
char*post_script;
mp_color color;
unsigned char color_model;
unsigned char size_index;
char*text_p;
size_t text_l;
char*font_name;
double font_dsize;
unsigned int font_n;
double width;
double height;
double depth;
double tx;
double ty;
double txx;
double txy;
double tyx;
double tyy;
}mp_text_object;

typedef struct mp_fill_object{
GRAPHIC_BODY;
char*pre_script;
char*post_script;
mp_color color;
unsigned char color_model;
unsigned char ljoin;
mp_gr_knot path_p;
mp_gr_knot htap_p;
mp_gr_knot pen_p;
double miterlim;
}mp_fill_object;

typedef struct mp_stroked_object{
GRAPHIC_BODY;
char*pre_script;
char*post_script;
mp_color color;
unsigned char color_model;
unsigned char ljoin;
unsigned char lcap;
mp_gr_knot path_p;
mp_gr_knot pen_p;
double miterlim;
mp_dash_object*dash_p;
}mp_stroked_object;

typedef struct mp_clip_object{
GRAPHIC_BODY;
mp_gr_knot path_p;
}mp_clip_object;

typedef struct mp_bounds_object{
GRAPHIC_BODY;
mp_gr_knot path_p;
}mp_bounds_object;

typedef struct mp_special_object{
GRAPHIC_BODY;
char*pre_script;
}mp_special_object;

typedef struct mp_edge_object{
struct mp_graphic_object*body;
struct mp_edge_object*next;
char*filename;
MP parent;
double minx,miny,maxx,maxy;
double width,height,depth,ital_corr;
int charcode;
}mp_edge_object;

/*:188*//*235:*/

int mp_ps_ship_out(mp_edge_object*hh,int prologues,int procset);

/*:235*//*240:*/

void mp_gr_toss_objects(mp_edge_object*hh);
void mp_gr_toss_object(mp_graphic_object*p);

/*:240*//*243:*/

mp_graphic_object*mp_gr_copy_object(MP mp,mp_graphic_object*p);

/*:243*/

#endif


/*:173*/
