
delimiters ();

% redefine some constants to work with the new numerical engines
numeric mm, cm, pt, pc, dd, cc;
pc = 12 pt; cc = 12 dd; cm = 10 mm;
803 pt = 800; 127 mm = 360; 1157 dd = 1238 pt;
eps := 1/2048; infinity := 64*64-epsilon;

message "Loading the minim extension macros";

% interaction with tex
vardef baseline expr o =
    fill if numeric o : (0,o) else: o fi
        -- cycle withprescript "BASELINE:"; enddef;
vardef boxresource expr nr = image(
    fill unitsquare withprescript "BOXRESOURCE:" & decimal nr ;
    setbounds currentpicture to unitsquare transformed runscript
        ("return { 'box_size', tex.getboxresourcedimensions(" & decimal nr & ") }");
    ) enddef;

primarydef t infont f = image( runscript(
    "return require('minim-mp').infont("&ditto&t&ditto&", "
    &if numeric f: decimal(f) else: ditto&f&ditto fi&")" ) ) enddef;

% even-odd rule
def nofill expr c = fill c withprescript "OTYPE:nofill" enddef;
def eofill expr c = fill c withprescript "OTYPE:eofill" enddef;
def eofilldraw expr c = filldraw c withprescript "OTYPE:eofilldraw" enddef;

def multidraw (text paths) text opts = draw image(
    for p = paths: ; nofill p opts endfor
    withprescript "OTYPE:outline";) enddef;
def multifill (text paths) text opts = draw image(
    for p = paths: ; nofill p opts endfor
    withprescript "OTYPE:fill";) enddef;
def multifilldraw (text paths) text opts = draw image(
    for p = paths: ; nofill p opts endfor
    withprescript "OTYPE:filldraw";) enddef;
def multieofill (text paths) text opts = draw image(
    for p = paths: ; nofill p opts endfor
    withprescript "OTYPE:eofill";) enddef;
def multieofilldraw (text paths) text opts = draw image(
    for p = paths: ; nofill p opts endfor
    withprescript "OTYPE:eofilldraw";) enddef;

vardef clipto text t =
    clip currentpicture to bbox currentpicture
        for c = t: -- c -- cycle endfor -- cycle enddef;
vardef clipout text t =
    clip currentpicture to
        for c = t: c -- cycle -- endfor cycle enddef;

vardef glyph expr c of f = image(for p =
    runscript("return require('minim-mp').get_"
    &if string c: "named_glyph("&ditto&c&ditto
    else: "glyph("& decimal c fi &", "
    &if numeric f: decimal(f) else: ditto&f&ditto fi
    & ")" ) : ; nofill p endfor
    withprescript "OTYPE:fill"; ) enddef;

def contours expr t of f =
    runscript("return require('minim-mp').get_contours("&ditto&t&ditto&", "
    &if numeric f: decimal(f) else: ditto&f&ditto fi& ")" ) enddef;

% interaction with lua
vardef hexadecimal expr n =
    % TODO: support other number systems
    save d, a, m; a = ASCII("a"); m := abs n;
    if n < 0: "-0x" else: "0x" fi
    for i = 1 upto 7: &
        hide(d := floor m div 256; m := 16(m - 256d);)
        if d < 10: decimal d else: char(a+d-10) fi
        if i = 3: & "." fi
    endfor enddef;
vardef scaledpoints expr n =
    % use the fact that 800bp = 803pt
    save a, m; m := abs n;
    a1 = m div (1025/1024); % 1025/1024 = 800epsilon * 82
    m := m mod (1025/1024);
    a2 = m div 800epsilon;  % max 82
    m := (m mod 800epsilon) div epsilon;
    a3 = floor(m*803/800 + 1/2);
    if n < 0: "-(" else: "(" fi
        & decimal(a1) & "*803*82 + "
        & decimal(a2) & "*803 + "
        & decimal(a3) & ")" enddef;

% reporting
def debug_pdf = runscript
    ("require('minim-mp').enable_debugging()") enddef;
def texmessage expr msg = runscript
    ("texio.write_nl("&ditto&msg&ditto&")") enddef;

% patterns
def withpattern(suffix s) = withprescript
    ("fillpattern: " & decimal(_patterns_.s)) enddef;
def beginpattern(suffix s) =
    begingroup clearxy; clearit;
    interim defaultcolormodel:=1;
    charcode:=incr _patterns_._last_;
    _patterns_.s:=charcode; drawoptions();
    pickup pencircle scaled 0.4pt;
    save painttype; painttype:=2;
    save _withcolor; let _withcolor = withcolor; save withcolor;
    def withcolor = hide(painttype:=1) _withcolor enddef;
    save matrix; transform matrix; enddef;
def endpattern (expr xstep, ystep) =
    if unknown matrix : matrix:=identity; fi
    special "definepattern:" for e = charcode, tilingtype, painttype,
        xstep, ystep, xxpart matrix, xypart matrix, yxpart matrix, yypart matrix:
        & " " & decimal(e) endfor;
    shipit; endgroup enddef;
newinternal tilingtype; tilingtype:=1;
_patterns_._last_ := 0;

% shorthands
primarydef p xshifted x = p shifted (x,0) enddef;
primarydef p yshifted y = p shifted (0,y) enddef;

% reverse paths to allow „p & vflip p”
def hflip primary p = if path p: reverse fi p xscaled -1 enddef;
def vflip primary p = if path p: reverse fi p yscaled -1 enddef;

% missing definitions
path fullsquare, unitcircle ;
fullsquare := unitsquare shifted - center unitsquare ;
unitcircle := fullcircle shifted urcorner fullcircle ;

% complement counterclockwise
vardef clockwise primary c =
    if turningnumber c > 0: reverse fi c enddef;

% cmyk colours
cmykcolor cyan, magenta, yellow, key;
cyan    = (1,0,0,0);
magenta = (0,1,0,0);
yellow  = (0,0,1,0);
key     = (0,0,0,1);

% constants
pi := 355/113;


