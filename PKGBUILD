pkgname=lltex
pkgver=0.1
pkgrel=1
pkgdesc='A leightweight LuaTeX distribution'
arch=('x86_64')
url='https://gitlab.com/lahcim8/lltex'
_ctan="http://mirrors.ctan.org"
_texlive="svn://tug.org/texlive"
source=("git+https://github.com/TeX-Live/luatex#branch=tags/1.12.0" # luatex binary source

        "git+https://github.com/hyphenation/tex-hyphen#tag=CTAN-2020.03.25" # hyph-utf8, etex.src
        "$_ctan/obsolete/systems/e-tex/v2/src/etexdefs.lib" # etexdefs.lib
        "$_ctan/macros/generic/unicode-data.zip" # unicode-data

        "$_ctan/systems/knuth/dist/lib.zip" # plain.tex, hyphen.tex
        "$_ctan/fonts/amsfonts.zip" # computer modern .pfb files
        "$_ctan/fonts/cm/tfm.zip" # computer modern .tfm files
        "$_ctan/fonts/manual.zip" # manfnt font
        "$_ctan/fonts/ec.zip" # ecso, ecsx .tfm files
        "$_ctan/fonts/lm.zip" # ec-lm .pfb files
        "$_ctan/fonts/rsfs.zip" # rsfs .pfb files
        "$_texlive/trunk/Master/texmf-dist/fonts/tfm/public/rsfs" # rsfs .tfm file
        "$_ctan/fonts/ps-type1/cm-super.zip" # ecso, ecsx .pfb files
        "$_ctan/macros/cstex/base/cmexb.tar.gz" # cmexb font

        "$_ctan/install/macros/luatex/generic/lualibs.tds.zip" # lualibs
        "$_ctan/install/macros/latex/latex-base.tds.zip" # ltluatex
        "$_ctan/macros/luatex/generic/luaotfload.zip" # luaotfload
        "$_ctan/install/macros/luatex/generic/luamplib.tds.zip" # luamplib

        # metapost base files
        # "https://ctan.org/tex-archive/obsolete/graphics/metapost/base/texmf/metapost/base/"
        "$_texlive/trunk/Master/texmf-dist/metapost/base/"

        "$_ctan/macros/generic/tex-ini-files.zip" # luatex.ini, etc

        "$_ctan/macros/luatex/optex.zip" # optex
        "$_texlive/trunk/Master/texmf-dist/tex/latex/lipsum" # optex needs lipsum.ltd.tex

        "texmf.cnf" # custom kpathsea config file
        "pdftex.map" # mapping of used type1 fonts
        "luatexiniconfig.tex" # config for plain luatex format
        "extract-language-data.awk") # creates language.def, language.dat.lua

sha256sums=('SKIP'
            'SKIP'
            '09af6198ac22a824b63ea4176fe584ef62802c1c7fb87f585fa97266d4142f03'
            'd38bc164d143a7d3cc1b99482509d7debaa7d2b12c8d652868264275014be5bd'
            'f697b665c835d4888b2417edbbf1c23322c722fc8163b1a231916f4e40dcd8fe'
            'aaab3930b952128b7ed65260144493eb3d88cb063b50da1f90272e23c7e08ba2'
            '2697459803c68db061217273ac7386efbfa17ed362aa3c7eafa24fb86cf1b4e2'
            '309e92d8ea932115b5775a418f0ef4ae373d088eefd70cf25d58757647c9901b'
            '364ea6dc4c05ca49833c31f8bb510bd7cd94142e8e934c59df48a950695c9ed4'
            '298744467b504c13a542ccfa0014f05e60367d0a84b4963f51036081980f4bd0'
            'd57d16ff8b438fad7212a822a394e099b427d1fb8434fd1f78decb09a4c84aaa'
            'SKIP'
            'f3f856a5006ae7d2bbc2d9a338ca5ae25b6fba19eebee3ba20892845aafa7987'
            '33f462ecbb4688a5015a7cd507918e96ab933059c9a40fb875a11819596f68d1'
            '6f4db1ebf91dfb5beeb315307c6a9d19594db7d9ff0dfbac3528f4670d206211'
            'e49b9d1c12c5152202bd279e9e5a21c47cd686a68c16b29cfae9aa8e15e134c3'
            'c79dac77a92a141f5099e14a6bdf679933514d5a6031a8cc5ae39019ab948fa7'
            '9d89f3532e45831f9f1c4233deaa4ec566f14556ede10e34fc4cf6299ddd6a31'
            'SKIP'
            'f0d1846073e7c8043750461af379a81e6498ebd38968f3fc5a8a996c61054fec'
            'd616171229a90dcfbf702177537105241813f0bf2cbbc3c0d7da4476a65a74bb'
            'SKIP'
            '2cabf75033450e45dc2fe5bbb1a3d30eb4c4d04acdf5d854fdeca0f90460ea62'
            'b8b107aae1eb98c0708f79dc72ffd6b78e33ffe9f0574ff661bc2857ed0f80d1'
            '9340df8c64b917773d2da54e7a24f5b0e9418834326c0df7b851e945859cbef3'
            '8e64c7f8963355ec0bd2744bed62890cec8f1e7e8728a6a78dc25f83ddbd8dfe')

