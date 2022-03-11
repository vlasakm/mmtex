
local M = {}

-- 1 messages

function M.msg(...)
    texio.write_nl(string.format(...))
end

function M.amsg(...)
    texio.write(string.format(...))
end

function M.log(...)
    texio.write_nl('log', string.format(...))
end

function M.alog(...)
    texio.write('log', string.format(...))
end

function M.term(...)
    texio.write_nl('term', string.format(...))
end

function M.err (...)
    tex.error(string.format(...))
end

-- 1 pdf helpers

local function insert_formatted(t, ...)
    table.insert(t, string.format(...))
end

local function hexify(c)
    return string.format('#%02x', c:byte())
end
function M.pdf_name(n)
    return '/'..n
        :gsub('[][(){}<>#%%/\\]', hexify)
        :gsub('%G', hexify)
end

-- re-encode to utf-16
local function pdf_hex_string(text)
    local str = { [1] = '<feff' }
    for i in text:utfvalues() do
        if i <= 0xffff then
            insert_formatted(str, '%04x', i)
        else
            i = i - 0x10000
            m = math.floor(i/0x400) + 0xd800
            n = ( i % 0x400 ) + 0xdc00
            insert_formatted(str, '%04x%04x', m, n)
        end
    end
    table.insert(str, '>')
    return table.concat(str,'')
end
local function octify(c)
    return string.format('\\%03o', c:byte())
end
function M.pdf_string(text)
    -- do note that \ddd is decimal in lua, octal in pdf
    if text:match('[^%g\009\010\13 ]') then
        return pdf_hex_string(text)
    else
        return string.format('(%s)', text
            :gsub('[()\\]','\\%0')
            :gsub('%c', octify))
    end
end

-- try and produce a date of the format (D:YYYYMMDD)
function M.pdf_date(text)
    local y, m, d = string.match(text, '^([12][0-9][0-9][0-9])-([0-9][0-9]?)-([0-9][0-9]?)$')
    if not y then d, m, y  = string.match(text, '^([0-9][0-9]?)-([0-9][0-9]?)-([12][0-9][0-9][0-9])$') end
    if y then
        return string.format('(D:%4d%02d%02d)', y, m, d)
    else
        return string.format('(D:%s)', text)
    end
end

-- 1 scanning helpers

local function make_scanner(fn)
    return function(this, name, multiple)
        this.scanners[name] = multiple and function()
                this.res[name] = this.res[name] or { }
                table.insert(this.res[name], fn())
            end or function()
                this.scanners[name] = nil
                this.res[name] = fn()
            end
        return this
    end
end

function M.options_scanner()
    return { scanners = { }, res = { },
        int = make_scanner(token.scan_int),
        glue = make_scanner(token.scan_glue),
        dimen = make_scanner(token.scan_dimen),
        string = make_scanner(token.scan_string),
        argument = make_scanner(token.scan_argument),
        word = make_scanner(token.scan_word),
        list = make_scanner(token.scan_list),
        keyword = function(this, name, opposite)
            this.scanners[name] = function()
                this.res[name] = true
                if opposite then this.res[opposite] = false end
            end
            if opposite then
                this.scanners[opposite] = function()
                    this.res[name] = false
                    this.res[opposite] = true
                end
            end
            return this
        end,
        table = function(this, name)
            this.scanners[name] = function()
                this.res[name] = this.res[name] or { }
                this.res[name][token.scan_string()] = token.scan_string()
            end
            return this
        end,
        subtable = function(this, name)
            this.scanners[name] = function()
                this.res[name] = this.res[name] or { }
                local sub = token.scan_string();
                this.res[name][sub] = this.res[name][sub] or { }
                this.res[name][sub][token.scan_string()] = token.scan_string()
            end
            return this
        end,
        scan = function(this, defaults)
            this.res = defaults or this.res
            repeat
                local matched = false
                for name, scanner in pairs(this.scanners) do
                    if token.scan_keyword(name) then
                        matched = true
                        scanner()
                    end
                end
            until not matched
            return this.res
        end
    }
end

--1 saving modules and tables

local tables = package.loaded['minim-saved-tables']
    or { ['minim:modules'] = { } }
local modules = tables ['minim:modules']

