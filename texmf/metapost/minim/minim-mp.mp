
delimiters ();

% This file is specific to the minim metapost processor (minim-mp) and cannot 
% be used with luamplib or other metapost implementations. See minim.mp for 
% general-purpose extensions.

message "Setting up the minim MetaPost extensions";

% 1 lua scripts and functions

def luafunction = gobble inner_luafunction enddef;
vardef inner_luafunction @# (text args) = endgroup
    % we remove the grouping so that the function may return any fragment of 
    % metapost code, in particular lists to-be-parsed as text parameters
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

vardef hexadecimal tertiary n =
    % TODO: support other number systems
    save d, a, m; a = ASCII("a"); m := abs n;
    save_string res; res =
    if n < 0: "-0x" else: "0x" fi
    for i = 1 upto 7: &
        hide(d := floor m div 256; m := 16(m - 256d);)
        if d < 10: decimal d else: char(a+d-10) fi
        if i = 3: & "." fi
    endfor; res enddef;

vardef scaledpoints tertiary n =
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

vardef quote_for_lua tertiary a =
    save_string res; res =
    if string a:
        lua_string(a)
    elseif numeric a:
        hexadecimal(a)
    elseif pair a:
        "{"& (hexadecimal xpart a) &
        ","& (hexadecimal ypart a) & "}"
    elseif boolean a:
        if a: "true" else: "false" fi
    elseif color a:
        "{"& (hexadecimal redpart a) &
        ","& (hexadecimal greenpart a) &
        ","& (hexadecimal bluepart a) & "}"
    elseif cmykcolor a:
        "{"& (hexadecimal cyanpart a) &
        ","& (hexadecimal magentapart a) &
        ","& (hexadecimal yellowpart a) &
        ","& (hexadecimal blackpart a) & "}"
    elseif transform a:
        "{"& (hexadecimal xxpart a) &
        ","& (hexadecimal xypart a) &
        ","& (hexadecimal yxpart a) &
        ","& (hexadecimal yypart a) &
        ","& (hexadecimal xpart a) &
        ","& (hexadecimal ypart a) & "}"
    elseif pen a:
        hide(errmessage("I cannot pass a pen value to lua");)
        "nil"
    elseif picture a:
        hide(errmessage("I cannot pass a picture value to lua");)
        "nil"
    else: % probably intentionally vacuous, which is fine
        "nil"
    fi; res enddef;

% constructing lua tables

def make_lua_dict (text t) = begingroup
    % Note that though the argument may contain = signs and commas, the rest of 
    % the arguments must consist of suffixes.
    save_boolean first; first := true;
    "{ " forsuffixes kv =
        hide(let = _EQ_ undefined)
        t hide(let = _EQ_ _EQ_) : &
        if first: hide(first := false;) else: ", "& fi
        begingroup make_lua_keyval kv endgroup
    endfor & " }" endgroup
enddef;
let _EQ_ = =;

