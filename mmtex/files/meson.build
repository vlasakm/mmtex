project('luatex', 'c')

git = find_program('git', native: true)
git_tag = run_command([git, 'describe', '--tag'])
mmtex_version = git_tag.stdout().strip()
add_project_arguments('-DMMTEX_VERSION="@0@"'.format(mmtex_version), language: 'c')

mmtex_inc = include_directories('include')

kpathsea_src = files(
  'kpathsea/absolute.c',
  'kpathsea/atou.c',
  'kpathsea/cnf.c',
  'kpathsea/concat.c',
  'kpathsea/concat3.c',
  'kpathsea/concatn.c',
  'kpathsea/db.c',
  'kpathsea/debug.c',
  'kpathsea/dir.c',
  'kpathsea/elt-dirs.c',
  'kpathsea/expand.c',
  'kpathsea/extend-fname.c',
  'kpathsea/file-p.c',
  'kpathsea/find-suffix.c',
  'kpathsea/fn.c',
  'kpathsea/fontmap.c',
  'kpathsea/hash.c',
  'kpathsea/kdefault.c',
  'kpathsea/kpathsea.c',
  'kpathsea/line.c',
  'kpathsea/magstep.c',
  'kpathsea/make-suffix.c',
  'kpathsea/path-elt.c',
  'kpathsea/pathsearch.c',
  'kpathsea/proginit.c',
  'kpathsea/progname.c',
  'kpathsea/readable.c',
  'kpathsea/rm-suffix.c',
  'kpathsea/str-list.c',
  'kpathsea/str-llist.c',
  'kpathsea/tex-file.c',
  'kpathsea/tex-glyph.c',
  'kpathsea/tex-hush.c',
  'kpathsea/tex-make.c',
  'kpathsea/tilde.c',
  'kpathsea/uppercasify.c',
  'kpathsea/variable.c',
  'kpathsea/version.c',
  'kpathsea/xbasename.c',
  'kpathsea/xcalloc.c',
  'kpathsea/xdirname.c',
  'kpathsea/xfopen.c',
  'kpathsea/xfseek.c',
  'kpathsea/xfseeko.c',
  'kpathsea/xftell.c',
  'kpathsea/xftello.c',
  'kpathsea/xgetcwd.c',
  'kpathsea/xmalloc.c',
  'kpathsea/xopendir.c',
  'kpathsea/xputenv.c',
  'kpathsea/xrealloc.c',
  'kpathsea/xstat.c',
  'kpathsea/xstrdup.c',
)

kpathsea_lib = static_library(
  'kpathsea',
  sources: kpathsea_src,
  include_directories: mmtex_inc,
  c_args: '-DMAKE_KPSE_DLL',
)

kpathsea_dep = declare_dependency(
  link_with: kpathsea_lib,
  include_directories: include_directories([
    'kpathsea',
  ]),
)

ctangle = executable(
  'ctangle',
  sources: files(
    'ctangle.c',
    'common.c',
  ),
)

tangle = generator(
  ctangle,
  output: '@BASENAME@.c',
  arguments: ['@INPUT@', '-', '@OUTPUT@'],
)

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
    'mplibdir/mpmathdecimal.w',
    'mplibdir/mpmathdouble.w',
    'mplibdir/mpmath.w',
    'mplibdir/mpstrings.w',
    'mplibdir/mp.w',
    'mplibdir/psout.w',
    'mplibdir/tfmin.w',
  ),
  'mplibdir/avl.c',
  'mplibdir/decNumber.c',
  'mplibdir/decContext.c',
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

