w2c_inc = include_directories(
  'lib',
  '.',
  # ideally 'include' would be only in mmtex_inc, but this seems
  # like lesser evil, compared to patching luatex source
  '../../include/w2c',
)

w2c_c_args = [
  '-DHAVE_CONFIG_H',
]

w2c_src = files(
  'lib/basechsuffix.c',
  'lib/chartostring.c',
  'lib/coredump.c',
  'lib/eofeoln.c',
  'lib/fprintreal.c',
  'lib/inputint.c',
  'lib/input2int.c',
  'lib/lib.h',
  'lib/openclose.c',
  'lib/printversion.c',
  'lib/setupvar.c',
  'lib/uexit.c',
  'lib/usage.c',
  'lib/version.c',
  'lib/zround.c',
)

w2c_lib = static_library(
  'w2c',
  sources: w2c_src,
  include_directories: [w2c_inc, mmtex_inc],
  c_args: w2c_c_args,
  dependencies: [kpathsea_dep],
)

w2c_dep = declare_dependency(
  link_with: w2c_lib,
  include_directories: w2c_inc,
  compile_args: w2c_c_args,
  dependencies: [kpathsea_dep],
)
