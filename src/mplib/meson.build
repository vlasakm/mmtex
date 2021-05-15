mplib_src = [
  'src/mpmathdecimal.c',
  'src/mpmathdouble.c',
  'src/mpmath.c',
  'src/mpstrings.c',
  'src/mp.c',
  'src/psout.c',
  'src/tfmin.c',
  'src/avl.c',
  'src/decNumber.c',
  'src/decContext.c',
  #'src/mplibpng.h',
  #'src/mplibsvg.h',
]

mplib_inc = include_directories(
  'src',
)

mplib_lib = static_library(
  'mplib',
  sources: mplib_src,
  include_directories: [mplib_inc, mmtex_inc],
  dependencies: kpathsea_dep,
)

mplib_dep = declare_dependency(
  link_with: mplib_lib,
  include_directories: mplib_inc,
)
