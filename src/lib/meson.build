w2c_inc = include_directories(
  'lib',
  # ideally 'include' would be only in mmtex_inc, but this seems
  # like lesser evil, compared to patching luatex source
  'include/w2c',
)

w2c_c_args = [
  '-DHAVE_CONFIG_H',
]

w2c_src = files(
  'src/basechsuffix.c',
  'src/chartostring.c',
  'src/coredump.c',
  'src/eofeoln.c',
  'src/fprintreal.c',
  'src/inputint.c',
  'src/input2int.c',
  'src/lib.h',
  'src/openclose.c',
  'src/printversion.c',
  'src/setupvar.c',
  'src/uexit.c',
  'src/usage.c',
  'src/version.c',
  'src/zround.c',
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