build() {
    ## build luatex binary
    cd luatex

    # set our own TEXMFCNF value
    sed -i '1i TEXMFCNF={$XDG_CONFIG_HOME,~/.config,/etc}/lltex;$SELFAUTODIR/share/lltex/web2c' source/texk/kpathsea/texmf.cnf

    ./build.sh --tlopt=--with-banner-add=/lltex
    cd -
    cp luatex/build/texk/web2c/luatex luatex-bin

    ## build language.dat.lua and helper files

    # extract language information to language.def and language.dat.lua
    awk -f extract-language-data.awk tex-hyphen/TL/tlpkg/tlpsrc/*.tlpsrc

    # delete comments and empty lines from .map file, prepare .tfm, .pfb file names
    sed -e 's/%.*//' -e '/^$/d' pdftex.map > pdftex.map.tmp
    awk '{printf "%s.tfm\n", $1}' pdftex.map.tmp > tfm_files
    # duplicities are removed, because some pfb files are listed multiple times
    awk -F'[[:blank:]]|<' '{print $NF}' pdftex.map.tmp | sort -u > pfb_files
}

package() {
    texmf="$pkgdir/usr/share/$pkgname"

    # install luatex packages needed by both plain luatex and optex
    install -Dm644 tex-hyphen/hyph-utf8/tex/generic/hyph-utf8/patterns/txt/* -t "$texmf/tex/hyph-utf8"
    install -Dm644 unicode-data/{CaseFolding.txt,load-unicode-data.tex,PropList.txt,ScriptExtensions.txt,Scripts.txt,UnicodeData.txt} -t "$texmf/tex/unicode-data"
    install -Dm644 tex/luatex/lualibs/*.lua -t "$texmf/tex/lualibs"
    install -Dm644 tex/latex/base/ltluatex.{lua,tex} -t "$texmf/tex/latex"
    install -Dm644 luaotfload/*.{lua,sty} -t "$texmf/tex/luaotfload"
    install -Dm644 tex/luatex/luamplib/*.{lua,sty} -t "$texmf/tex/luamplib"
    install -Dm644 base/*.mp -t "$texmf/metapost"
    install -Dm644 tex-hyphen/hyph-utf8/tex/luatex/hyph-utf8/luatex-hyphen.lua -t "$texmf/tex/hyph-utf8"

    # install pdftex.map and needed .enc files
    install -Dm644 pdftex.map -t "$texmf/fonts/map"
    install -Dm644 lm/fonts/enc/dvips/lm/lm-ec.enc -t "$texmf/fonts/enc"
    install -Dm644 cm-super/dvips/cm-super-t1.enc -t "$texmf/fonts/enc"
    # language.dat.lua is needed at run time, language.def is needed only by
    # etex.src at luatex plain format creation
    install -Dm644 language.dat.lua -t "$texmf/tex/lltex"

    # find needed .tfm, .pfb files, and copy them
    install -dm755 "$texmf/fonts/"{tfm,type1}
    xargs -a tfm_files -Ifile find -name file -print -quit | xargs install -Dm644 -t "$texmf/fonts/tfm"
    xargs -a pfb_files -Ifile find -name file -print -quit | xargs install -Dm644 -t "$texmf/fonts/type1"

    # need etex.src from depths of hyph-utf8
    cp tex-hyphen/hyph-utf8/tex/luatex/hyph-utf8/etex.src .

    # install optex files
    install -Dm644 optex/{base,pkg}/*.opm -t "$texmf/tex/optex"
    install -Dm644 lipsum/lipsum.ltd.tex -t "$texmf/tex/lipsum"

    export TEXMF="{$texmf,$_TEXMFMAIN}"
    export TEXMFCNF=.

    # run iniluatex to create format files
    env TEXMFDOTDIR=".,tex-ini-files,config,etex,lib,unicode-data" ./luatex-bin -ini tex-ini-files/luatex.ini
    env TEXMFDOTDIR=".,lib" ./luatex-bin -ini optex/base/optex.ini

    # install format files
    install -Dm644 *.fmt -t "$texmf/web2c"

    # install luatex binary and link optex to it
    install -Dm755 luatex-bin "$pkgdir/usr/bin/luatex"
    ln -s luatex "$pkgdir/usr/bin/optex"

    # install configuration file
    install -Dm644 texmf.cnf "$pkgdir/usr/share/lltex/web2c/texmf.cnf"
}
