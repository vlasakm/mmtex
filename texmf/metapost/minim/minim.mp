
if known minim.mp:
    message "skipping: already read";
    expandafter endinput fi
minim.mp := 1.3;

% This file only contains code that is not specific to the minim metapost 
% processor. See minim-mp.mp for the wireup of minim-mp’s extensions.

message "Loading general minim extension macros";

% redefine some constants to work with the new numerical engines
numeric mm, cm, pt, pc, dd, cc;
pc = 12 pt; cc = 12 dd; cm = 10 mm;
803 pt = 800; 127 mm = 360; 1157 dd = 1238 pt;
eps := 1/2048; infinity := 64*64-epsilon;

% constants
pi := 355/113;

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

% clipping
vardef clipto text t =
    clip currentpicture to bbox currentpicture
        for c = t: -- c -- cycle endfor -- cycle enddef;
vardef clipout text t =
    clip currentpicture to
        for c = t: c -- cycle -- endfor cycle enddef;

% cmyk colours
cmykcolor cyan, magenta, yellow, key;
cyan    = (1,0,0,0);
magenta = (0,1,0,0);
yellow  = (0,0,1,0);
key     = (0,0,0,1);

% also in minim-mp.mp
if unknown rgb_to_gray red:
    vardef rgb_to_gray expr c =
        0.2126*redpart c + 0.7152*greenpart c + 0.0722*bluepart c
    enddef;
fi

% shorthands
def save_pen       text t = save t; pen       t; enddef;
def save_pair      text t = save t; pair      t; enddef;
def save_path      text t = save t; path      t; enddef;
def save_color     text t = save t; color     t; enddef;
def save_cmykcolor text t = save t; cmykcolor t; enddef;
def save_transform text t = save t; transform t; enddef;
def save_picture   text t = save t; picture   t; enddef;
def save_boolean   text t = save t; boolean   t; enddef;
def save_string    text t = save t; string    t; enddef;

% missing trigonometric functions
vardef tand    primary x = sind(x)/cosd(x) enddef;
vardef arcsind primary x = angle((1+-+x, x)) enddef;
vardef arccosd primary x = angle((x, 1+-+x)) enddef;
vardef arctand primary x = angle(1, x) enddef;

% segments of the circle (counterclockwise)
vardef arc (expr thetafrom, thetalen) =
    save n, d, l, theta; save_path a; save_pair p, c;
    n = ceiling(thetalen / 45); % number of segments (45° is max segment length)
    d = thetalen / n;           % angle of each segment
    l = 4/3 * tand(d/4);        % length of control points
    theta := thetafrom;
    p := (cosd theta, sind theta);
    c := l * (-sind theta, cosd theta);
    a := p for _ = 1 upto n:
        .. controls (p + c)
        hide(theta := theta + d;
            p := (cosd theta, sind theta);
            c := l * (-sind theta, cosd theta);)
        and (p - c) .. p
    endfor; a enddef;

