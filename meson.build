project(
  'mmtex',
  'c',
  version: '20231102',
)

mmtex_version = meson.project_version()

add_project_arguments('-DMMTEX_VERSION="@0@"'.format(mmtex_version), language: 'c')

mmtex_inc = include_directories('include')

subdir('src')

mmtex_datadir = get_option('datadir') + '/mmtex'

install_subdir('texmf', install_dir: mmtex_datadir, strip_directory: true)

mmoptex_fmt = custom_target(
  'mmoptex.fmt',
  input: files('texmf/tex/mmoptex/mmoptex.ini'),
  output: 'mmoptex.fmt',
  env: {
    'TEXMF': meson.current_source_dir() + '/texmf',
    'TEXMFCNF': '/none', # no config files
  },
  command: [
    mmluatex,
    '-ini',
    '@INPUT@'
  ],
  install_dir: mmtex_datadir + '/web2c',
  install: true,
)

# symlink mmoptex -> mmluatex
install_symlink(
  'mmoptex',
  install_dir: get_option('bindir'),
  pointing_to: 'mmluatex',
)
