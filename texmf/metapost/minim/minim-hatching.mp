
%% To be used with the minim-mp metapost processor. See minim-hatching-doc.mp 
%% for an overview of the patterns defined below.


% 1 definition macros

def new_linepattern(suffix name)(expr sep, rot) =
    beginpattern(name)
        draw origin -- (100,0);
        matrix = identity rotated rot;
        setbounds currentpicture to unitsquare xscaled 100 yscaled 2 shifted (0, -1);
    endpattern(100, sep);
enddef;

def new_dotpattern(suffix name)(expr r, sep, rot) =
    beginpattern(name)
        drawdot origin withpen pencircle scaled r;
        matrix = identity rotated rot;
        setbounds currentpicture to bbox currentpicture;
    endpattern(sep,sep);
enddef;

def new_hexdotpattern(suffix name)(expr r, sep) =
    beginpattern(name)
        pickup pencircle scaled r;
        drawdot origin; drawdot (sep, sep/sqrt(3));
        setbounds currentpicture to bbox currentpicture;
    endpattern(2sep,2sep/sqrt(3));
enddef;

def new_brokenlinepattern(suffix name)(expr sep, on, off) =
    beginpattern(name)
        draw (0,0) -- (on,0);
        draw (on/2+off/2,sep) -- (3on/2+off/2,sep);
        setbounds currentpicture to bbox currentpicture;
    endpattern(on+off,2sep);
enddef;

def new_distortedgridpattern(suffix name)(expr sep, rot, x, y) =
    beginpattern(name)
        draw (0, sep/2) -- (sep, sep/2);
        draw (sep/2, 0) -- (sep/2, sep);
        matrix = identity xscaled x yscaled y rotated rot;
        setbounds currentpicture to unitsquare scaled sep;
    endpattern(sep,sep);
enddef;
def new_gridpattern(suffix name)(expr sep, rot) =
    new_distortedgridpattern(name)(sep, rot, 1, 1) enddef;

def new_weavepattern(suffix name)(expr sep, width) =
    beginpattern(name)
        matrix = identity rotated 45;
        draw (0,-width)--(0,width);
        draw (-width,sep)--(width,sep);
        draw (sep-width,0)--(sep+width,0);
        draw (sep,sep-width)--(sep,sep+width);
    endpattern(2sep,2sep); enddef;

def new_hexpattern(suffix name)(expr d) =
    beginpattern(name)
        save v,w; w:=d/2; v := w/sqrt(3); draw (w,4v) -- (w,6v);
        draw (0,v) -- (w,0) -- (2w,v) -- (2w,3v) -- (w,4v) -- (0,3v);
        setbounds currentpicture to unitsquare xscaled 3w yscaled 6v shifted linecorr;
    endpattern(2w,6v); enddef;

def new_circlepattern(suffix name)(expr d) =
    beginpattern(name)
        draw fullcircle scaled d;
        draw fullcircle scaled d shifted (sqrt(3)/2*d,d/2);
    endpattern(sqrt(3)*d,d); enddef;

def new_scalepattern(suffix name)(expr d) =
    beginpattern(name)
        draw halfcircle scaled d rotated 180;
        draw halfcircle scaled d rotated 180 shifted (d/2,d/2);
    endpattern(d,d); enddef;

def new_squarecirclepattern(suffix name)(expr d) =
    beginpattern(name)
        draw fullcircle scaled d;
        setbounds currentpicture to unitsquare shifted -(1/2,1/2) scaled 2d;
    endpattern(d,d); enddef;


% 1 predefined patterns

if known skip_predefined_patterns : expandafter endinput fi;

begingroup save xl, l, s;
2l = 3s; 2xl = 3l; s = 3.5;

save linecorr; pair linecorr; linecorr = -(.2pt, .2pt);

begingroup
    save horizontal, vertical, upward, downward, diagonal;
    horizontal = 0; vertical = 90; diagonal = 45;
    downward = 30; downward = -upward;
    forsuffixes d = horizontal, vertical, upward, downward :
        new_linepattern(d lines)(l, d);
        new_linepattern(dense d lines)(s, d);
    endfor

    new_brokenlinepattern(broken lines)(l, 2l, l)
    new_brokenlinepattern(dense broken lines)(s, 3s, s)

    forsuffixes d = diagonal, upward, downward :
        new_gridpattern(d grid)(l, d);
        new_gridpattern(dense d grid)(s, d);
    endfor
endgroup;

new_gridpattern(grid)(l, 0)
new_gridpattern(dense grid)(s, 0)

new_distortedgridpattern(horizontal grid)(l, 45, 3/2, 1);
new_distortedgridpattern(vertical grid)(l, 45, 1, 3/2);
new_distortedgridpattern(dense horizontal grid)(s, 45, 3/2, 1);
new_distortedgridpattern(dense vertical grid)(s, 45, 1, 3/2);

