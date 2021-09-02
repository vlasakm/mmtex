# MMTeX

This is MMTeX, a minimal modern TeX distribution, which consists of the [LuaTeX
engine](http://luatex.org/) and the [OpTeX format](http://petr.olsak.net/optex/).

The repository of MMTeX is at https://github.com/vlasakm/mmtex.

# Installation instructions

For Debian, Ubuntu, Fedora, openSUSE you can install MMTeX from the [Open Build
Service](https://software.opensuse.org/download.html?project=home%3Alahcim8&package=mmtex).
Just choose your distribution and version and follow the instructions there.

If you choose to "Grab binary packages directly" you need to install and keep
the package up to date manually. If you instead "Add repository and install
manually" you add a repository to your package manager, and can install `mmtex`
like any other package from your distribution.

For Arch Linux see the [AUR](https://aur.archlinux.org/packages/mmtex/) package.

You can also
[build the package from source](#manual-build-and-installation-instructions)
and install it to some path on your system.

# Usage

You now have OpTeX available via the `mmoptex` command. Note that no implicit fonts
are set. You will get errors if you don't set a font family (e.g.
`\fontfam[lm]` for Latin Modern) as early as possible. (This also applies to
the various OpTeX demo documents you can find.)

For a quick start, you can try printing the catalog of fonts your OpTeX has
available:

```
% font-catalog.tex
\fontfam[catalog]

\bye
```

Compile with `mmoptex font-catalog.tex`.


## Advanced usage

If you don't understand this, you don't need it.

LuaTeX in "ini" mode is also available, with either `mmoptex -ini` or `mmluatex
-ini`. If you know what you are doing, you can use it, for example to
regenerate the format file:

```
mmoptex -ini mmoptex.ini
```

# Manual build and installation instructions

To build `mmtex` from source and install it your home directory, you can run:

```
meson setup builddir --prefix ~/.mmtex --buildtype release
meson compile -C builddir
meson install -C builddir
```

Now you can run it by specifying full path:

```
~/.mmtex/bin/mmoptex mydocument.tex
```

Or you can add it to your `$PATH` (possibly in your `~/.profile` file):

```
PATH="$HOME/.mmtex/bin:$PATH"
export PATH
```

Then you can use it like this:

```
mmoptex mydocument.tex
```

Uninstallation is easy, just delete the installation directory and possible
also the cache:

```
rm -rf ~/.mmtex ~/.cache/mmtex
```

## Advanced builds

The `meson setup` step allows [more
customization](https://mesonbuild.com/Commands.html#setup) than in the example
above. Other options are also provided by this package:

 - `-D luahbtex=<true|false>` (default: `false`) decides whether to build
   `luahbtex` instead of `luatex`. OpTeX currently doesn't take advantage of
   this in any way.

# Dependencies

Build only dependencies:

 - `meson` (+ `python`)
 - `ninja`
 - `pkg-config`

Build and run time dependencies:

 - `libpng`
 - `zlib`
 - `zziplib`
 - `harfbuzz` (if compiling with `-D luahbtex=true`)

# License

The license for meson build and packaging files is in file `LICENSE.mmtex`. The
license information about source files/packages (directories `src` and `texmf`)
included in the distribution see `LICENSE`.
