
local M = {}

local function log(...) end
local function alog(...) end
local function do_log(msg, ...)
    texio.write_nl('log', string.format(msg, ...))
end

--1 capturing the callback mechanism

local primitives = { }
M.primitives = primitives
primitives.register = callback.register
primitives.find     = callback.find
primitives.list     = callback.list

-- use the ltluatex functions if needed
local primitive_register = primitives.register
if luatexbase then
    primitive_register = function(cb, f)
        if f == nil then
            luatexbase.remove_from_callback(cb, 'minim callback')
        elseif f == false then
            luatexbase.disable_callback(cb)
        else
            luatexbase.add_to_callback(cb, f, 'minim callback')
        end
    end
end


local own_callbacks   = {}
local callback_lists  = {}
local callback_stacks = {}

--1 finding callbacks

function M.find(cb)
    local f = own_callbacks[cb]
    if f == nil then
        return primitives.find(cb)
    else
        return f
    end
end

function M.list()
    local t = {}
    for n,f in pairs(callback_lists) do
        if f then
            t[n] = #f
        else
            t[n] = false
        end
    end
    -- no stack callbacks, since the active callback is in one of the two below
    for n,f in pairs(primitives.list()) do
        if f then
            t[n] = t[n] or true
        else
            t[n] = t[n] or false
        end
    end
    -- this might obscure primitive callbacks (this is intended)
    for n,f in pairs(own_callbacks) do
        if f then
            t[n] = t[n] or true
        else
            t[n] = t[n] or false
        end
    end
    return t
end

--1 registering callbacks

local function register_simple(cb,f)
    -- prefer user-defined callbacks over built-in
    local own = own_callbacks[cb]
    log ('callback %s: %s (%s)', f == nil and 'removed' or f and 'set' or 'disabled',
            cb, own == nil and 'primitive' or 'user-defined')
    if own == nil then -- may be set to ‘false’
        return primitive_register(cb, f)
    else
        own_callbacks[cb] = f or false -- ‘nil’ would delete the callback
        return -1
    end
end

-- will be redefined later

