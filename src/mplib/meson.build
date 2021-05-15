mplib_png_h = custom_target(
  'mplibpng.h',
  input: 'mplibdir/pngout.w',
  output: 'mplibpng.h',
  command: [ctangle, '-q', '@INPUT@'],
)

mplib_svg_h = custom_target(
  'mplibsvg.h',
  input: 'mplibdir/svgout.w',
  output: 'mplibsvg.h',
  command: [ctangle, '-q', '@INPUT@'],
)

mplib_h = [
  mplib_png_h,
  mplib_svg_h,
]

mplib_src = [
  tangle.process(
    'src/mpmathdecimal.w',
    'src/mpmathdouble.w',
    'src/mpmath.w',
    'src/mpstrings.w',
    'src/mp.w',
    'src/psout.w',
    'src/tfmin.w',
  ),
  'src/avl.c',
  'src/decNumber.c',
  'src/decContext.c',
  mplib_svg_h,
  mplib_png_h,
]

mplib_inc = include_directories(
  'mplibdir',
)

mplib_lib = static_library(
  'mplib',
  sources: mplib_src,
  include_directories: [mplib_inc, mmtex_inc],
)

mplib_dep = declare_dependency(
  link_with: mplib_lib,
  sources: [mplib_h],
  include_directories: mplib_inc,
)
