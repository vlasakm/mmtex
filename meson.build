project('mmtex', 'c')

#git = find_program('git', native: true)
#git_tag = run_command([git, 'describe', '--tag'])
mmtex_version = '20210515'#git_tag.stdout().strip()
add_project_arguments('-DMMTEX_VERSION="@0@"'.format(mmtex_version), language: 'c')

mmtex_inc = include_directories('include')

subdir('src')

mmtex_datadir = get_option('datadir') + '/mmtex'

install_subdir('texmf', install_dir: mmtex_datadir, strip_directory: true)

mmoptex_fmt = custom_target(
  'mmoptex.fmt',
  input: files('texmf/tex/mmoptex/mmoptex.ini'),
  output: 'mmoptex.fmt',
  command: ['env', 'TEXMF=' + meson.current_source_dir() + '/texmf', mmluatex, '-ini', '@INPUT@'],
  install_dir: mmtex_datadir + '/web2c',
  install: true,
)

# symlink mmoptex -> mmluatex
meson.add_install_script('sh', '-c',
  'ln -s mmluatex "$MESON_INSTALL_DESTDIR_PREFIX/@0@/mmoptex"'.format(get_option('bindir'))
)