lua_src = files(
  # core
  'lua/src/lapi.c',
  'lua/src/lcode.c',
  'lua/src/lctype.c',
  'lua/src/ldebug.c',
  'lua/src/ldo.c',
  'lua/src/ldump.c',
  'lua/src/lfunc.c',
  'lua/src/lgc.c',
  'lua/src/llex.c',
  'lua/src/lmem.c',
  'lua/src/lobject.c',
  'lua/src/lopcodes.c',
  'lua/src/lparser.c',
  'lua/src/lstate.c',
  'lua/src/lstring.c',
  'lua/src/ltable.c',
  'lua/src/ltm.c',
  'lua/src/lundump.c',
  'lua/src/lvm.c',
  'lua/src/lzio.c',
  # lib
  'lua/src/lauxlib.c',
  'lua/src/lbaselib.c',
  'lua/src/lbitlib.c',
  'lua/src/lcorolib.c',
  'lua/src/ldblib.c',
  'lua/src/liolib.c',
  'lua/src/lmathlib.c',
  'lua/src/loslib.c',
  'lua/src/lstrlib.c',
  'lua/src/ltablib.c',
  'lua/src/lutf8lib.c',
  'lua/src/loadlib.c',
  'lua/src/linit.c',
)

lua_c_args = [
  '-DLUA_COMPAT_MODULE',
  '-DLUA_COMPAT_5_2',
  '-DLUAI_HASHLIMIT=6',
  '-DLUA_USE_POSIX',
  '-DLUA_USE_DLOPEN',
]

