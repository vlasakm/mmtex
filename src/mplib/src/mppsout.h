
#ifndef MPPSOUT_H
#define MPPSOUT_H 1
#include "avl.h"
#include "mplib.h"
#include "mpmp.h"
#include "mplibps.h"

typedef struct{
boolean loaded;
char*file_name;
char*enc_name;
integer objnum;
char**glyph_names;
integer tounicode;
}enc_entry;



enum _mode{FM_DUPIGNORE,FM_REPLACE,FM_DELETE};
enum _ltype{MAPFILE,MAPLINE};
enum _tfmavail{TFM_UNCHECKED,TFM_FOUND,TFM_NOTFOUND};
typedef struct mitem{
int mode;
int type;
char*map_line;
int lineno;
}mapitem;


typedef char char_entry;
#ifndef ZCONF_H
typedef unsigned char Byte;
typedef Byte Bytef;
#endif


typedef unsigned char byte;
typedef struct{
byte nargs;
boolean bottom;
boolean clear;
boolean valid;
}cc_entry;
typedef struct{
char*glyph_name;
byte*data;
unsigned short len;
unsigned short cslen;
boolean is_used;
boolean valid;
}cs_entry;


typedef char t1_line_entry;
typedef char t1_buf_entry;


typedef struct{
const char*pdfname;
const char*t1name;
float value;
boolean valid;
}key_entry;


typedef struct{
char*ff_name;
char*ff_path;
}ff_entry;


typedef struct mp_ps_font{
int font_num;
char**t1_glyph_names;
cs_entry*cs_tab;
cs_entry*cs_ptr;
cs_entry*subr_tab;
int subr_size;
int t1_lenIV;
int slant;
int extend;

double flex_hint_data[14];
unsigned int flex_hint_index;
boolean ignore_flex_hint;
double cur_x,cur_y;
double orig_x,orig_y;
mp_edge_object*h;
mp_graphic_object*p;
mp_gr_knot pp;



}mp_ps_font;


typedef struct{
char*tfm_name;
char*ps_name;
integer flags;
char*ff_name;
char*subset_tag;
enc_entry*encoding;
unsigned int tfm_num;
unsigned short type;
short slant;
short extend;
integer ff_objnum;
integer fn_objnum;
integer fd_objnum;
char*charset;
boolean all_glyphs;
unsigned short links;
short tfm_avail;
short pid;
short eid;
}fm_entry;



enum mp_char_mark_state{mp_unused= 0,mp_used};


#define gr_left_type(A)  (A)->data.types.left_type
#define gr_right_type(A) (A)->data.types.right_type
#define gr_x_coord(A)    (A)->x_coord
#define gr_y_coord(A)    (A)->y_coord
#define gr_left_x(A)     (A)->left_x
#define gr_left_y(A)     (A)->left_y
#define gr_right_x(A)    (A)->right_x
#define gr_right_y(A)    (A)->right_y
#define gr_next_knot(A)  (A)->next
#define gr_originator(A) (A)->originator


#define gr_type(A)         (A)->type
#define gr_link(A)         (A)->next
#define gr_color_model(A)  (A)->color_model
#define gr_red_val(A)      (A)->color.a_val
#define gr_green_val(A)    (A)->color.b_val
#define gr_blue_val(A)     (A)->color.c_val
#define gr_cyan_val(A)     (A)->color.a_val
#define gr_magenta_val(A)  (A)->color.b_val
#define gr_yellow_val(A)   (A)->color.c_val
#define gr_black_val(A)    (A)->color.d_val
#define gr_grey_val(A)     (A)->color.a_val
#define gr_path_p(A)       (A)->path_p
#define gr_htap_p(A)       ((mp_fill_object *)A)->htap_p
#define gr_pen_p(A)        (A)->pen_p
#define gr_ljoin_val(A)    (A)->ljoin
#define gr_lcap_val(A)     ((mp_stroked_object *)A)->lcap
#define gr_miterlim_val(A) (A)->miterlim
#define gr_pre_script(A)   (A)->pre_script
#define gr_post_script(A)  (A)->post_script
#define gr_dash_p(A)       ((mp_stroked_object *)A)->dash_p
#define gr_size_index(A)    ((mp_text_object *)A)->size_index
#define gr_text_p(A)       ((mp_text_object *)A)->text_p
#define gr_text_l(A)       ((mp_text_object *)A)->text_l
#define gr_font_n(A)       ((mp_text_object *)A)->font_n
#define gr_font_name(A)    ((mp_text_object *)A)->font_name
#define gr_font_dsize(A)   ((mp_text_object *)A)->font_dsize
#define gr_width_val(A)    ((mp_text_object *)A)->width
#define gr_height_val(A)   ((mp_text_object *)A)->height
#define gr_depth_val(A)    ((mp_text_object *)A)->depth
#define gr_tx_val(A)       ((mp_text_object *)A)->tx
#define gr_ty_val(A)       ((mp_text_object *)A)->ty
#define gr_txx_val(A)      ((mp_text_object *)A)->txx
#define gr_txy_val(A)      ((mp_text_object *)A)->txy
#define gr_tyx_val(A)      ((mp_text_object *)A)->tyx
#define gr_tyy_val(A)      ((mp_text_object *)A)->tyy