new_weavepattern(stitches)(l, 3/2)
new_weavepattern(weave)(l, 3)
new_weavepattern(dense weave)(s, 3/2)

beginpattern(horizontal zigzag)
    draw (0,0)--(l,2/3l)--(2l,0);
    setbounds currentpicture to unitsquare xscaled 2l yscaled l shifted -(0,l/6);
endpattern(2l,l);
beginpattern(vertical zigzag)
    draw (0,0)--(2/3l,l)--(0,2l);
    setbounds currentpicture to unitsquare xscaled l yscaled 2l shifted -(l/6,0);
endpattern(l,2l);

beginpattern(crosses)
    matrix = identity rotated 45;
    save c,o,w; pair c,o; c=(l/2,l/2); w=4/5;
    o:=(w, w); draw (c+o)--(c-o);
    o:=(w,-w); draw (c+o)--(c-o);
    setbounds currentpicture to unitsquare scaled l;
endpattern(l,l);

beginpattern(bricks)
    draw (0,l)--(0,0)--(2l,0);
    draw (l,2l)--(l,l)--(3l,l);
    clip currentpicture to unitsquare xscaled 3l yscaled 2l shifted linecorr;
endpattern(2l,2l);

beginpattern(tiles)
    save s; s:=l/4;
    draw (0,l+s) -- (l+s,l+s);
    draw (l-s,0) -- (l-s,l+s);
    draw currentpicture rotatedaround((l,l), 180);
    draw (0,2l) -- (0,0) -- (2l,0);
    clip currentpicture to unitsquare xscaled 2l yscaled 2l shifted linecorr;
    matrix := identity rotated 45;
endpattern(2l,2l);

beginpattern(chords)
    save c,d; c:=2.1; d:=1.4;
    draw (c-d,c-d){dir 225}..{dir -30}(2c-d/2,d/2-2c);
    draw (2c+d,-d-2c){dir -45}..{dir 210}(c+d/2,d/2-5c);
    setbounds currentpicture to bbox currentpicture;
endpattern(7c, 2c);

beginpattern(tea cloth)
    save r; r:=xl/8; pickup pencircle scaled r;
    drawdot (xl/2,xl/2); drawdot (0,0);
    for i = 1 upto 3 : drawdot (0,i*xl/4); drawdot (i*xl/4,0); endfor
endpattern(xl,xl);

beginpattern(knit)
    save v; v:=2/3xl;
    draw (0,0) -- (0,v);
    draw (-xl/2,3/2v) -- (-xl/2,v/2) {dir -60}..{dir -60} (0,0) {dir 60}..{dir 60} (xl/2,v/2);
endpattern(xl,v);

beginpattern(purl)
    save v; v := 2/3xl;
    interim linecap:=butt;
    draw (0,0) -- (0,v) {dir 30}..{dir 30} (xl/2,3/2v) {dir -30}..{dir -30} (xl,v);
    draw (xl/2,v/2) {dir -30}..{dir -30} (xl,0) {dir 30}..{dir 30} (3/2xl,v/2) -- (3/2xl,-v/2);
endpattern(xl,2v);

new_hexpattern(hexagons)(xl);
new_hexpattern(small hexagons)(l);

new_squarecirclepattern(square circles)(xl);
new_squarecirclepattern(small square circles)(l);

new_circlepattern(circles)(xl);
new_circlepattern(small circles)(l);

new_scalepattern(scales)(xl);
new_scalepattern(small scales)(l);

save dot;
dot := 1.2pt;
new_hexdotpattern(dots)(dot, l);
new_hexdotpattern(dense dots)(dot, s);
new_hexdotpattern(sparse dots)(dot, xl);
new_dotpattern(square dots)(dot, l, 0);
new_dotpattern(diamond dots)(dot, l, 45);
new_dotpattern(dense square dots)(dot, s, 0);
new_dotpattern(dense diamond dots)(dot, s, 45);
new_dotpattern(sparse square dots)(dot, xl, 0);
new_dotpattern(sparse diamond dots)(dot, xl, 45);
dot := 1.8pt;
new_hexdotpattern(heavy dots)(dot, l);
new_hexdotpattern(dense heavy dots)(dot, s);
new_hexdotpattern(sparse heavy dots)(dot, xl);
new_dotpattern(square heavy dots)(dot, l, 0);
new_dotpattern(diamond heavy dots)(dot, l, 45);
new_dotpattern(dense square heavy dots)(dot, s, 0);
new_dotpattern(dense diamond heavy dots)(dot, s, 45);
new_dotpattern(sparse square heavy dots)(dot, xl, 0);
new_dotpattern(sparse diamond heavy dots)(dot, xl, 45);

endgroup;

% 

endinput;