vardef make_lua_keyval @# expr e =
    (str @#) & " = " & quote_for_lua e
enddef;

% 1 tex registers

string _SUFFIX_HACK_[];
vardef index_or_suffix (suffix s) =
    save_string res; res =
    if string _SUFFIX_HACK_ s: % s is a number
        "["&decimal(s)&"]"
    else: % s is a suffix
        "."&(str s)
    fi ; res enddef;

vardef tex.count @# =
    runscript ("return tex.count" & index_or_suffix(@#)) enddef;
vardef tex.attribute @# =
    runscript ("return tex.attribute" & index_or_suffix(@#)) enddef;
vardef tex.dimen @# =
    runscript ("return sp_to_pt(tex.dimen" & index_or_suffix(@#) & ")") enddef;
vardef tex.skip @# =
    runscript ("return sp_to_pt(tex.skip" & index_or_suffix(@#) & ".width)") enddef;
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

boolean debug_tex_bboxes;
debug_tex_bboxes := false;

let textext = maketext;
let TEX = maketext;

def _set_maketext_result_ (expr nr)(text tr) = image (
    fill unitsquare withprescript "TEXBOX:"&decimal nr;
    save_path bb; bb := unitsquare transformed tr;
    if debug_tex_bboxes: draw bb dashed evenly; fi
    setbounds currentpicture to bb;) enddef;

% baseline pair or numeric -> fill statement
vardef baseline expr o =
    fill if numeric o : (0,o) else: o fi
        -- cycle withprescript "BASELINE:"; enddef;

vardef find_baseline expr p =
    save_pair bl, ibl;
    for c within p:
        if clipped c or bounded c:
            ibl := find_baseline c;
            if known ibl: bl := ibl; fi
        elseif "BASELINE:" = substring (0,9) of prescriptpart c:
            bl := point 0 of pathpart c;
        fi
    endfor bl enddef;

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

% 1 box resources (xforms)

% boxresource number -> fill statement + setbounds
vardef boxresource primary nr = image(
    fill unitsquare withprescript "BOXRESOURCE:" & decimal nr ;
    save btf; transform btf;
    btf = luafunction get_boxresource_dimensions (nr);
    save_path bb; bb = unitsquare transformed btf;
    if debug_tex_bboxes: draw bb dashed evenly; fi
    setbounds currentpicture to bb;
    currentpicture := currentpicture
        shifted luafunction get_boxresource_center (nr);
    ) enddef;

% id = saveboxresource (attributes) image ( ... );
vardef saveboxresource (text attrs) expr p =
    save id; id = luafunction reserve_xform_id();
    % save the dimensions
    save t, o; transform t; pair o;
    (0,0) transformed t = llcorner p;
    (1,0) transformed t = lrcorner p;
    (0,1) transformed t = ulcorner p;
    save bl; bl = -ypart find_baseline p;
    o = (-xpart llcorner p, if known bl: bl else: 0 fi);
    luafunction set_boxresource_dimensions (id, t shifted o, -o);
    % shipout the xform
    shipout image(draw p;
        special "XFORMATTRS:" & make_lua_dict (attrs);
        special "XFORMINDEX:" & decimal id;
    ); id enddef;

% 1 extended graphics state

vardef modify_scripts text t =
    % Note: this is a no-op when the picture is empty
    save_picture curr;
    save_string pre, post;
    % extract script parts
    curr := image(drawdot origin t;);
    pre = prescriptpart curr;
    post = postscriptpart curr;
    % add the prescript
    if pre <> "":
        curr := currentpicture; clearit;
        draw curr withprescript pre;
    fi
    % add the postscript
    if post <> "":
        % here we find the reason for this routine: metapost *should* apply the 
        % postscript to the last element of a picture, but chooses the first 
        % instead.
        curr := currentpicture; clearit;
        setbounds curr to llcorner curr -- lrcorner curr --
            urcorner curr -- ulcorner curr -- cycle;
        % these bounds force an extra nesting level of the next function
        draw with_postscript_to_last(curr, post);
    fi
enddef;

vardef with_postscript_to_last (expr p, script) =
    image( save i; i := 0;
    for c within p:
        if incr i < length(p): draw c;
        elseif clipped c:
            save_picture q; q:= with_postscript_to_last(c, script);
            clip q to pathpart c;
            addto currentpicture also q;
        elseif bounded c:
            save_picture q; q:= with_postscript_to_last(c, script);
            setbounds q to pathpart c;
            addto currentpicture also q;
        else:
            draw c withpostscript script;
        fi
    endfor) enddef;

def append_postscript expr s =
    if length(currentpicture) = 0: special s;
    else: modify_scripts withpostscript s;
    fi enddef;

def savegstate =
    append_postscript "gstate:save"; enddef;
def restoregstate =
    append_postscript "gstate:restore"; enddef;
def setgstate =
    append_postscript "extgstate:" & make_lua_dict enddef;

def withgstate (text t) =
    withprescript "extgstate:" & make_lua_dict (t)
    withprescript "gstate:save"
    withpostscript "gstate:restore" enddef;

% 1 transparency

newinternal string blend_mode;
newinternal string transparency_group_attrs;

% setalpha (α)
vardef setalpha expr alpha =
    save a; a = alpha;
    save_string bm; bm = "/" & blend_mode;
    setgstate(CA=a, ca=a if bm <> "/":, BM=bm fi) enddef;

% <drawing_cmd> withalpha (α)
def withalpha = gobble _withalpha_ enddef;
string _blend_mode_;
vardef _withalpha_ (expr alpha) =
    _with_alpha_ := alpha;
    _blend_mode_ := "/" & blend_mode;
    endgroup
    withgstate(CA=_with_alpha_,ca=_with_alpha_ if _blend_mode_ <> "/":, BM=_blend_mode_ fi)
    gobble begingroup enddef;

% transparent (α) image (...)
vardef transparent (expr alpha) expr p =
    save_string attrs; attrs = "<< /S/Transparency "&transparency_group_attrs&">>";
    save g; g = saveboxresource (Group=attrs) p;
    savegstate; setalpha (alpha);
    draw boxresource g;
    restoregstate;
enddef;

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
    modify_scripts
        withprescript "pdf:/Artifact BMC"
        withpostscript "pdf:EMC";
    if unknown matrix : matrix:=identity; fi
    special "definepattern:" for e = charcode, tilingtype, painttype,
        xstep, ystep, xxpart matrix, xypart matrix, yxpart matrix, yypart matrix:
        & " " & decimal(e) endfor;
    shipit; endgroup enddef;
newinternal tilingtype; tilingtype:=1;
_patterns_._last_ := 0;

% 1 miscellaneous

def debug_pdf = luafunction enable_debugging(); enddef;

vardef texmessage text msg = luafunction texmessage (msg) enddef;

% 
