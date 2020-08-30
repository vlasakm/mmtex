# LLTeX

This repository contains build instructions for LLTeX, a lightweight LuaTeX distribution.

LLTeX provides two formats `optex` and texlive's plain `luatex`.


## Build instructions

To build Arch Linux - pacman package, run:

```
makepkg
```

To build .deb package, run:

```
./build-deb
```

To create both packages, while not building everything twice, run:

```
makepkg
env USE_MAKEPKG_PKG=1 ./build-deb
```
