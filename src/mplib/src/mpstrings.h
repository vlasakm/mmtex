/*3:*/

#ifndef MPSTRINGS_H
#define MPSTRINGS_H 1
#include "mplib.h"
#include "mplibps.h"            
#include "mplibsvg.h"           
#include "mpmp.h"               
#include "mppsout.h"            
#include "mpsvgout.h"           
#include "mpmath.h"             
/*4:*/

void*copy_strings_entry(const void*p);

/*:4*//*8:*/

extern int mp_xstrcmp(const char*a,const char*b);
extern char*mp_xstrdup(MP mp,const char*s);
extern char*mp_xstrldup(MP mp,const char*s,size_t l);
extern char*mp_strdup(const char*p);
extern char*mp_strldup(const char*p,size_t l);

/*:8*//*13:*/

extern void mp_initialize_strings(MP mp);
extern void mp_dealloc_strings(MP mp);

/*:13*//*14:*/

char*mp_str(MP mp,mp_string s);
mp_string mp_rtsl(MP mp,const char*s,size_t l);
mp_string mp_rts(MP mp,const char*s);
mp_string mp_make_string(MP mp);

/*:14*//*18:*/

#define EXTRA_STRING 500
#define append_char(A) do { \
    str_room(1); \
    *(mp->cur_string+mp->cur_length)= (unsigned char)(A); \
    mp->cur_length++; \
} while (0)
#define str_room(wsize) do { \
    size_t nsize; \
    if ((mp->cur_length+(size_t)wsize) >  mp->cur_string_size) { \
        nsize =  mp->cur_string_size + mp->cur_string_size / 5 + EXTRA_STRING; \
        if (nsize < (size_t)(wsize)) { \
            nsize =  (size_t)wsize + EXTRA_STRING; \
        } \
        mp->cur_string =  (unsigned char *) mp_xrealloc(mp, mp->cur_string, (unsigned)nsize, sizeof(unsigned char)); \
        memset (mp->cur_string+mp->cur_length,0,(nsize-mp->cur_length)); \
        mp->cur_string_size =  nsize; \
    } \
} while (0)


/*:18*//*19:*/

void mp_reset_cur_string(MP mp);

/*:19*//*21:*/

#define MAX_STR_REF 127 
#define add_str_ref(A) { if ( (A)->refs < MAX_STR_REF ) ((A)->refs)++; }

/*:21*//*22:*/

#define delete_str_ref(A) do {  \
    if ( (A)->refs < MAX_STR_REF ) { \
       if ( (A)->refs >  1 ) ((A)->refs)--;  \
       else mp_flush_string(mp, (A)); \
    } \
  } while (0)

/*:22*//*23:*/

void mp_flush_string(MP mp,mp_string s);

/*:23*//*26:*/

mp_string mp_intern(MP mp,const char*s);


/*:26*//*27:*/

mp_string mp_make_string(MP mp);

/*:27*//*29:*/

integer mp_str_vs_str(MP mp,mp_string s,mp_string t);

/*:29*//*31:*/

mp_string mp_cat(MP mp,mp_string a,mp_string b);

/*:31*//*33:*/

mp_string mp_chop_string(MP mp,mp_string s,integer a,integer b);

/*:33*/
;
#endif

/*:3*/
