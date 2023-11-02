
delimiters ();

% This file is specific to the minim metapost processor (minim-mp) and cannot 
% be used with luaotfload or other metapost implementations. See minim.mp for 
% general-purpose extensions.

message "Setting up the minim MetaPost extensions";

def save_picture   text t = save t; picture   t; enddef;
def save_boolean   text t = save t; boolean   t; enddef;
def save_string    text t = save t; string    t; enddef;

% 1 lua scripts, functions and variables

def luafunction = gobble inner_luafunction enddef;
vardef inner_luafunction @# (text args) = endgroup
    % we remove the grouping so that the function may return any fragment of 
    % lua code, in particular lists to-be-parsed as text parameters
    runscript ("return " & (str @#) & build_lua_arguments(args))
    gobble begingroup enddef;

vardef build_lua_arguments (text args) =
    save_boolean first; first = true;
    "(" for a = args:
        & if first: hide(first:=false) "" else: "," fi
        & (quote_for_lua a)
    endfor & ")"
enddef;

vardef luavariable @# =
    runscript ("return quote("&(str @#)&")") enddef;
vardef setluavariable @# expr val=
    runscript ((str @#)&" = "&quote_for_lua(val)) enddef;

% quoting expressions for lua

vardef lua_string(expr s) =
    runscript ("[[quote_for_lua]]"&s) enddef;

vardef hexadecimal expr n =
    % TODO: support other number systems
    save d, a, m; a = ASCII("a"); m := abs n;
    save_string res; res =
    if n < 0: "-0x" else: "0x" fi
    for i = 1 upto 7: &
        hide(d := floor m div 256; m := 16(m - 256d);)
        if d < 10: decimal d else: char(a+d-10) fi
        if i = 3: & "." fi
    endfor; res enddef;

vardef scaledpoints expr n =
    % use the fact that 800bp = 803pt
    save a, m; m := abs n;
    a1 = m div (1025/1024); % 1025/1024 = 800epsilon * 82
    m := m mod (1025/1024);
    a2 = m div 800epsilon;  % max 82
    m := (m mod 800epsilon) div epsilon;
    a3 = floor(m*803/800 + 1/2);
    save_string res; res =
    if n < 0: "-(" else: "(" fi
        & decimal(a1) & "*803*82 + "
        & decimal(a2) & "*803 + "
        & decimal(a3) & ")";
    res enddef;

vardef quote_for_lua expr a =
    save_string res; res =
    if string a:
        lua_string(a)
    elseif numeric a:
        hexadecimal(a)
    elseif pair a:
        "{"&hexadecimal(xpart a) &
        ","&hexadecimal(ypart a) & "}"
    elseif boolean a:
        if a: "true" else: "false" fi
    elseif color a:
        "{"&hexadecimal(redpart a) &
        ","&hexadecimal(greenpart a) &
        ","&hexadecimal(bluepart a) & "}"
    elseif cmykcolor a:
        "{"&hexadecimal(cyanpart a) &
        ","&hexadecimal(magentapart a) &
        ","&hexadecimal(yellowpart a) &
        ","&hexadecimal(blackpart a) & "}"
    elseif pen a:
        hide(errmessage("I cannot pass a pen value to lua");)
        "nil"
    elseif transform a:
        hide(errmessage("I cannot pass a transform value to lua");)
        "nil"
    elseif picture a:
        hide(errmessage("I cannot pass a picture value to lua");)
        "nil"
    else: % probably intentionally vacuous, which is fine
        "nil"
    fi; res enddef;

% tex registers

string _SUFFIX_HACK_[];
vardef index_or_suffix (suffix s) =
    save_string res; res =
    if string _SUFFIX_HACK_ s: % this is a number
        "["&decimal(s)&"]"
    else: % this is a suffix
        "."&(str s)
    fi ; res enddef;

vardef tex.count @# =
    runscript ("return tex.count" & index_or_suffix(@#)) enddef;
vardef tex.attribute @# =
    runscript ("return tex.attribute" & index_or_suffix(@#)) enddef;
vardef tex.dimen @# =
    runscript ("return sp_to_pt(tex.dimen" & index_or_suffix(@#) & ")") enddef;
vardef tex.toks @# =
    runscript ("return quote(tex.toks" & index_or_suffix(@#) & ")") enddef;

vardef set tex.count @# expr val =
    runscript ("tex.count" & index_or_suffix(@#) & " = " & decimal(val)) enddef;
vardef set tex.attribute @# expr val =
    runscript ("tex.attribute" & index_or_suffix(@#) & " = " & decimal(val)) enddef;
vardef set tex.dimen @# expr val =
    runscript ("tex.dimen" & index_or_suffix(@#) & " = " & scaledpoints(val)) enddef;
vardef set tex.toks @# expr val =
    runscript ("tex.toks" & index_or_suffix(@#) & " = " & lua_string(val)) enddef;

% 1 typesetting

let textext = maketext;
let TEX = maketext;

% baseline pair or numeric -> fill statement
vardef baseline expr o =
    fill if numeric o : (0,o) else: o fi
        -- cycle withprescript "BASELINE:"; enddef;

% boxresource number -> fill statement + setbounds
vardef boxresource expr nr = image(
    fill unitsquare withprescript "BOXRESOURCE:" & decimal nr ;
    setbounds currentpicture to unitsquare transformed runscript
        ("return { 'box_size', tex.getboxresourcedimensions(" & decimal nr & ") }");
    ) enddef;

% actual typesetting

primarydef t infont f = image( luafunction minim_infont (t, f); ) enddef;

def glyph expr c of f = luafunction get_glyph (c, f) enddef;

def contours expr t of f = luafunction get_contours (t, f) enddef;

% labels can optionally be typeset with maketext
% and the default font must be set explicitly
string defaultfont;
boolean maketextlabels;
maketextlabels := true;
vardef thelabel@#(expr s,z) =  % Position s near z
  save_picture p;
  p = if     picture s         : s
      elseif maketextlabels    : maketext s
      elseif known defaultfont : s infont defaultfont
      else                     : s infont luafunction font.current()
      fi;
  p shifted (z + labeloffset*laboff@# -
     (labxf@#*lrcorner p + labyf@#*ulcorner p
       + (1-labxf@#-labyf@#)*llcorner p
  )  ) enddef;

% 1 even-odd rule and multidraw

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

% 1 patterns

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


% 1 miscellaneous

vardef debug_pdf = luafunction enable_debugging () enddef;

def texmessage text msg = luafunction texio.write_nl (msg) enddef;

vardef rgb_to_gray expr c =
    luafunction rgb_to_gray (redpart c, greenpart c, bluepart c)
enddef;

% 