function M.register(cb, f)
    local list = callback_lists[cb]
    if list then
        if f == nil then
            return tex.error('Use ‘deregister’ for removing list callbacks')
        else
            list[#list+1] = f
            log('callback set: %s (#%d on list)', cb, #list)
            return -2
        end
    end
    local stack = callback_stacks[cb]
    if stack then
        if f == nil then -- pop
            local p = stack[#stack]
            stack[#stack] = nil
            return register_simple(cb,p)
        else             -- push
            stack[#stack+1] = M.find(cb)
            return register_simple(cb,f)
        end
    end
    return register_simple(cb, f)
end

function M.deregister(cb, f)
    local list = callback_lists[cb]
    if list then
        for i,g in ipairs(list) do
            if f == g then
                log('callback removed: %s (#%d on list)', cb, i)
                table.remove(list, i)
                return true, -2
            end
        end
        return false
    end
    local stack = callback_stacks[cb]
    if stack then
        for i,g in ipairs(stack) do
            if f == g then
                log('callback removed: %s (#%d on stack)', cb, i)
                table.remove(stack, i)
                return true, -3
            end
        end
        -- no return: fall through to next
    end
    if f == M.find(cb) then
        return true, register_simple(cb, nil)
    end
end

--1 lists of callback functions

local function call_list_node (lst)
    return function (head, ...)
        local list = callback_lists[lst]
        for _,f in ipairs(list) do
            local newhead = f(head,...)
            if node.is_node(newhead) then
                head = newhead
            elseif newhead == false then
                return false
            end
        end
        return head
    end
end

local function call_list_data (lst)
    return function (str)
        local list = callback_lists[lst]
        for _,f in ipairs(list) do
            str = f(str) or str
        end
        return str
    end
end

local function call_list_simple (lst)
    return function (...)
        local list = callback_lists[lst]
        for _,f in ipairs(list) do
            f(...)
        end
    end
end

--1 creating and calling callbacks

local function register_list (lst, fn)
    M.register (lst, fn(lst))
    callback_lists[lst] = {}
end

local function stack_callback (cb)
    callback_stacks[cb] = {}
end

function M.new_callback (name, prop)
    own_callbacks[name] = false -- false means empty here
    if prop == 'stack' then
        stack_callback (name)
    elseif prop == 'node' then
        register_list (name, call_list_node)
    elseif prop == 'simple' then
        register_list (name, call_list_simple)
    elseif prop == 'data' then
        register_list (name, call_list_data)
    end
end

function M.call_callback (name, ...)
    local f = own_callbacks[name]
    if f then
        return f (...)
    else
        return false
    end
end

-- 1 replace the primitive registering

-- TODO: preserve return values
local primitively_registered = { }
function M.primitiveregister(cb, f)
    local rv = false
    if f == nil then
        f = primitively_registered[cb]
        if f == nil then
            rv = M.register(cb)
        else
            _, rv = M.deregister(cb, f)
        end
    else
        rv = M.register(cb, f)
    end
    alog(' through primitive interface')
    primitively_registered[cb] = f
    return rv
end


--1 initialisation

-- save all registered callbacks
if not luatexbase then
    for n,s in pairs(primitives.list()) do
        if s then
            do_log('save callback: %s', n)
            primitively_registered[n] = primitives.find(n)
        end
    end
end

-- string processing callbacks
register_list ('process_input_buffer', call_list_data)
register_list ('process_output_buffer', call_list_data)
register_list ('process_jobname', call_list_data)

-- node list processing callbacks
register_list ('pre_linebreak_filter', call_list_node)
register_list ('post_linebreak_filter', call_list_node)
--register_list ('append_to_vlist_filter', call_list_node) -- TODO this breaks something
register_list ('hpack_filter', call_list_node)
register_list ('vpack_filter', call_list_node)
register_list ('pre_output_filter', call_list_node)

-- mlist_to_mlist and mlist_to_mlist
M.new_callback ('mlist_to_mlist', 'node')
M.new_callback ('mlist_to_hlist', 'stack')
M.register ('mlist_to_hlist', node.mlist_to_hlist )
primitive_register ('mlist_to_hlist', function (head, ...)
    local newhead = M.call_callback ('mlist_to_mlist', head, ...)
    if newhead ~= true then
        head = newhead or head
    end
    newhead = M.call_callback ('mlist_to_hlist', head, ...)
    return newhead
end)

-- simple listable callbacks
register_list ('contribute_filter', call_list_simple)
register_list ('pre_dump', call_list_simple)
register_list ('wrapup_run', call_list_simple)
register_list ('finish_pdffile', call_list_simple)
register_list ('finish_pdfpage', call_list_simple)
register_list ('insert_local_par', call_list_simple)

register_list ('ligaturing', call_list_simple)
register_list ('kerning', call_list_simple)

-- stack callbacks
stack_callback ('hpack_quality')
stack_callback ('vpack_quality')
stack_callback ('hyphenate')
stack_callback ('linebreak_filter')
stack_callback ('buildpage_filter')
stack_callback ('build_page_insert')

-- process_rule
M.new_callback ('process_rule', 'simple')
primitive_register ('process_rule', function (rule, ...)
    local p = own_callbacks[rule.index]
    if p then
        p (rule, ...)
    else
        M.call_callback ('process_rule')
    end
end)

-- restore all registered callbacks
for n,f in pairs(primitively_registered) do
    do_log('restore callback: %s', n)
    M.primitiveregister (n,f)
end
saved = nil

--

-- replace primitive callbacks
callback.find     = M.find
callback.list     = M.list
callback.register = M.primitiveregister

log = do_log
local function alog(msg, ...)
    texio.write('log', string.format(msg, ...))
end

return M