lua_inc = include_directories(
  'lua/src',
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


pplib_src = files(
  'pplib/src/pparray.c',
  'pplib/src/ppcrypt.c',
  'pplib/src/ppdict.c',
  'pplib/src/ppheap.c',
  'pplib/src/ppload.c',
  'pplib/src/ppstream.c',
  'pplib/src/ppxref.c',
  'pplib/src/util/utilbasexx.c',
  'pplib/src/util/utilcrypt.c',
  'pplib/src/util/utilflate.c',
  'pplib/src/util/utilfpred.c',
  'pplib/src/util/utiliof.c',
  'pplib/src/util/utillog.c',
  'pplib/src/util/utillzw.c',
  'pplib/src/util/utilmd5.c',
  'pplib/src/util/utilmem.c',
  'pplib/src/util/utilmemheap.c',
  'pplib/src/util/utilmemheapiof.c',
  'pplib/src/util/utilmeminfo.c',
  'pplib/src/util/utilnumber.c',
  'pplib/src/util/utilsha.c',
)

pplib_inc = include_directories(
  'pplib/src',
  'pplib/src/util',
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


luatex_src = files(
  'luatexdir/luafilesystem/src/lfs.c',
  'luatexdir/luamd5/md5.c',
  'luatexdir/luamd5/md5lib.c',
  'luatexdir/luapeg/lpeg.c',
  'luatexdir/luazip/src/luazip.c',
  'luatexdir/luazlib/lgzip.c',
  'luatexdir/luazlib/lzlib.c',
  'luatexdir/slnunicode/slnunico.c',
  'luatexdir/luasocket/src/auxiliar.c',
  'luatexdir/luasocket/src/buffer.c',
  'luatexdir/luasocket/src/compat.c',
  'luatexdir/luasocket/src/except.c',
  'luatexdir/luasocket/src/inet.c',
  'luatexdir/luasocket/src/io.c',
  'luatexdir/luasocket/src/lua_preload.c',
  'luatexdir/luasocket/src/luasocket.c',
  'luatexdir/luasocket/src/mime.c',
  'luatexdir/luasocket/src/options.c',
  'luatexdir/luasocket/src/select.c',
  'luatexdir/luasocket/src/serial.c',
  'luatexdir/luasocket/src/socket.c',
  'luatexdir/luasocket/src/tcp.c',
  'luatexdir/luasocket/src/timeout.c',
  'luatexdir/luasocket/src/udp.c',
  'luatexdir/unilib/alphabet.c',
  'luatexdir/unilib/ArabicForms.c',
  'luatexdir/unilib/char.c',
  'luatexdir/unilib/cjk.c',
  'luatexdir/unilib/gwwiconv.c',
  'luatexdir/unilib/ucharmap.c',
  'luatexdir/unilib/unialt.c',
  'luatexdir/unilib/usprintf.c',
  'luatexdir/unilib/ustring.c',
  'luatexdir/unilib/utype.c',
  'luatexdir/luafontloader/fontforge/fontforge/autohint.c',
  'luatexdir/luafontloader/fontforge/fontforge/clipnoui.c',
  'luatexdir/luafontloader/fontforge/fontforge/cvundoes.c',
  'luatexdir/luafontloader/fontforge/fontforge/dumppfa.c',
  'luatexdir/luafontloader/fontforge/fontforge/encoding.c',
  'luatexdir/luafontloader/fontforge/fontforge/featurefile.c',
  'luatexdir/luafontloader/fontforge/fontforge/fontviewbase.c',
  'luatexdir/luafontloader/fontforge/fontforge/fvcomposit.c',
  'luatexdir/luafontloader/fontforge/fontforge/fvfonts.c',
  'luatexdir/luafontloader/fontforge/fontforge/lookups.c',
  'luatexdir/luafontloader/fontforge/fontforge/macbinary.c',
  'luatexdir/luafontloader/fontforge/fontforge/macenc.c',
  'luatexdir/luafontloader/fontforge/fontforge/mathconstants.c',
  'luatexdir/luafontloader/fontforge/fontforge/memory.c',
  'luatexdir/luafontloader/fontforge/fontforge/mm.c',
  'luatexdir/luafontloader/fontforge/fontforge/namelist.c',
  'luatexdir/luafontloader/fontforge/fontforge/noprefs.c',
  'luatexdir/luafontloader/fontforge/fontforge/nouiutil.c',
  'luatexdir/luafontloader/fontforge/fontforge/parsepfa.c',
  'luatexdir/luafontloader/fontforge/fontforge/parsettf.c',
  'luatexdir/luafontloader/fontforge/fontforge/parsettfatt.c',
  'luatexdir/luafontloader/fontforge/fontforge/psread.c',
  'luatexdir/luafontloader/fontforge/fontforge/pua.c',
  'luatexdir/luafontloader/fontforge/fontforge/python.c',
  'luatexdir/luafontloader/fontforge/fontforge/sfd1.c',
  'luatexdir/luafontloader/fontforge/fontforge/splinechar.c',
  'luatexdir/luafontloader/fontforge/fontforge/splinefill.c',
  'luatexdir/luafontloader/fontforge/fontforge/splinefont.c',
  'luatexdir/luafontloader/fontforge/fontforge/splineorder2.c',
  'luatexdir/luafontloader/fontforge/fontforge/splineoverlap.c',
  'luatexdir/luafontloader/fontforge/fontforge/splinerefigure.c',
  'luatexdir/luafontloader/fontforge/fontforge/splinesave.c',
  'luatexdir/luafontloader/fontforge/fontforge/splinesaveafm.c',
  'luatexdir/luafontloader/fontforge/fontforge/splinestroke.c',
  'luatexdir/luafontloader/fontforge/fontforge/splineutil.c',
  'luatexdir/luafontloader/fontforge/fontforge/splineutil2.c',
  'luatexdir/luafontloader/fontforge/fontforge/start.c',
  'luatexdir/luafontloader/fontforge/fontforge/stemdb.c',
  'luatexdir/luafontloader/fontforge/fontforge/tottf.c',
  'luatexdir/luafontloader/fontforge/fontforge/tottfgpos.c',
  'luatexdir/luafontloader/fontforge/fontforge/ttfspecial.c',
  'luatexdir/luafontloader/fontforge/gutils/fsys.c',
  'luatexdir/lua/lstrlibext.c',
  'luatexdir/lua/helpers.c',
  'luatexdir/lua/texluac.c',
  'luatexdir/utils/utils.c',
  'luatexdir/lua/luastuff.c',
  'luatexdir/lua/luainit.c',
  'luatexdir/tex/printing.c',
  'luatexdir/luafontloader/src/ffdummies.c',
  'luatexdir/luafontloader/src/luafflib.c',
  'luatexdir/dvi/dvigen.c',
  'luatexdir/font/dofont.c',
  'luatexdir/font/luafont.c',
  'luatexdir/font/mapfile.c',
  'luatexdir/font/pkin.c',
  'luatexdir/font/sfnt.c',
  'luatexdir/font/texfont.c',
  'luatexdir/font/tfmofm.c',
  'luatexdir/font/tounicode.c',
  'luatexdir/font/tt_glyf.c',
  'luatexdir/font/tt_table.c',
  'luatexdir/font/vfovf.c',
  'luatexdir/font/vfpacket.c',
  'luatexdir/font/writecff.c',
  'luatexdir/font/writeenc.c',
  'luatexdir/font/writefont.c',
  'luatexdir/font/writet1.c',
  'luatexdir/font/writet3.c',
  'luatexdir/font/writettf.c',
  'luatexdir/font/writetype0.c',
  'luatexdir/font/writetype2.c',
  'luatexdir/image/pdftoepdf.c',
  'luatexdir/image/writeimg.c',
  'luatexdir/image/writejbig2.c',
  'luatexdir/image/writejp2.c',
  'luatexdir/image/writejpg.c',
  'luatexdir/image/writepng.c',
  'luatexdir/lang/hnjalloc.c',
  'luatexdir/lang/hyphen.c',
  'luatexdir/lang/texlang.c',
  'luatexdir/lua/lcallbacklib.c',
  'luatexdir/lua/lfontlib.c',
  'luatexdir/lua/limglib.c',
  'luatexdir/lua/lpdfelib.c',
  'luatexdir/lua/lpdfscannerlib.c',
  'luatexdir/lua/lkpselib.c',
  'luatexdir/lua/llanglib.c',
  'luatexdir/lua/llualib.c',
  'luatexdir/lua/lnodelib.c',
  'luatexdir/lua/liolibext.c',
  'luatexdir/lua/loslibext.c',
  'luatexdir/lua/lpdflib.c',
  'luatexdir/lua/lstatslib.c',
  'luatexdir/lua/ltexiolib.c',
  'luatexdir/lua/ltexlib.c',
  'luatexdir/lua/lnewtokenlib.c',
  'luatexdir/lua/luatex-core.c',
  'luatexdir/lua/helpers.c',
  'luatexdir/lua/luanode.c',
  'luatexdir/lua/luatoken.c',
  'luatexdir/lua/mplibstuff.c',
  'luatexdir/pdf/pdfaction.c',
  'luatexdir/pdf/pdfannot.c',
  'luatexdir/pdf/pdfcolorstack.c',
  'luatexdir/pdf/pdfdest.c',
  'luatexdir/pdf/pdffont.c',
  'luatexdir/pdf/pdfgen.c',
  'luatexdir/pdf/pdfglyph.c',
  'luatexdir/pdf/pdfimage.c',
  'luatexdir/pdf/pdflink.c',
  'luatexdir/pdf/pdflistout.c',
  'luatexdir/pdf/pdfliteral.c',
  'luatexdir/pdf/pdfobj.c',
  'luatexdir/pdf/pdfoutline.c',
  'luatexdir/pdf/pdfpage.c',
  'luatexdir/pdf/pdfpagetree.c',
  'luatexdir/pdf/pdfrule.c',
  'luatexdir/pdf/pdfsaverestore.c',
  'luatexdir/pdf/pdfsetmatrix.c',
  'luatexdir/pdf/pdfshipout.c',
  'luatexdir/pdf/pdftables.c',
  'luatexdir/pdf/pdfthread.c',
  'luatexdir/pdf/pdfxform.c',
  'luatexdir/tex/backend.c',
  'luatexdir/tex/align.c',
  'luatexdir/tex/arithmetic.c',
  'luatexdir/tex/buildpage.c',
  'luatexdir/tex/commands.c',
  'luatexdir/tex/conditional.c',
  'luatexdir/tex/directions.c',
  'luatexdir/tex/dumpdata.c',
  'luatexdir/tex/equivalents.c',
  'luatexdir/tex/errors.c',
  'luatexdir/tex/expand.c',
  'luatexdir/tex/extensions.c',
  'luatexdir/tex/filename.c',
  'luatexdir/tex/inputstack.c',
  'luatexdir/tex/linebreak.c',
  'luatexdir/tex/mainbody.c',
  'luatexdir/tex/maincontrol.c',
  'luatexdir/tex/mathcodes.c',
  'luatexdir/tex/memoryword.c',
  'luatexdir/tex/mlist.c',
  'luatexdir/tex/nesting.c',
  'luatexdir/tex/packaging.c',
  'luatexdir/tex/postlinebreak.c',
  'luatexdir/tex/primitive.c',
  'luatexdir/tex/scanning.c',
  'luatexdir/tex/stringpool.c',
  'luatexdir/tex/texdeffont.c',
  'luatexdir/tex/texfileio.c',
  'luatexdir/tex/texmath.c',
  'luatexdir/tex/texnodes.c',
  'luatexdir/tex/textcodes.c',
  'luatexdir/tex/textoken.c',
  'luatexdir/utils/avl.c',
  'luatexdir/utils/avlstuff.c',
  'luatexdir/utils/managed-sa.c',
  'luatexdir/utils/unistring.c',
  'synctexdir/synctex.c',
  'luatexdir/luaffi/call.c',
  'luatexdir/luaffi/ctype.c',
  'luatexdir/luaffi/ffi.c',
  'luatexdir/luaffi/parser.c',
  'luatexdir/luatex.c',
  'mplibdir/lmplib.c',
  'libmd5/md5.c',
)

luatex_inc = include_directories(
  'luatexdir/unilib',
  'luatexdir',
  'luatexdir/luafontloader/fontforge/inc',
  'luatexdir/luafontloader/fontforge/fontforge',
  'libmd5',
  'synctexdir',
)

cc = meson.get_compiler('c')

luatex_dependencies = [
  cc.find_library('m', required: false),
  cc.find_library('dl', required: false),
  dependency('libpng'),
  dependency('zlib'),
  dependency('zziplib'),
  lua_dep,
  mplib_dep,
  pplib_dep,
  kpathsea_dep,
  w2c_dep,
]

luatex_c_args = [
  '-DLUASOCKET_DEBUG',
  '-DLUA_FF_LIB',
  '-D_NO_PYTHON',
  '-DX_DISPLAY_MISSING',
  '-DUSE_OUR_MEMORY',
  '-DSYNCTEX_ENGINE_H=<synctex-luatex.h>',
]

if get_option('luahbtex')
  luaharfbuzz_src = files(
    'luatexdir/luaharfbuzz/src/luaharfbuzz/blob.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/buffer.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/class_utils.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/direction.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/face.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/feature.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/font.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/language.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/luaharfbuzz.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/luaharfbuzz.h',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/ot.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/script.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/tag.c',
    'luatexdir/luaharfbuzz/src/luaharfbuzz/unicode.c',
  )

  harfbuzz_dep = dependency('harfbuzz')

  luaharfbuzz_lib = static_library(
    'luaharfbuzz',
    sources: luaharfbuzz_src,
    dependencies: [harfbuzz_dep, lua_dep],
  )

  luaharfbuzz_dep = declare_dependency(
    link_with: luaharfbuzz_lib,
    dependencies: [harfbuzz_dep, lua_dep],
  )

  luatex_dependencies += [luaharfbuzz_dep]
  luatex_c_args +=  ['-DLUATEX_HARFBUZZ_ENABLED']
endif

executable(
  'mmluatex',
  sources: luatex_src,
  include_directories: [luatex_inc, mmtex_inc],
  dependencies: luatex_dependencies,
  c_args: luatex_c_args,
  install: true,
)
