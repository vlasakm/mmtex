
local alloc = require ('minim-alloc')
local cb = require('minim-callbacks')
local pdfres = require('minim-pdfresources')
alloc.remember ('minim-mp')

local M = { } -- module contents
local E = { } -- runscript environment
local A = { } -- postprocessing functions

--1 AUXILIARY FUNCTIONS

local GLUE_NODE = node.id 'glue'
local GLYPH_NODE = node.id 'glyph'
local KERN_NODE = node.id 'kern'
local WHATSIT_NODE = node.id 'whatsit'

local function copy_table(from, to)
    for k,v in pairs(from) do to[k] = v end
    return to
end

-- 2 state metatable

-- q Q  store/restore graphics state

-- In what follows, ‘append’ is a structure that contains a (tex) node list 
-- that will become the picture that is being constructed and an internal 
-- graphics state.
--
-- We can call append:somefunction(...) to append a node or append:somevariable 
-- to query the graphics state. These go via its metatable:

local append_meta =
{
    -- Either return an appending function or an entry in the graphics state.
    __index = function(table, key)
        return A[key] or table.state[#table.state][key]
    end,
    __newindex = function(table, key, value)
        table.state[#table.state][key] = value
    end
}

local function init_append()
    return setmetatable({
        head = false, tail = false, -- node list
        baseline = false,           -- internal state
        node_count = 0,             -- node count
        state = { },                -- graphics state variables
        user = { },                 -- user data for extensions
        object_info = { },          -- data for current object
        }, append_meta)
end

function A.node(append, nd)
    append.node_count = append.node_count + 1
    append.head, append.tail = node.insert_after(append.head or nil, append.tail or nil, nd)
end

function A.save(append)
    local st = append.state[#append.state] or { }
    append.state[#append.state+1] =
    {
        linewidth  = st.linewidth,
        miterlimit = st.miterlimit,
        linejoin   = st.linejoin,
        linecap    = st.linecap,
        dashed     = st.dashed,
        stroke     = st.stroke,
        fill       = st.fill
    }
    append:node(node.new('whatsit', 'pdf_save')) -- q
end

function A.restore(append)
    append.state[#append.state] = nil
    append:node(node.new('whatsit', 'pdf_restore')) -- Q
end

-- The following callback is executed just before the final step of surrounding 
-- the image in properly-dimensioned boxes. It receives the processed image 
-- object as argument. That object may have the following fields (which can be 
-- changed):
--     head         the head of the node list
--     name         the image name
--     user         the image user table
--     wd, ht, dp   tex dimensions
--     x0, y0       position of (0,0) w.r.t. tex dimension
--     bbox         original metapost bounding box
--     discard      whether not to save this image
cb.new_callback('finish_mpfigure', 'simple')

--2 debugging

local debugging = false

function M.enable_debugging()
    debugging = true
    pdf.setcompresslevel(0)
    pdf.setobjcompresslevel(0)
end
E.enable_debugging = M.enable_debugging

alloc.luadef('debugmetapost', M.enable_debugging)

local function debug(...)
    if debugging then
        alloc.log(...)
    end
end

local function print_prop(append, obj, prop)
    if obj[prop] then
        local val = string.gsub(tostring(obj[prop]), '\r', '<CR>')
        append:literal('%%       %s: %s', prop, val)
    end
end

local function print_multi(append, obj, prop)
    if obj[prop] then
        local x = ''
        for i = 1,#obj[prop] do
            x = x .. tostring(obj[prop][i])..' '
        end
        append:literal('%%  %s: %s', prop, x)
    end
end

local function print_knots(append, obj, ptype)
    if obj[ptype] then
        append:literal('%%    %s: see below', ptype)
        for i = 1, #obj[ptype] do
            local a,b = obj[ptype][i].left_type or 'joined', obj[ptype][i].right_type or 'joined'
            append:literal('%%       -+-   knot: %s-%s', a, b)
            append:literal('%%        | x_coord: %s', tostring(obj[ptype][i].x_coord))
            append:literal('%%        | y_coord: %s', tostring(obj[ptype][i].y_coord))
            append:literal('%%        | right_x: %s', tostring(obj[ptype][i].right_x))
            append:literal('%%        | right_y: %s', tostring(obj[ptype][i].right_y))
            append:literal('%%        |  left_x: %s', tostring(obj[ptype][i].left_x))
            append:literal('%%        |  left_y: %s', tostring(obj[ptype][i].left_y))
        end
    end
end

function A.printobj(append, obj)
    local nc = append.node_count
    append:literal('%% Object Type: %s', obj.type)
    print_prop(append, obj, 'text')
    print_prop(append, obj, 'font')
    print_prop(append, obj, 'dsize')
    print_prop(append, obj, 'width')
    print_prop(append, obj, 'height')
    print_prop(append, obj, 'depth')
    print_multi(append, obj, 'transform')
    print_multi(append, obj, 'color')
    print_knots(append, obj, 'path')
    print_knots(append, obj, 'htap')
    if obj.pen then
        local x = obj.pen.type or 'not elliptical'
        append:literal('%%     pen is %s', x)
        x = mplib.pen_info(obj)
        append:literal('%%     width: %s', tostring(x.width))
        append:literal('%%        sx: %s', tostring(x.sx))
        append:literal('%%        sy: %s', tostring(x.sy))
        append:literal('%%        rx: %s', tostring(x.rx))
        append:literal('%%        ry: %s', tostring(x.ry))
        append:literal('%%        tx: %s', tostring(x.tx))
        append:literal('%%        ty: %s', tostring(x.ty))
        print_knots(append, obj, 'pen path')
    end
    if obj.dash then
        local d = ''
        for i = 1,#obj.dash.dashes do
            d = d ..tonumber(obj.dash.dashes[i]).. ' '
        end
        append:literal('%%     dashes: %s', d)
        append:literal('%%dash offset: %s', tostring(obj.dash.offset))
    end
    print_prop(append, obj, 'prescript')
    print_prop(append, obj, 'postscript')
    print_prop(append, obj, 'miterlimit')
    print_prop(append, obj, 'linejoin')
    print_prop(append, obj, 'linecap')
    append.node_count = nc
end

--2 pdf literal helpers

local function format_numbers(...)
    return (string.format(...)
        :gsub('[.]0+ ', ' ')
        :gsub('([.][1-9]+)0+ ', '%1 ')
        :gsub(' +$', ''))
end

-- Only to be used for coordinates: ‘cm’ parameters should not be rounded.
local function pdfnum(operator, ...)
    local fmt = string.format('%%.%sf %s', pdf.getdecimaldigits(), operator)
    return format_numbers(fmt, ...)
end

local function make_pdf_dashpattern(dl)
    return string.format('[%s] %s',
        table.concat(dl.dashes or {},' '),
        pdfnum('d', dl.offset))
end

local function point_fmt(operator, ...)
    local dd = pdf.getdecimaldigits()
    local fmt = string.format('%%.%sf %%.%sf %s', dd, dd, operator)
    return format_numbers(fmt, ...)
end

local function bbox_fmt(...)
    local dd = pdf.getdecimaldigits()
    local fmt = string.format('/BBox [ %%.%sf %%.%sf %%.%sf %%.%sf ]', dd, dd, dd, dd)
    return format_numbers(fmt, ...)
end

local function curve_fmt(...)
    local dd = pdf.getdecimaldigits()
    local fmt = string.format('%%.%sf %%.%sf %%.%sf %%.%sf %%.%sf %%.%sf c', dd, dd, dd, dd, dd, dd)
    return format_numbers(fmt, ...)
end

function A.literal(append, fmt, ...)
    local lit = node.new('whatsit', 'pdf_literal')
    lit.data = fmt:format(...)
    append:node(lit)
end

--2 parsing helpers

local function parse_lua_table(name, str)
    local f, msg = load('return '..str, name, 't')
    if msg then return alloc.err(msg) end
    local t = f()
    if not t or type(t) ~= 'table' then
        return alloc.err('%s attributes must be given as lua table', name)
    end
    -- format all numbers with pdfnum
    for k, v in pairs(t) do
        if type(v) == 'number' then
            t[k] = pdfnum('', v)
        end
    end
    return t
end

--2 boxing helpers

local function make_surrounding_box(nd_id, head)
    local nd = node.new(nd_id)
    nd.dir, nd.head = 'TLT', head
    return nd
end

local function wrap_picture(head, x0, y0)
    -- Note: this does not set the image dimensions
    local horizontal = make_surrounding_box('hlist', head)
    local vertical   = make_surrounding_box('vlist', horizontal)
    local outer      = make_surrounding_box('hlist', vertical)
    vertical.shift   = -y0
    horizontal.shift = x0
    return outer
end
M.wrap_picture = wrap_picture

--2 colour conversion

local function rgb_to_gray (r,g,b)
    return ( tex.count['RtoG'] * r / 10000
           + tex.count['GtoG'] * g / 10000
           + tex.count['BtoG'] * b / 10000 )
end
E.rgb_to_gray = rgb_to_gray

local function cmyk_to_rgb (c,m,y,k)
    return (1-k)*(1-c), (1-k)*(1-m), (1-k)*(1-y)
end

local function rgb_to_cmyk (r, g, b)
    local k = 1 - math.max(r, g, b)
    if k == 1 then
        return 0, 0, 0, k
    else
        return (1-r-k)/(1-k), (1-g-k)/(1-k), (1-b-k)/(1-k), k
    end
end

local function convert_colour(cr)
    -- always write rgb or cmyk black as grayscale
    if cr[1] == 0 and cr[2] == 0 and cr[3] == 0
    and (cr[4] == 1 or not cr[4]) then
        return { 0 }
    end
    -- see if we must convert to another colour space
    local n = #cr
    local convert = tex.count['convertmpcolours']
    if convert == 1 then
        if n == 3 then
            return { rgb_to_gray(table.unpack(cr)) }
        elseif n == 4 then
            return { rgb_to_gray(cmyk_to_rgb(table.unpack(cr))) }
        end
    elseif convert == 3 and n == 4 then
        return { cmyk_to_rgb(table.unpack(cr)) }
    elseif convert == 4 and n == 3 then
        return { rgb_to_cmyk(table.unpack(cr)) }
    end
    -- otherwise return the colour unchanged
    return cr
end

--2 colour literals

-- MetaPost supports colour models with 1, 3 or 4 parameters. The corresponding 
-- pdf operators are

-- RG rg    RGB colour model for stroke/filling
-- K  k     CMYK colour model for stroke/filling
-- G  g     Grayscale colour model for stroke/filling

-- ... CS  cs   select colourspace for stroke/filling
-- ... SCN scn  select colour in colourspace for stroke/filling

-- In order to prevent duplicate colour settings, ‘append’ contains the state 
-- variables ‘stroke’ and ‘fill’ that record the last-used colour settings.

-- preload device colour pattern colour spaces
pdfres.add_resource('ColorSpace', 'PsG', { value = '[ /Pattern /DeviceGray ]' })
pdfres.add_resource('ColorSpace', 'PsRG', { value = '[ /Pattern /DeviceRGB ]' })
pdfres.add_resource('ColorSpace', 'PsK', { value = '[ /Pattern /DeviceCMYK ]' })

local colour_template = { '%.3f ', '%.3f %.3f ', '%.3f %.3f %.3f ', '%.3f %.3f %.3f %.3f ' }
local colour_stroke_operators = { 'G', nil, 'RG', 'K' }
local colour_fill_operators = { 'g', nil, 'rg', 'k' }
local colour_pattern_spaces = { 'PsG', nil, 'PsRG', 'PsK' }

local function get_colour_params(cr)
    return format_numbers(colour_template[#cr], table.unpack(cr)) .. ' '
end

local function get_stroke_colour(cr)
    return get_colour_params(cr)..colour_stroke_operators[#cr]
end

local function get_fill_colour(append, cr)
    local params = get_colour_params(cr)
    if append.pattern then
        local ptype, pname = table.unpack(append.pattern)
        if ptype == 2 then -- coloured pattern
            local space = colour_pattern_spaces[#cr]
            append:node(pdfres.use_resource_node('ColorSpace', space))
            return string.format('/%s cs %s%s scn', space, params, alloc.pdf_name(pname))
        elseif ptype == 1 then -- uncoloured pattern
            return string.format('/Pattern cs %s scn', alloc.pdf_name(pname))
        else -- should be unreachable
            alloc.err('Unknown pattern paint type %s', ptype)
        end
    end
    return params..colour_fill_operators[#cr]
end

-- TODO We should allow the user access to the internals here, so that support 
-- for other colour spaces may be added. Then, pattern support could also be 
-- moved into a plugin.
function A.colour(append, cr, otype)
    if cr and #cr > 0 then
        cr = convert_colour(cr)
        -- stroke colour
        if otype ~= 'fill' then
            local stroke = get_stroke_colour(cr)
            if stroke ~= append.stroke then
                append.stroke = stroke
                append:literal(stroke)
            end
        end
        -- fill colour (possibly a pattern)
        if otype ~= 'outline' then
            local fill = get_fill_colour(append, cr)
            append.pattern = nil -- patterns only apply to one object
            if fill ~= append.fill then
                append.fill = fill
                append:literal(fill)
            end
        end
    end
end

--2 stroke setting literals

-- M    miterlimit
-- j    linejoin
-- J    linecap
-- d    dash

-- As with colour, we record the last-used settings in ‘append’. This function 
-- is only called for fill/outline objects.

function A.linestate (append, object)
    local ml = object.miterlimit
    local res = { }
    if ml and ml ~= append.miterlimit then
        append.miterlimit = ml
        table.insert(res, pdfnum('M', ml))
    end
    local lj = object.linejoin
    if lj and lj ~= append.linejoin then
        append.linejoin = lj
        table.insert(res, string.format('%i j', lj))
    end
    local lc = object.linecap
    if lc and lc ~= append.linecap then
        append.linecap = lc
        table.insert(res, string.format('%i J', lc))
    end
    local dl = object.dash
    if dl then
        local d = make_pdf_dashpattern(dl)
        if d ~= append.dashed then
            append.dashed = d
            table.insert(res, d)
        end
    elseif append.dashed then
       append.dashed = false
       table.insert(res, '[] 0 d')
    end
    if #res > 0 then
        append:literal(table.concat(res, ' '))
    end
end

--2 path literals

-- MetaPost only gives us curved lines; if some of the segments are straight, 
-- we have to find out ourselves:

local bend_tolerance = 131/65536 -- context uses this value, presumably with good reasons

local function curved (a,b)
    local d = b.left_x - a.right_x
    if math.abs(a.right_x - a.x_coord - d) <= bend_tolerance
    and math.abs(b.x_coord - b.left_x - d) <= bend_tolerance then
        d = b.left_y - a.right_y
        if math.abs(a.right_y - a.y_coord - d) <= bend_tolerance
        and math.abs(b.y_coord - b.left_y - d) <= bend_tolerance then
            return false
        end
    end
    return true
end

-- Write the path as list of points.

-- m    move to this point without drawing anything
-- c    make a curved line (two control points)
-- l    make a straight line

function A.curve(append, path, open, concat)
    -- The ‘concat’ function transforms the given coordinate pairs 
    -- according to the current transformation.
    concat = concat or function(px, py) return px, py end
    local res = { }
    local append_line = function(to, op)
        table.insert(res, point_fmt(op, concat(to.x_coord, to.y_coord)))
    end
    local append_curve = function(from, to)
        local a, b = concat(from.right_x, from.right_y)
        local c, d = concat(to.left_x, to.left_y)
        table.insert(res, curve_fmt(a,b,c,d,concat(to.x_coord, to.y_coord)))
    end
    local append_knot = function(from, to)
        if not from then
            append_line(to, 'm')
        elseif curved(from, to) then
            append_curve(from, to)
        else
            append_line(to, 'l')
        end
    end
    local knot, prev_knot
    for i=1, #path do
        knot = path[i]
        append_knot(prev_knot, knot)
        prev_knot = knot
    end
    if not open then
        append_knot(knot, path[1])
    elseif #path == 1 then
        append_line(path[1], 'l') -- special case: draw a point
    end
    append:literal(table.concat(res, '\n'))
end

-- And actually draw the path.

-- S    draw the path
-- h    close the path
-- s    close and draw the path (equivalent to h S)
-- f    fill the path (implies h)
-- f*   fill the path, use even/odd rule
-- b    close, fill and draw the path (equivalent to h B)
-- b*   close, fill and draw, use even/odd rule
-- n    do nothing (used for clipping paths)

local function get_path_operator(otype, open)
    if otype == 'fill' then
        return 'f'
    elseif otype == 'outline' then
        return (open and 'S') or 's'
    elseif otype == 'both' then
        return 'b'
    elseif otype == 'nofill' then
        return ''
    elseif otype == 'eofill' then
        return 'f*'
    elseif otype == 'eofilldraw' then
        return 'b*'
    else
        alloc.err('Unknown path type ‘%s’', otype)
        return 'f'
    end
end

--

--1 PROCESSING OBJECTS

-- Our processors are located in two tables: one that contains a processor for 
-- each object and one that contains processors for certain ‘special’ statements. Every 
-- table contains functions that take the ‘append’ structure and the current 
-- object as arguments. The tables are indexed by object/special name.

-- The treatment of pre- and postscripts is like this:
--  * Pre- and postscripts should be of the form ‘type: instruction’.
--  * If the type of a prescript is present in the ‘specials’ table, the 
--    corresponding function will be used in place of the default handling.
--  * Execution of other prescripts and of all postscripts will be given by the 
--    entries in the ‘prescripts’ and ‘postscripts’ table corresponding to the 
--    type.

local process  = {}
local specials = {}
M.specials = specials

local prescripts = {}
local postscripts = {}
M.prescripts = prescripts
M.postscripts = postscripts

--2 choosing a parser

local function split_specials(thespecials)
    if not thespecials then return function() return end end
    local l = thespecials:explode('\r')
    local i, n = 0, #l
    return function()
        if i < n then i = i + 1 else return end
        local sp, instr = l[i]:match('^([a-zA-Z_]+): *(.*)')
        return sp, instr or l[i]
    end
end

local function parse_object(append, object)
    append.object_info = { }
    if debugging then
        append:printobj(object)
    end
    local processor = nil
    for sp, instr in split_specials(object.prescript) do
        if not sp then
            alloc.err('Unrecognised prescript: %s', instr)
            append:literal('%% unsupported special excluded (see log file)')
        elseif specials[sp] then
            processor = function() specials[sp](append, instr, object) end
        elseif prescripts[sp] then
            prescripts[sp](append, instr, object)
        else
            alloc.err('Unrecognised prescript ‘%s’ with instruction: %s', sp, instr)
            append:literal('%% unsupported special excluded (see log file)')
        end
    end
    if processor then
        processor()
    else
        process[object.type](append, object)
    end
    for sp, instr in split_specials(object.postscript) do
        if not sp then
            alloc.err('Unrecognised postscript: %s', instr)
            append:literal('%% unsupported special excluded (see log file)')
        elseif postscripts[sp] then
            postscripts[sp](append, instr, object)
        else
            alloc.err('Unrecognised postscript ‘%s’ with instruction: %s', sp, instr)
            append:literal('%% unsupported special excluded (see log file)')
        end
    end
end

--2 start/stop bounds

-- These can be ignored, because they are taken into account by MetaPost when 
-- it reports the bounding box of the picture.

process.start_bounds = function(append, object) end
process.stop_bounds  = function(append, object) end

--2 clipping

-- W    clipping operator
-- n    path no-op

process.start_clip = function(append, object)
    append:save()
    append:curve(object.path, false)
    append:literal('W n')
end

process.stop_clip = function(append, object)
    append:restore()
end

--2 fill and outline

process.fill_or_outline = function(append, object, otype)
    append:linestate(object)
    local t, appendpath
    if object.pen and object.pen.type == 'elliptical' then
        -- metapost includes nonelliptical pens in the outline
        t = mplib.pen_info(object)
        if t.width ~= append.linewidth then
            append:literal(pdfnum('w', t.width))
            append.linewidth = t.width
        end
        if otype == 'fill' then otype = 'both' end -- for in append:colour
        local transformed = not ( t.sx == 1 and t.rx == 0
                              and t.ry == 0 and t.sy == 1
                              and t.tx == 0 and t.ty == 0 )
        t = transformed and t
    end
    append:colour(object.color, otype) -- otype is 'fill' 'outline' or 'both'
    otype = append.object_info.otype or otype -- 'eofill' etc.
    local open = object.path
             and object.path[1].left_type
             and object.path[#object.path].right_type
    local operator = get_path_operator(otype, open)
    if t then
        local d = t.sx * t.sy - t.rx - t.ry
        local concat = function(px, py)
            return (t.sy*px - t.ry*py)/d, (t.sx*py - t.rx*px)/d
        end
        appendpath = function(path)
            append:save()
            append:literal('%f %f %f %f %f %f cm', t.sx, t.rx, t.ry, t.sy, t.tx, t.ty)
            append:curve(path, open, concat)
            append:literal(operator)
            append:restore()
        end
    else
        appendpath = function(path)
            append:curve(path, open)
            append:literal(operator)
        end
    end
    if object.path then appendpath(object.path) end
    if object.htap then appendpath(object.htap) end -- reversed trajectory
end

process.fill = function(append, object)
    process.fill_or_outline(append, object, 'fill')
end

process.outline = function(append, object)
    process.fill_or_outline(append, object, 'outline')
end

--2 specials

-- this will be pointed to the right table at the start of each run
local current_instance = false

-- pure specials are already taken care of in parse_object (they only have 
-- a ‘prescript’ field).
process.special = function(append, object) end

prescripts.pdf = function(append, special, object)
    append:literal(special)
end
postscripts.pdf = prescripts.pdf

prescripts.pdfcomment = function(append, str, object)
    append:literal('%% %s', str)
end
postscripts.pdfcomment = prescripts.pdfcomment

prescripts.latelua = function(append, str, object)
    local n = node.new('whatsit', 'late_lua')
    n.data = str
    append:node(n)
end
postscripts.latelua = prescripts.latelua

prescripts.OTYPE = function(append, str, object)
    append.object_info.otype = append.object_info.otype or str
end

specials.BASELINE = function(append, _, object)
    -- object is a ‘fill’ statement with only a single point in its path (and 
    -- will thus not have to be transformed).
    append.baseline = object.path[1].y_coord
end

-- 2 box resources (xforms)

-- The first problem that we run into is that we want to refer to xforms (from 
-- the metapost side) whose numerical id* we do know know yet (because the 
-- xform will only be made at the end of the run, during the lua-side 
-- processing of mplib output).
--
-- Our solution is using negative ids for metapost-defined xforms, which will 
-- be converted to actual boxresource ids by means of a conversion table.
--
-- The second problem is the need to position metapost-defined xforms by their 
-- original (metapost) origin. This necessitates storing extra information 
-- lua-side.
--
-- * Not to be confused with the object number which we, due to pdftex’s 
-- special handling of xforms, will never come to know.

local xform_nr_shim = { }

local function resolve_xform_id(nr)
    nr = tonumber(nr)
    if nr < 0 then
        return xform_nr_shim[-nr]
    else
        return nr
    end
end

local function reserve_xform_id()
    xform_nr_shim[1+#xform_nr_shim] = false
    return -#xform_nr_shim
end

M.resolve_xform_id = resolve_xform_id
E.resolve_xform_id = resolve_xform_id
E.reserve_xform_id = reserve_xform_id

-- When using xforms in metapost, the positive numbers refer to tex-defined and 
-- the negative to metapost-defined box resources.

specials.BOXRESOURCE = function(append, id, object)
    local realid = resolve_xform_id(id)
    local rule = tex.useboxresource(realid)
    append:box(object, node.hpack(rule))
end

local xform_sizes = { }
local xform_center = { }

local function set_boxresource_dimensions (id, transf, center)
    xform_sizes[id] = transf
    xform_center[id] = center
end

local function get_boxresource_dimensions (id)
    if xform_sizes[id] then
        return xform_sizes[id]
    else
        return { 'box_size', tex.getboxresourcedimensions(id) }
    end
end

local function get_boxresource_center (id)
    if xform_center[id] then
        return xform_center[id]
    else
        return "(0,0)"
    end
end

E.set_boxresource_dimensions = set_boxresource_dimensions
E.get_boxresource_dimensions = get_boxresource_dimensions
E.get_boxresource_center = get_boxresource_center

local function save_as_boxresource(pic)
    -- attributes
    local attrs = { '/Subtype/Form', bbox_fmt(0, -pic.dp, pic.wd, pic.ht) }
    for k, v in pairs(pic.user.xform_attrs or { }) do
        table.insert(attrs, string.format('%s %s', alloc.pdf_name(k), v))
    end
    -- box to-be-saved
    local box = wrap_picture(node.copy_list(pic.head), pic.x0, pic.y0)
    box.width, box.height, box.depth = pic.wd, pic.ht, pic.dp
    -- save the box
    local xform = tex.saveboxresource(box,
        table.concat(attrs, ' '), nil, false, 4) -- 4: no /Type, /BBox or /Matrix
    xform_nr_shim[-pic.user.xform_id] = xform
end

specials.XFORMINDEX = function(append, id, object)
    append.user.xform_id = tonumber(id)
    append.user.save_fn = save_as_boxresource
end

specials.XFORMATTRS = function(append, attrs, object)
    local t = parse_lua_table('XForm attributes', attrs)
    append.user.xform_attrs = t or { }
end

--2 patterns

-- Saved patterns have the following fields:
--     attr        the pattern attributes
--     stream      the pattern drawing statements
--     painttype   the paint type of the pattern (1 or 2)

local function write_pattern_object(pat)
    local objnum = pat.objnum or pdf.reserveobj()
    pdf.obj(objnum, 'stream', pat.stream, pat.attr)
    pdf.refobj(objnum)
    return string.format('%d 0 R', objnum)
end

prescripts.fillpattern = function(append, str, object)
    local name = 'MnmP'..tonumber(str)
    local pat = pdfres.get_resource('Pattern', name)
    if not pat then
        alloc.err('Unknown pattern %s', name)
    else
        append.pattern = { pat.painttype, name }
        append:node(pdfres.use_resource_node('Pattern', name))
    end
end

local function make_pattern_xform(head, bb)
    -- regrettably, pdf.refobj does not work with xforms, so we must 
    -- write it to the pdf immediately, whether the pattern will be 
    -- used or not.
    local xform = tex.saveboxresource((node.hpack(node.copy_list(head))),
        '/Subtype/Form '..bb, nil, true, 4) -- 4: no /Type, /BBox or /Matrix
    return string.format(' /Resources << /XObject << /PTempl %d 0 R >> >>', xform), '/PTempl Do'
end

local function definepattern(pic)
    local bb = bbox_fmt(table.unpack(pic.bbox))
    local pat, literals, resources = { write = write_pattern_object }, { }
    -- pattern content
    for n in node.traverse(pic.head) do
        -- try if we can construct the content stream ourselves; otherwise, 
        -- stuff the pattern template into an xform.
        if n.id == WHATSIT_NODE then
            -- try if we can simply concatenate pdf statements
            if n.subtype == node.subtype 'literal' then
                table.insert(literals, n.data)
            elseif n.subtype == node.subtype 'save' then
                table.insert(literals, 'q')
            elseif n.subtype == node.subtype 'restore' then
                table.insert(literals, 'Q')
            else
                resources, pat.stream = make_pattern_xform(pic.head, bb)
                goto continue
            end
        else
            resources, pat.stream = make_pattern_xform(pic.head, bb)
            goto continue
        end
        pat.stream = table.concat(literals, '\n')
    end
    ::continue::
    -- construct the pattern object
    local i = pic.user.pattern_info
    local m = i.matrix
    pat.painttype = tonumber(i.painttype)
    pat.attr = table.concat({
        string.format('/PatternType 1 /PaintType %d /TilingType %s /XStep %f /YStep %f\n',
            i.painttype, i.tilingtype, i.xstep, i.ystep),
        string.format('%s\n/Matrix [ %s %s %s %s %s %s ]', bb, m.xx, m.xy, m.yx, m.yy, m.x, m.y),
        resources }, '')
    -- remember the pattern
    pdfres.add_resource('Pattern', 'MnmP'..i.nr, pat)
end

specials.definepattern = function(append, str, object)
    local nr, tiling, paint, xs, ys, xx, xy, yx, yy = table.unpack(str:explode())
    append.user.pattern_info = { nr = nr, xstep = xs, ystep = ys,
        tilingtype = tiling, painttype = paint,
        matrix = { xx = xx, xy = xy, yx = yx, yy = yy, x = 0, y = 0 } }
    append.user.save_fn = definepattern
end

-- 2 extgstates

-- Specials for the graphics state:
--
--    gstate:save           q
--    gstate:restore        Q
--
--    extgstate:label       /label gs
--    extgstate:{...}       /newlabel gs
--
-- If a lua table is passed to the extgstate, minim will try and find an 
-- earlier-defined matching ExtGState object. If it cannot be found, a new one 
-- will be created and used. The values of the table will be written to the pdf 
-- as-they-are (this means booleans and numbers are alright), but the keys will 
-- be converted to pdf name objects.

prescripts.gstate = function(append, str, object)
    if str == 'save' or str == 'store' then
        append:save()
    elseif str == 'restore' then
        append:restore()
    else
        alloc.err('Unknown gstate operator: »%s«', str)
    end
end
postscripts.gstate = prescripts.gstate

local gs_next, gs_index = 1, { }

function M.get_gstate_name(t)
    -- format the pdf dict
    local d = { }
    for k,v in pairs(t) do
        if type(v) == 'table' and t.dashes then
            v = '[ '..make_pdf_dashpattern(v)..' ]'
        end
        table.insert(d, string.format('%s %s', alloc.pdf_name(k), v))
    end
    table.sort(d)
    d[0] = '<<'; table.insert(d, '>>')
    t.value = table.concat(d, ' ', 0)
    -- check the index
    if not gs_index[t.value] then
        local name = string.format('MnmGs%d', gs_next)
        gs_index[t.value] = name
        gs_next = gs_next + 1
        pdfres.add_resource('ExtGState', name, t)
    end
    -- return the resource name
    return gs_index[t.value]
end

prescripts.extgstate = function(append, str, object)
    -- determine resource name
    local name, t = str
    if string.find(str, '^[A-Za-z0-9_]+$') then
        t = pdfres.get_resource('ExtGState', name)
        if not t then return alloc.err('Unknown named ExtGState: %s', name) end
    else
        t = parse_lua_table('ExtGState', str)
        if not t then return end
        name = M.get_gstate_name(t)
    end
--  -- update state parameters (disabled for now; may be enabled if it has practical use)
--  if t.LW then append.linewidth = t.LW end
--  if t.ML then append.miterlimit = t.LW end
--  if t.LJ then append.linejoin = t.LW end
--  if t.LC then append.linecap = t.LW end
--  if t.D and type(t.D) == 'table' then append.dashed = make_pdf_dashpattern(t.D) end
    -- apply the state change
    append:literal('%s gs', alloc.pdf_name(name))
    append:node(pdfres.use_resource_node('ExtGState', name))
end
postscripts.extgstate = prescripts.extgstate

-- 2 text

process.text = function(append, object)
    alloc.err('Text figure primitives are not supported (this message should not occur)')
end

local function get_transform(rect)
    -- reconstruct the applied transformation by examining a unit square, i.e. 
    -- ‘rect’ was originally the path (0,0) -- (0,1) -- (1,1) -- (1,0)
    local ll, lr, ul = rect[1], rect[2], rect[4]
    -- determine translation from (0,0)
    local tx, ty = ll.x_coord, ll.y_coord
    -- determine rotation and scaling from the diagonals
    local sx, rx = lr.x_coord - tx, lr.y_coord - ty
    local ry, sy = ul.x_coord - tx, ul.y_coord - ty
    return sx, rx, ry, sy, tx, ty
end

local function apply_transform(rect, box)
    local sx, rx, ry, sy, tx, ty = get_transform(rect)
    local transform = node.new('whatsit', 'pdf_setmatrix')
    transform.next, box.prev = box, transform
    transform.data = string.format('%f %f %f %f', sx, rx, ry, sy)
    tx = tex.sp(''..tx..'bp')
    ty = tex.sp(''..ty..'bp')
    return wrap_picture(transform, tx, ty)
end

function A.box(append, object, box)
    box.width = 0 ; box.height = 0 ; box.depth = 0;
    local outer = apply_transform(object.path, box)
    append:colour(object.color, 'fill')
    append:save()
    append:node(outer)
    append:restore()
end

specials.TEXBOX = function(append, boxnr, object)
    local box = tex.getbox(tonumber(boxnr))
    append:box(object, node.copy_list(box))
end

specials.CHAR = function(append, data, object)
    local char, font, xo, yo = table.unpack(data:explode(' '))
    local n = node.new('glyph')
    n.char, n.font, n.xoffset, n.yoffset =
        tonumber(char), tonumber(font), tonumber(xo), tonumber(yo)
    append:box(object, node.hpack(n))
end

--

--1 METAPOST INSTANCES

local instances = { }
M.instances  = instances

--2 small instance helper functions

-- parameters: wd, ht+dp, dp
local function make_transform(w, h, d)
    return string.format('identity xscaled %fpt yscaled %fpt shifted (0,%fpt)',
        w/65536, (h+d)/65536, -d/65536)
end

local status_names = { [0] = 'good', 'warning', 'error', 'fatal' }
local function print_status(st)
    return string.format('status %d (%s)', st, status_names[st])
end

M.on_line = false
M.max_errprint = 1
local function print_log (nr, res, why)
    local i = instances[nr]
    -- only write to term if on_line or if exit status increases
    local log, alog --luacheck:ignore 231
    if M.on_line or res.status > i.status then
        alog = alloc.amsg
        local nr_errs = 0
        log = function(...)
            if  string.sub(table.pack(...)[2],1,2) == "! " then
                nr_errs = nr_errs + 1
            end
            if M.max_errprint < 1 or M.max_errprint >= nr_errs then
                alloc.msg(...)
            else
                alloc.log(...)
                alloc.term('╧ [... see log file for full report ...]')
                log, alog = alloc.log, alloc.alog
            end
        end
    else
        log, alog = alloc.log, alloc.alog
    end
    -- split log into lines; discard empty lines at the end
    local report = res.log and res.log:explode('\n') or { }
    -- write out the log
    log('┌ %smetapost instance {%s} (%d)', why or '', i.jobname, i.nr)
    for _,line in ipairs(report) do
        if line ~= '' and line ~= "(Please type a command or say `end')" then
            log('│ %s', line)
        end
    end
    log('└ %s', print_status(res.status))
    -- generate error or warning if needed
    if res.status > i.status then
        local ecl = tex.errorcontextlines -- TODO: why does TeX fill the error context
        tex.errorcontextlines = 0         -- with repeated <inserted text> BAD ???
        if res.status == 3 then
            alloc.err('Metapost instance now defunct')
        elseif res.status == 2 then
            alloc.err('Error in metapost code. Further errors will be ignored')
        elseif res.status == 1 then
            alloc.msg('Metapost code caused warning')
        end
        tex.errorcontextlines = ecl
    end
    -- save the exit status for later comparison
    i.status = res.status
end

local function new_file_finder()
    -- HACK: The file finder is called twice for every file input by metapost. 
    -- Thus, in order for the file recorder to work properly, we only record 
    -- repeated files and hope for the best.
    local last_found = false
    local function record(name, record_fn)
        if last_found and name == last_found then
            record_fn(name)
            last_found = false
        else
            last_found = name
        end
    end
    return function(name, mode, ftype)
        if mode == 'w' then
            record(name, kpse.record_output_file)
        else
            name = kpse.find_file(name, ftype)
            record(name, kpse.record_input_file)
        end
        return name
    end
end

--2 processing results

local function process_results(nr, res)
    local pictures = {}
    if res.fig then
        alloc.alog (' (%d figures)', #res.fig)
        for i=1, #res.fig do
            local fig = res.fig[i]
            local name = fig:filename()
            local append = init_append()
            if debugging then
                append:literal('%% START OF MP FIGURE %s (instance %d)', name, nr)
            end
            -- parse and append all objects
            append:save()
            local objects = fig:objects()
            for j=1, #objects do
                parse_object (append, objects[j])
            end
            append:restore()
            if debugging then
                append:literal('%% END OF MP FIGURE %s (instance %d)', name, nr)
            end
            -- bounding box and baseline information
            local bb = fig:boundingbox()
            local llx, lly, urx, ury = table.unpack(bb)
            local bas = append.baseline or lly
            local pic =
                { head = append.head
                , user = append.user
                , name = name
                , bbox = bb }
            if llx > urx and lly > ury then
                pic.discard = true -- picture is empty
                pic.wd, pic.ht, pic.dp, pic.x0, pic.y0 = 0,0,0,0,0
            else
                pic.wd = tex.sp(string.format('%s bp', urx - llx))
                pic.ht = tex.sp(string.format('%s bp', ury - bas))
                pic.dp = tex.sp(string.format('%s bp', bas - lly))
                pic.x0 = tex.sp(string.format('%s bp',  -llx    ))
                pic.y0 = tex.sp(string.format('%s bp',  -bas    ))
            end
            cb.call_callback('finish_mpfigure', pic)
            if pic.user.save_fn then
                pic.discard = true
                pic.user.save_fn(pic)
            end
            if not pic.discard then
                pic.head = wrap_picture(pic.head, pic.x0, pic.y0)
            end
            if debugging then
                alloc.msg('┌ image %s, with %s objects, %s nodes',
                name, #objects, append.node_count)
                alloc.msg('│ dimensions (%fpt+%fpt)x%fpt',
                    pic.ht/65536, pic.dp/65536, pic.wd/65536)
                alloc.msg('└ origin (%fpt,%fpt)',
                    pic.x0/65536, pic.y0/65536)
                if pic.discard then alloc.amsg(' [discarded]') end
            end
            table.insert(pictures, pic)
        end
    else
        alloc.alog (' (no figures)')
    end
    return pictures
end

-- 2 running lua scripts

-- There are two ways of running lua code with the runscript primitive. In the 
-- normal case, the argument to runscript is executed as lua code. You can 
-- bypass this mechanism by prepending the runscript argument with the name of 
-- a lua function between double square brackets. Then, the remainder of the 
-- string will be passed as an argument to that function.Q
--
-- Code run with runscript may return a value; we will try and convert it to 
-- a string that metapost can understand.
--
-- Tables of the form { 'box_size', width, height, depth, margin } are  
-- converted to a transform. (The margin will be ignored for now, this may 
-- change in the future.)

local function mkluastring(s)
    return "'"..(s
        :gsub('\\', '\\\\')
        :gsub("'", "\\'")
        :gsub('\n', '\\n')
        :gsub('\013', '\\r')
        :gsub('\000', '\\000')
    ).."'"
end

local function runscript(code)
    debug('┌ runscript: %s', code)
    -- (possibly) pass directly to function
    local fn, arg = code:match('^%[%[(.-)%]%](.*)')
    if fn then code = 'return '..fn .. mkluastring(arg) end
    -- execute the script
    local f, msg = load(code, current_instance.jobname, 't', current_instance.env)
    -- interpret results
    if f then
        local result = f()
        if result == nil then
            debug('└ (no return value)')
            return
        else
            local t = type(result)
            if t == 'number' then
                result = string.format('%.16f', result)
            elseif t == 'string' then
                result = result
            elseif t == 'table' and result[1] == 'box_size' then
                result = make_transform(result[2], result[3], result[4])
            elseif t == 'table' and #result < 5 then
                local fmt = #result == 1 and '%.16f'
                         or #result == 2 and '(%.16f, %.16f)'
                         or #result == 3 and '(%.16f, %.16f, %.16f)'
                         or #result == 4 and '(%.16f, %.16f, %.16f, %.16f)'
                result = fmt:format(table.unpack(result))
            elseif t == 'table' and #result == 6 then
                result = table.concat({
                        'begingroup save t; transform t',
                        'xxpart t = %.16f', 'xypart t = %.16f',
                        'yxpart t = %.16f', 'yypart t = %.16f',
                        'xpart t = %.16f',  'ypart t = %.16f',
                        't endgroup' },
                    ';'):format(table.unpack(result))
            else
                result = tostring(result)
            end
            if #result > 120 then
                debug('└ %s etc. etc.', result:sub(1,110))
            else
                debug('└ %s', result)
            end
            return result
        end
    else
        local mp_msg = string.gsub(msg, '"', '"&ditto&"')
        -- TODO: provide errhelp once the echo is gone
        return string.format('hide(errmessage "Lua error: %s")', mp_msg)
    end
end

-- The environment the scripts will be run in can be specified at instance 
-- creation; its default value is a copy (at that time) of the global 
-- environment. The runscript environment will then be extended with all 
-- elements of the M.mp_functions table.

M.mp_functions = E
E.texmessage = alloc.msg

local function prepare_env(e) -- in M.open()
    local env = e or copy_table(_G, { })
    return copy_table(E, env)
end

function E.quote(val)
    if type(val) ~= 'string' then return val end
    local escaped = string.format('%s', val):gsub('"', '"&ditto&"')
    return string.format('("%s")', escaped)
end

function E.sp_to_pt(val)
    return string.format('%.16fpt', val/65536)
end

function E.quote_for_lua(s)
    return E.quote(mkluastring(s))
end

-- These are here so that luametafun does not bug out immediately. Please note 
-- that using metafun is not otherwise supported or recommended.
local cct_maketext = alloc.registernumber('minim:mp:catcodes:maketext')
E.catcodes = { numbers =
    { inicatcodes = cct_maketext , texcatcodes = cct_maketext
    , luacatcodes = cct_maketext , notcatcodes = cct_maketext
    , vrbcatcodes = cct_maketext , prtcatcodes = cct_maketext
    , ctxcatcodes = cct_maketext , txtcatcodes = cct_maketext
}   }
E.mp = mp or { } --luacheck: ignore 113
-- all functions below seem nonessential
E.mp.mf_path_reset = E.mp.mf_path_reset or function() end
E.mp.mf_finish_saving_data = E.mp.mf_finish_saving_data or function() end
E.mp.report = E.mp.report or function() end


--2 typesetting with tex

-- The result of the maketext function is fed back into metapost; on that side, 
-- the representation of a <picture primary> will be expected for btex...etex 
-- and an empty string for verbatimtex...etex. maketext is indistinguishable 
-- from btex...etex.
--
-- We return here an image() containing a single path; it is that path that 
-- will be replaced with a stored node list later on.
--
-- The path itself is a unit rectangle: from the rectangle we will be able to 
-- reconstruct how the tex box will have been transformed. We indicate with 
-- a prescript that the rectangle should be replaced.
--
-- The size of the picture is communicated to MetaPost by a ‘setbounds’ 
-- instruction.

local function maketext(text, mode)
    if mode == 0 then -- btex or maketext
        local nr = alloc.new_box()
        debug('┌ btex: %s', text)
        table.insert(current_instance.boxes, nr)
        local assignment = string.format('\\global\\setbox%s=\\hbox{\\the\\everymaketext %s}', nr, text)
        tex.runtoks(function() tex.print(current_instance.catcodes, assignment:explode('\n')) end)
        local box = tex.box[nr]
        debug('└ etex: box %d', nr)
        return string.format('_set_maketext_result_(%d, %s)', nr,
            make_transform(box.width, box.height, box.depth))
    elseif mode == 1 then -- verbatimtex
        debug('┌ verbatimtex: %s', text)
        tex.runtoks(function() tex.print(current_instance.catcodes, text:explode('\n')) end)
        debug('└ etex')
    end
end

-- a font cache for infont and glyph of
local infont_fonts = { }
local function get_infont_font(fnt)
    local csname = 'minim-mp infont '..fnt
    local res = infont_fonts[csname]
    if res then
        debug('├ resolved font "%s" (%d)', fnt, res)
    else
        tex.runtoks(function()
            tex.print(current_instance.catcodes, string.format(
                '\\expandafter\\font\\csname %s\\endcsname={%s}\\relax', csname, fnt))
        end)
        res = font.id(csname)
        infont_fonts[csname] = res
        debug('├ loaded font "%s" (%d)', fnt, res)
    end
    return res
end

local function fontid_from_csname(fnt)
    local id = font.id(fnt)
    if id < 0 then return end
    debug('├ resolved font \\%s (%d)', fnt, id)
    return id
end

local function getfontid(fnt)
    return tonumber(fnt)
        or fontid_from_csname(fnt)
        or get_infont_font(fnt)
end

local typeset_box = alloc.new_box('infont box')

local function process_typeset(text, fnt, sep, fn)
    tex.runtoks(function()
        tex.sprint(current_instance.catcodes, string.format(
            '\\setbox%d=\\hbox{\\setfontid%d\\relax', typeset_box, getfontid(fnt)))
        tex.sprint(-2, text); tex.sprint(current_instance.catcodes, '}')
    end)
    local res, x = { }, 0
    for n in node.traverse(tex.box[typeset_box].list) do
        if n.id == GLYPH_NODE then
            fn(res, n, x)
            x = x + n.width
        elseif n.id == GLUE_NODE then
            x = x + n.width
        elseif n.id == KERN_NODE then
            x = x + n.kern
        end
    end
    return table.concat(res, sep)
end

function E.minim_infont(text, fnt)
    return process_typeset(text, fnt, '', function(res, n, x)
        table.insert(res, string.format(
            'draw image ( fill unitsquare shifted (%fpt,0) withprescript "CHAR:%d %d %d %d";'
            ..'setbounds currentpicture to unitsquare transformed %s shifted (%fpt,0););',
                x/65536, n.char, n.font, n.xoffset, n.yoffset,
                make_transform(n.width, n.height, n.depth), x/65536))
    end)
end


--2 glyph contours

function M.make_glyph(glyphname, fnt)
    -- gather information
    if not luaotfload then
        alloc.err('Luaotfload required for glyph of operator')
        return { }, 10
    end
    local fontid = getfontid(fnt)
    local thefont = font.getfont(fontid)
    if not thefont then
        alloc.err('Font not found: %s (id %s)', fnt, fontid)
        return { }, 10
    end
    local gid = luaotfload.aux.gid_of_name(fontid, glyphname)
    if not gid then
        alloc.err('Font %s has no glyph named %s', thefont.psname, glyphname)
        return { }, 10
    end
    local segments = fonts.hashes.shapes[fontid].glyphs[gid].segments
    if #segments == 0 then return { }, 10 end
    local q = 1000 / (thefont.units_per_em or 1000)
    -- retrieve the contours
    local path, paths = { '(' }, { }
    for _, s in ipairs(segments) do
        local op = s[#s]
        if op == 'm' then
            if #path > 1 then
                table.insert(path, '--cycle)')
                table.insert(paths, table.concat(path, ''))
                path = { '(' }
            end
            table.insert(path, string.format('(%f, %f)', q*s[1], q*s[2]))
        elseif op == 'l' then
            table.insert(path, string.format('--(%f, %f)', q*s[1], q*s[2]))
        elseif op == 'c' then
            table.insert(path, string.format('..controls (%f, %f) and (%f, %f) .. (%f, %f)',
                q*s[1], q*s[2], q*s[3], q*s[4], q*s[5], q*s[6]))
        end
    end
    table.insert(path, '--cycle)')
    table.insert(paths, table.concat(path, ''))
    return paths, thefont.size
end

local function get_glyphname(c_id)
    if type(c_id) == 'string' then return c_id end
    local res = luaotfload.aux.name_of_slot(c_id)
    debug('├ name of glyph %d is %s', c_id, res)
    return res
end

function E.get_glyph(c_id, fnt)
    debug('┌ glyph %s of %s', c_id, fnt)
    local name = get_glyphname(c_id)
    local contours, size = M.make_glyph(name, fnt)
    local res = { }
    for _, c in ipairs(contours) do
        local scaled = string.format('%s scaled %f', c, size/65536/1000)
        debug('│ %s', scaled)
        table.insert(res, scaled)
    end
    debug('└ %d contours returned', #res)
    return table.concat(res, ', ')
end

function E.get_contours(text, fnt)
    return process_typeset(text, fnt, ', ', function(res, n, x)
        local contours, size = M.make_glyph(get_glyphname(n.char), n.font)
        for _, c in ipairs(contours) do
            table.insert(res, string.format(
                '%s scaled %f shifted (%fpt, %fpt)', c,
                size/65536/1024, (x + n.xoffset)/65536, n.yoffset/65536))
        end
    end)
end

M.get_contours = E.get_contours


--2 opening, running and and closing instances

M.default_format = 'plain.mp'
M.default_mathmode = 'scaled'

local function apply_default_instance_opts(t)
    return
        { ini_version  = true
        , error_line   = (texconfig.error_line or 79) - 5
        , extensions   = 1
        , find_file    = new_file_finder()
        --, script_error = ...
        , job_name     = t.jobname
        , math_mode    = t.mathmode or t.math or M.default_mathmode
        , random_seed  = t.randomseed or t.seed or nil
        -- , file_line_error_style
        , make_text    = maketext
        , run_script   = runscript
        }
end

local function save_image_list(self, res)
    for _, img in ipairs(res) do
        if img.discard then
            node.flush_list(img.head)
        else
            self.results.count = self.results.count + 1
            img.prev, img.next = self.results.last, nil
            self.results.by_name[img.name] = img
            if nil == self.results.first then
                self.results.first = img
            else
                self.results.last.next = img
            end
            self.results.last = img
        end
    end
end

function M.run (nr, code)
    local self = instances[nr]
    if self.status == 3 then
        alloc.msg('metapost instance %s (%s) is defunct and will not run', self.jobname, nr)
        return
    end
    current_instance = self
    if debugging then
        alloc.log('┌ metapost chunk for {%s} (%d)', self.jobname, nr)
        for _, line in ipairs(code:explode('\013')) do
            alloc.log('│ %s', line)
        end
        alloc.log('└')
    end
    local cct = tex.catcodetable
    tex.catcodetable = self.catcodes
    local res = self.instance:execute(code)
    tex.catcodetable = cct
    print_log(nr, res)
    local picts = process_results(nr, res)
    save_image_list(self, picts)
end

M.init_code = { 'let dump=endinput;'
              , 'boolean mplib; mplib:=true;'
              , 'input INIT;'
              , 'input minim.mp;'
              , 'input minim-mp.mp;' }
local maketext_catcodes = alloc.registernumber('minim:mp:catcodes:maketext')

function M.open (t)
    local nr = #instances + 1
    tex.count['mp:cur:inst'] = nr
    -- creating instance options
    t.jobname = t.jobname or ':metapost:'
    local init = string.gsub(table.concat(M.init_code, ''), 'INIT', t.format or M.default_format)
    local opts = apply_default_instance_opts(t)
    local instance = mplib.new(opts)
    tex.runtoks 'mp:init:env'
    -- adding the instance
    instances[nr] =
        { nr        = nr
        , instance  = instance
        , jobname   = t.jobname
        , results   = { first = nil, last = nil, by_name = {}, count = 0 }
        , status    = 0
        , catcodes  = t.catcodes or maketext_catcodes
        , boxes     = { } -- allocated by maketext
        , env       = prepare_env(t.env)
        }
    current_instance = instances[nr]
    print_log(nr, instance:execute(init), 'opening ')
    tex.count['mp:cur:inst'] = -1
    return nr
end

function M.close (nr)
    local i = instances[nr]
    tex.count['mp:cur:inst'] = nr
    if i.instance then
        local res = i.instance:finish()
        print_log(nr, res, 'closing ')
    end
    for _, b in ipairs(i.boxes) do
        -- remove allocated boxes
        tex.box[b] = nil
    end
    instances[nr] = false
    tex.count['mp:cur:inst'] = -1
end

--2 retrieving and using results

local function retrieve(nr, name)
    local results = instances[nr].results
    local image
    if name then
        image = results.by_name[name]
        results.by_name [name] = nil
    else
        image = results.first
    end
    if not image then return end
    results.count = results.count - 1
    if image.prev then
        if image.next then
            image.prev.next = image.next
            image.next.prev = image.prev
        else
            image.prev.next = nil
            results.last = image.prev
        end
    elseif image.next then
        results.first = image.next
        image.next.prev = nil
    else
        results.first = nil
        results.last  = nil
    end
    return image
end

function M.left (nr)
    return instances[nr].results.count
end

function M.get_image(nr, name)
    local image = retrieve(nr, name)
    if image then
        local box = image.head
        box.width  = image.wd
        box.height = image.ht
        box.depth  = image.dp
        return box
    end
end

function M.shipout(nr)
    local ox, oy  = pdf.getorigin()
    local ho, vo = tex.hoffset, tex.voffset
    pdf.setorigin()
    tex.hoffset = 0
    while M.left(nr) > 0 do
        local image = retrieve(nr)
        tex.pageheight = (image.ht + image.dp)
        tex.pagewidth  = image.wd
        tex.voffset    = image.ht
        tex.box[255]   = image.head
        tex.shipout(255)
        tex.count[0] = tex.count[0] + 1
    end
    pdf.setorigin(ox, oy)
    tex.hoffset, tex.voffset = ho, vo
end

--2 tex interface

local scan_int = token.scan_int
local scan_string = token.scan_string

alloc.luadef('closemetapostinstance', function() M.close(scan_int()) end)

local code_catcodes = alloc.registernumber('minim:mp:catcodes:mpcode')

alloc.luadef('runmetapost', function()
    local id = scan_int()
    tex.count['mp:cur:inst'] = id
    -- run tex code before
    tex.runtoks 'mp:inst:pre:tex'
    -- scan the argument with inert catcodes
    local cct = tex.catcodetable
    tex.catcodetable = code_catcodes
    token.scan_keyword '\013' -- ^^M has catcode 12 now
    local code = token.scan_string()
    tex.catcodetable = cct
    -- prepare the argument further
    tex.toks['mp:mpcode'] = code
    tex.runtoks 'mp:makempcode'
    code = tex.toks['mp:mpcode']
    -- run the code
    M.run(id, code)
    -- run tech code after
    tex.runtoks 'mp:inst:post:tex'
    tex.count['mp:cur:inst'] = -1
end, 'protected')

alloc.luadef('getnextmpimage', function()
    node.write(M.get_image(scan_int()))
end)
alloc.luadef('getnamedmpimage', function()
    node.write(M.get_image(scan_int(), scan_string()))
end)

alloc.luadef('boxnextmpimage', function()
    local i = scan_int()
    local b = scan_int()
    tex.box[b] = M.get_image(i)
end)

alloc.luadef('boxnamedmpimage', function()
    local i = scan_int()
    local b = scan_int()
    local n = scan_string()
    tex.box[b] = M.get_image(i, n)
end)

alloc.luadef('remainingmpimages', function()
    tex.sprint(M.left(scan_int()))
end)

--

--

return M