function M.remember (name)
    if modules[name] == nil then
        modules[name] = false -- will be a number if a bytecode register is reserved
        modules[#modules+1] = name
    end
end

function M.saved_table (identifier, table)
    if tables[identifier] == nil then
        tables[identifier] = table or { }
    end
    return tables[identifier]
end

-- saved tables may only contain values that can be converted to and from 
-- strings with tostring() or other tables meeting the same requirement.
function M.table_to_text (tbl)
    local r = { }
    for i,t in pairs(tbl) do
        local l = ''
        if type(i) == 'string' then
            l = string.format('[%q] = ', i)
        else
            l = string.format('[%s] = ', i)
        end
        if type(t) == 'table' then
            l = l .. M.table_to_text (t)
        elseif type(t) == 'string' then
            l = l .. string.format ('%q', t)
        else
            l = l .. tostring(t)
        end
        r[#r+1] = l
    end
    return '{ ' .. table.concat (r,', ') .. ' }'
end

local cb = require('minim-callbacks')
M.remember('minim-callbacks')
M.remember('minim-alloc')

-- 1 allocation functions

-- like \unset
M.unset = -0x7FFFFFFF

-- works for both \chardef and the likes of \countdef
function M.registernumber(csname)
    if token.is_defined(csname) then
        return token.create(csname).index
    else
        return -- would return 0 otherwise
    end
end

-- we need remember lua-made allocations in the format file, since otherwise, 
-- a different register will be reserved when the lua code is seen again in the 
-- actual run.
local allocations = M.saved_table('minim lua-side allocations')

local function make_alloc_new(fname, globcount)
    allocations[fname] = allocations[fname] or { }
    M['new_'..fname] = function(id)
        local nr
        if id and allocations[fname][id] then
            nr = allocations[fname][id]
        else
            nr = tex.count[globcount] + 1
            tex.setcount('global', globcount, nr)
            if id then allocations[fname][id] = nr end
            M.log('\\%s%d : %s', fname, nr, id or '<unnamed>')
        end
        return nr
    end
end

make_alloc_new ('attribute'    , 'e@alloc@attribute@count'   )
make_alloc_new ('whatsit'      , 'e@alloc@whatsit@count'     )
make_alloc_new ('luabytecode'  , 'e@alloc@bytecode@count'    )
make_alloc_new ('function'     , 'e@alloc@luafunction@count' )
make_alloc_new ('luachunkname' , 'e@alloc@luachunk@count'    )
make_alloc_new ('catcodetable' , 'e@alloc@ccodetable@count'  )
make_alloc_new ('userrule'     , 'e@alloc@rule@count'        )

-- We need different allocation functions for the older registers, because 
-- etex’s global allocation macros are off-by-one w.r.t. all other.
--
local function make_alloc_old(fname, globcount)
    allocations[fname] = allocations[fname] or { }
    M['new_'..fname] = function (id)
        local nr
        if id and allocations[fname][id] then
            nr = allocations[fname][id]
        else
            nr = tex.count[globcount]
            tex.setcount('global', globcount, nr + 1)
            if id then allocations[fname][id] = nr end
            M.log('\\%s%d : %s', fname, nr, id or '<unnamed>')
        end
        return nr
    end
end

-- existing allocation counters
make_alloc_old ('count',  260 )
make_alloc_old ('dimen',  261 )
make_alloc_old ('skip',   262 )
make_alloc_old ('muskip', 263 )
make_alloc_old ('box',    264 )
make_alloc_old ('toks',   265 )
make_alloc_old ('marks',  266 )

function M.luadef (csname, fn, ...)
    local nr = M.new_function(csname)
    lua.get_functions_table()[nr] = fn
    token.set_lua(csname, nr, ...)
end

-- the current file
M.luadef('minim:currentfile', function()
    tex.sprint((status.filename:gsub('^.*/', '')))
end)

-- make pdf_string() available as \pdfstring{...}
M.luadef('pdfstring', function() M.pdf_string(token.scan_string()) end)

-- uselanguage hook callback
cb.new_callback('uselanguage', 'simple')
M.luadef('minim:uselanguagecallback', function()
    local langname = token.scan_string()
    cb.call_callback('uselanguage', langname)
end)

--1 dumping information to the format file

-- reserve a bytecode register
local saved_tables_bytecode = M.new_luabytecode('saved_tables_bytecode')

-- we cannot use set_lua because lua functions are not included in the format file
token.set_macro('minim:restoremodules', '\\luabytecodecall'..saved_tables_bytecode)

local function dump_saved_tables()
    M.msg('pre_dump: save modules and tables to format file')
    -- save modules
    for i,name in ipairs (modules) do
        if not modules[name] then
            M.msg('saving module '..name)
            -- reserve (if necessary) a bytecode register
            modules[name] = M.new_luabytecode ('module '..name)
            -- store the file into the format file
            lua.bytecode[modules[name]] = loadfile(kpse.find_file(name,'lua'))
        end
    end
    -- save tables (and restore modules)
    local saved_tables = [[
        
        -- include all saved tables in this bytecode register
        local t = ]]..M.table_to_text(tables)..[[

        -- and make them available via require()
        package.loaded['minim-saved-tables'] = t

        -- restore all remembered modules from their saved bytecode
        local s = t['minim:modules']
        for _, name in ipairs (s) do
            texio.write_nl('log', 'minim: restoring module '..name)
            package.loaded[name] = lua.bytecode[ s[name] ] ()
        end

        ]]
    lua.bytecode[saved_tables_bytecode] = load(saved_tables)
end

cb.register ('pre_dump', dump_saved_tables)

--

return M

