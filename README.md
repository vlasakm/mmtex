# MMTeX

This repository contains build instructions for MMTeX, a minimal modern
(Lua)TeX distribution.

MMTeX provides only one format - OpTeX. TeXlive's plain LuaTeX used to be
provided as well, but diverged enough to be left out.

The repository of MMTeX is at https://github.com/vlasakm/mmtex.

# Installation instructions

You should [download](https://github.com/vlasakm/mmtex/releases)) or build (see
below) a package for your distribution:

 - `.pkg.tar.zst` for Arch Linux
 - `.deb` for Debian based systems
 - `tar.gz` other Linux distributions (dependencies have to be installed
   manually, see "Dependencies" section)

Then you can install it:

For Arch Linux:

```
pacman -U mmtex-<VERSION>-x86_64.pkg.tar.zst
```

For Debian based systems:

```
dpkg -i mmtex_<VERSION>_amd64.deb
```

For other Linux systems you can install to `/usr/local` like this:

```
tar -C /usr/local -xf mmtex-<VERSION>.tar.gz
```

# Usage

You now have OpTeX available via `mmoptex` command. Note that no implicit fonts
are set. You will get errors if you don't set a font family (e.g.
`\fontfam[lm]` for Latin Modern) as early as possible. (This also applies to
OpTeX demo documents you can find.)

`mmluatex` command is also available and is the `luatex`/`luahbtex` binary
adjusted to use MMTeX paths. But there is no format file (`mmluatex.fmt`) so
you can only use it in `-ini` mode. (Note that because `mmoptex` is just
symlink to `mmluatex` (which means it loads `mmoptex.fmt`) you can also use
`mmoptex -ini` for LuaTeX in `-ini` mode.

# Build instructions

To build `mmtex` package of requested types, run:

```
./package-builder [--all] [--deb] [--arch] [--tar] mmtex..
```

For example to do a full build of all package types, run:

```
./package-builder --all mmtex
```

For building `mmtex` the generic `package-builder` finds information in
`mmtex/` subdirectory. The important files are `info`, `sources` (what gets
downloaded), `build` (build script that calls `meson` to build `luatex` and
creates `texmf` tree), and `files` (`mmtex` specific files for building it,
like `meson.build` and some patches).

For customizing the build you can pass two environment variables:

 - `MESON_SETUP` - generic `meson setup` options, default is
   `--prefix /usr --buildtype release -D b_lto=true -D b_pie=true`, but you may
   want to choose different `prefix` or `buildtype` (like `plain` to use your
   own `CFLAGS`)
 - `MESON_OPTIONS` - should be used to enable/disable package specific options
   (it is empty by default). With `mmtex` it is possible to _not_ build
   `luahbtex` variant by setting `MESON_OPTIONS="-D luahbtex=false"`

# Dependencies

The "generic" package builder has the following dependencies:

 - `git`
 - `svn`
 - `curl`
 - `unzip`
 - `tar`
 - `meson` (+ `python`)
 - `ninja`
 - `makepkg` (for creating Arch Linux packages)
 - `dpkg-deb` (for creating Debian packages)
 - `fakeroot` (for creating `tar` packages)

For building mmtex specifically following are needed (these are also runtime
dependencies of built packages):

 - `libpng`
 - `zlib`
 - `zziplib`
 - `harfbuzz` (if compiling with `luaharfbuzz`, therefore making `luahbtex` variant)


# Documentation

See `doc/old-mmtex-doc.tex`, an older document, for motivation and some design
decisions.

Instructions (build, install, user guide) are not up to date.
Currently the focus and design is shifting towards having only one format using
only modern font mechanisms. There are also planned build system changes.

# License

The license for files found in this repository is in file `LICENSE.mmtex`. For
license information about files/packages included in the distribution see
`LICENSE`.
