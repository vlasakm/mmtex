
local M = { }

local alloc = require 'minim-alloc'
local cb = require 'minim-callbacks'

-- the standard table design
local function init_resources()
    return {
        ExtGState = { },
        ColorSpace = { },
        Pattern = { },
        Shading = { },
    }
end

-- the module will use optex’s functions if present
M.self_destruct = pdf.add_page_resource or false

-- resource_data is a table that can contain any data. only the following keys 
-- are used by this module:
--
--    _entry_   internal value; do not use
--    value     value in the resource dictionary
--    write()   called for writing the resource to the pdf; returns value
--
-- of the last two, only one needs be present; if the value is missing it will 
-- be set at first use to the result of write().
--
local resource_data = init_resources() -- name ↦ { [write = ... | value = ...], ... }
--
function M.add_resource(kind, name, resource)
    resource_data[kind][name] = resource
end
function M.get_resource(kind, name)
    return resource_data[kind][name]
end
function M.use_resource(kind, name)
    local res = resource_data[kind][name]
    if not res then
        return alloc.err('Unknown %s resource: %s', kind, name)
    end
    res.value = res.value or res:write()
    if not res._entry_ then -- first-use
        res._entry_ = string.format('%s %s', alloc.pdf_name(name), res.value)
        if M.self_destruct then
            M.self_destruct(kind, name, res.value)
        end
    end
    return res._entry_
end

-- global resources are mainly for pgf compatibility: contains adds entries to 
-- the resource dictionaries that will be added for every page.
--
local global_resources = init_resources() -- name ↦ '/Key <value>'
--
function M.add_global_resource(kind, name, value)
    local r = global_resources[kind]
    if M.self_destruct then
        M.self_destruct(kind, name, value)
    elseif name == nil then -- used for pgf compatibility
        if value ~= '' then
            r[''] = r[''] and string.format('%s %s', global_resources[kind][''], value) or value
        end
    else
        r[name] = string.format('%s %s', alloc.pdf_name(name), value)
    end
end

-- we can now provide optex’s interface
if not M.self_destruct then
    pdf.add_page_resource = M.add_global_resource
end

-- for nonglobal resources, every use must be marked with a late_lua node. from 
-- those, the M.use_resouce() function will be called automatically.
--
local page_resources = init_resources() -- name ↦ '/Key <value>'
--
function _with_pdf_resource_(kind, name) -- global, for use in latelua
    page_resources[kind][name] = M.use_resource(kind, name)
end
function M.use_resource_node(kind, name)
    local n = node.new('whatsit', 'late_lua')
    n.data = string.format('_with_pdf_resource_("%s", "%s")', kind, name)
    return n
end

-- construction and caching of resource dictionaries.
--
local previous_dicts = init_resources() -- pdf dict ↦ objnum
--
local function make_resource_entry(kind)
    local arr = { }
    for _, entry in pairs(page_resources[kind]) do table.insert(arr, entry) end
    for _, entry in pairs(global_resources[kind]) do table.insert(arr, entry) end
    if #arr == 0 then return false end
    table.sort(arr)
    arr[0] = '<<'; table.insert(arr, '>>')
    local dict = table.concat(arr, ' ', 0)
    local objnum = previous_dicts[kind][dict]
    if not objnum then
        objnum = pdf.obj(dict)
        pdf.refobj(objnum)
        previous_dicts[kind][dict] = objnum
    end
    return string.format('/%s %d 0 R', kind, objnum)
end

local removal_regex = {
    ExtGState  = ' */ExtGState *%d+ +0 *R',
    ColorSpace = ' */ColorSpace *%d+ +0 *R',
    Pattern    = ' */Pattern *%d+ +0 *R',
    Shading    = ' */Shading *%d+ +0 *R' }

local function update_page_resources(shippingout)
    if M.self_destruct then return end
    local resources = shippingout and pdf.getpageresources() or pdf.getxformresources() or ''
    for kind, used in pairs(page_resources) do
        resources = string.gsub(resources, removal_regex[kind], '')
        local entry = make_resource_entry(kind)
        if entry then
            resources = resources == '' and entry or string.format('%s %s', resources, entry)
        end
    end
    -- update page resources
    if shippingout then
        pdf.setpageresources(resources)
    else
        pdf.setxformresources(resources)
    end
    page_resources = init_resources()
end

cb.register('finish_pdfpage', update_page_resources)

-- for pgf compatibility, reroute the pgf resource registration functions to 
-- our global resource pool.
--
alloc.luadef('minim:pgf:fix:luaside', function()
    alloc.luadef('pgf@sys@addpdfresource@extgs@plain', function()
        M.add_global_resource('ExtGState', nil, token.scan_string())
    end)
    alloc.luadef('pgf@sys@addpdfresource@patterns@plain', function()
        M.add_global_resource('Pattern', nil, token.scan_string())
    end)
    alloc.luadef('pgf@sys@addpdfresource@colorspaces@plain', function()
        M.add_global_resource('ColorSpace', nil, token.scan_string())
    end)
end)

return M