typedef struct _gs_state{
double red_field;
double green_field;
double blue_field;
double black_field;

quarterword colormodel_field;

quarterword ljoin_field;
quarterword lcap_field;

quarterword adj_wx_field;

double miterlim_field;

mp_dash_object*dash_p_field;

boolean dash_done_field;
struct _gs_state*previous_field;

double width_field;

}_gs_state;



typedef struct mp_font_size_node_data{
NODE_BODY;
double sc_factor_;
}mp_font_size_node_data;
typedef struct mp_font_size_node_data*mp_font_size_node;



typedef struct psout_data_struct{

integer ps_offset;



#define ENC_BUF_SIZE  0x1000
char enc_line[ENC_BUF_SIZE];
void*enc_file;


avl_tree enc_tree;


void*fm_file;
size_t fm_byte_waiting;
size_t fm_byte_length;
unsigned char*fm_bytes;


mapitem*mitem;
fm_entry*fm_cur;
fm_entry*loaded_tfm_found;
fm_entry*avail_tfm_found;
fm_entry*non_tfm_found;
fm_entry*not_avail_tfm_found;


avl_tree tfm_tree;
avl_tree ps_tree;
avl_tree ff_tree;


char_entry*char_ptr,*char_array;
size_t char_limit;
char*job_id_string;


#define PRINTF_BUF_SIZE     1024
char*dvips_extra_charset;
char*cur_enc_name;
unsigned char*grid;
char*ext_glyph_names[256];
char print_buf[PRINTF_BUF_SIZE];
size_t t1_byte_waiting;
size_t t1_byte_length;
unsigned char*t1_bytes;


char**t1_glyph_names;
char*t1_builtin_glyph_names[256];
char charsetstr[0x4000];
boolean read_encoding_only;
int t1_encoding;


unsigned short t1_dr,t1_er;
unsigned short t1_cslen;
short t1_lenIV;


t1_line_entry*t1_line_ptr,*t1_line_array;
size_t t1_line_limit;
t1_buf_entry*t1_buf_ptr,*t1_buf_array;
size_t t1_buf_limit;
int cs_start;
cs_entry*cs_tab,*cs_ptr,*cs_notdef;
char*cs_dict_start,*cs_dict_end;
int cs_count,cs_size,cs_size_pos;
cs_entry*subr_tab;
char*subr_array_start,*subr_array_end;
int subr_max,subr_size,subr_size_pos;


const char**cs_token_pair;
boolean t1_pfa,t1_cs,t1_scan,t1_eexec_encrypt,t1_synthetic;
int t1_in_eexec;
int t1_block_length;
int last_hexbyte;
void*t1_file;
int hexline_length;


#define FONTNAME_BUF_SIZE 128
boolean fontfile_found;
boolean is_otf_font;
char fontname_buf[FONTNAME_BUF_SIZE];


struct _gs_state*gs_state;


}psout_data_struct;

void mp_ps_backend_initialize(MP mp);
void mp_ps_backend_free(MP mp);


fm_entry*mp_fm_lookup(MP mp,font_number f);


void mp_map_file(MP mp,mp_string t);
void mp_map_line(MP mp,mp_string t);
void mp_init_map_file(MP mp,int is_troff);


void mp_read_psname_table(MP mp);


void mp_set_job_id(MP mp);


mp_ps_font*mp_ps_font_parse(MP mp,int tex_font);


void mp_ps_font_free(MP mp,mp_ps_font*f);



mp_edge_object*mp_ps_font_charstring(MP mp,mp_ps_font*f,int c);
mp_edge_object*mp_ps_do_font_charstring(MP mp,mp_ps_font*f,char*n);



mp_graphic_object*mp_new_graphic_object(MP mp,int type);


int mp_gr_ship_out(mp_edge_object*hh,int prologues,int procset,int standalone);


#endif

