lua_src = files(
  # core
  'src/lapi.c',
  'src/lcode.c',
  'src/lctype.c',
  'src/ldebug.c',
  'src/ldo.c',
  'src/ldump.c',
  'src/lfunc.c',
  'src/lgc.c',
  'src/llex.c',
  'src/lmem.c',
  'src/lobject.c',
  'src/lopcodes.c',
  'src/lparser.c',
  'src/lstate.c',
  'src/lstring.c',
  'src/ltable.c',
  'src/ltm.c',
  'src/lundump.c',
  'src/lvm.c',
  'src/lzio.c',
  # lib
  'src/lauxlib.c',
  'src/lbaselib.c',
  'src/lbitlib.c',
  'src/lcorolib.c',
  'src/ldblib.c',
  'src/liolib.c',
  'src/lmathlib.c',
  'src/loslib.c',
  'src/lstrlib.c',
  'src/ltablib.c',
  'src/lutf8lib.c',
  'src/loadlib.c',
  'src/linit.c',
)

lua_c_args = [
  '-DLUA_COMPAT_MODULE',
  '-DLUA_COMPAT_5_2',
  '-DLUAI_HASHLIMIT=6',
  '-DLUA_USE_POSIX',
  '-DLUA_USE_DLOPEN',
]

lua_inc = include_directories(
  'src',
)

lua_lib = static_library(
  'lua',
  sources: lua_src,
  include_directories: lua_inc,
  c_args: lua_c_args,
)

lua_dep = declare_dependency(
  link_with: lua_lib,
  include_directories: lua_inc,
  compile_args: lua_c_args,
)
