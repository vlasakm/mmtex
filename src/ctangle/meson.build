ctangle = executable(
  'ctangle',
  sources: files(
    'src/ctangle.c',
    'src/common.c',
  ),
)

tangle = generator(
  ctangle,
  output: '@BASENAME@.c',
  arguments: ['@INPUT@', '-', '@OUTPUT@'],
)
