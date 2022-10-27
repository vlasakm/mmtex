/* Not an original file from dvipdfmx, but collection of its functions needed by
   what is needed by luatex. */

/* This is dvipdfmx, an eXtended version of dvipdfm by Mark A. Wicks.

    Copyright (C) 2002-2020 by Jin-Hwan Cho and Shunsaku Hirata,
    the dvipdfmx project team.

    Copyright (C) 1998, 1999 by Mark A. Wicks <mwicks@kettering.edu>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
*/

#ifndef _DVIPDFMX_UTIL_H_
#define _DVIPDFMX_UTIL_H_

/* So we don't have to include whole of ptexlib.h */
extern void formatted_error(const char *t, const char *fmt, ...);
extern void formatted_warning(const char *t, const char *fmt, ...);

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

#define ASSERT(a) assert(a)
#define RELEASE(a) free(a)
#define NEW(a,b) malloc((unsigned)((unsigned)(a)*sizeof(b)))
#define RENEW(a,b,c) realloc(a, (unsigned)((unsigned)(b)*sizeof(c)))
#define ERROR(...) formatted_error("dvipdfmx",__VA_ARGS__)
#define WARN(...) formatted_warning("dvipdfmx",__VA_ARGS__)
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

static inline void
seek_relative (FILE *file, int32_t pos)
{
  if (fseek(file, (long)pos, SEEK_CUR)) {
    ERROR("seek failed");
  }
}

extern char *xstrdup(const char *);

static inline int
xtoi (char ch)
{
  if (ch >= '0' && ch <= '9')
    return ch - '0';
  if (ch >= 'A' && ch <= 'F')
    return (ch - 'A') + 10;
  if (ch >= 'a' && ch <= 'f')
    return (ch - 'a') + 10;

  return -1;
}

#define is_space(c) ((c) == ' '  || (c) == '\t' || (c) == '\f' || \
		     (c) == '\r' || (c) == '\n' || (c) == '\0')

#define is_delim(c) ((c) == '(' || (c) == ')' || \
                     (c) == '/' || \
                     (c) == '<' || (c) == '>' || \
		     (c) == '[' || (c) == ']' || \
                     (c) == '{' || (c) == '}' || \
                     (c) == '%')

static inline void
skip_white_spaces (unsigned char **s, unsigned char *endptr)
{
  while (*s < endptr)
    if (!is_space(**s))
      break;
    else
      (*s)++;
}

#endif /* _DVIPDFMX_UTIL_H_ */
