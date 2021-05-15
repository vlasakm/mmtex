pplib_src = files(
  'src/pparray.c',
  'src/ppcrypt.c',
  'src/ppdict.c',
  'src/ppheap.c',
  'src/ppload.c',
  'src/ppstream.c',
  'src/ppxref.c',
  'src/util/utilbasexx.c',
  'src/util/utilcrypt.c',
  'src/util/utilflate.c',
  'src/util/utilfpred.c',
  'src/util/utiliof.c',
  'src/util/utillog.c',
  'src/util/utillzw.c',
  'src/util/utilmd5.c',
  'src/util/utilmem.c',
  'src/util/utilmemheap.c',
  'src/util/utilmemheapiof.c',
  'src/util/utilmeminfo.c',
  'src/util/utilnumber.c',
  'src/util/utilsha.c',
)

pplib_inc = include_directories(
  'src',
  'src/util',
)

pplib_lib = static_library(
  'pplib',
  sources: pplib_src,
  include_directories: pplib_inc,
)

pplib_dep = declare_dependency(
  link_with: pplib_lib,
  include_directories: pplib_inc,
)
