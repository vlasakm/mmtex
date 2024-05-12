
local M = { }
local alloc = require('minim-alloc')
local cb = require('minim-callbacks')
alloc.remember('minim-hooks')
alloc.remember('minim-pdf')

-- 1 helper functions

local HLIST_NODE = node.id 'hlist'
local GLUE_NODE = node.id 'glue'
local GLYPH_NODE = node.id 'glyph'
local RULE_NODE = node.id 'rule'
local DISC_NODE = node.id 'disc'
local WHATSIT_NODE = node.id 'whatsit'
local USER_DEFINED = node.subtype 'user_defined'
local START_LINK = node.subtype 'pdf_start_link'

local function insert_formatted(t, ...)
    table.insert(t, string.format(...))
end

local function add_to_catalog(...)
    pdf.setcatalog((pdf.getcatalog() or '') .. string.format(...) .. ' ')
end

local function add_to_names(...)
    pdf.setnames((pdf.getnames() or '') .. string.format(...) .. ' ')
end

local pdf_name = alloc.pdf_name
local pdf_string = alloc.pdf_string
local options_scanner = alloc.options_scanner

-- is this table empty?
local function is_empty(t)
    for _, _ in pairs(t or {}) do
        return false
    end
    return true
end

-- has this table just one element?
local function singleton(t)
    local one = false
    for _, _ in pairs(t) do
        if one then
            return false
        else
            one = true
        end
    end
    return one
end

-- in-depth node list traversal; returns current and parent node
-- only dives into hbox, vbox and ins nodes, and in disc no-break text
-- returns node and enclosing box
local function full_traverse(head)
    return function(stack, last)
        local next = last.next
        if not next then
            next, stack.box = table.unpack(table.remove(stack))
        else
            while next.list do
                table.insert(stack, { next, stack.box })
                next, stack.box = next.list, next
            end
        end
        return next, stack.box
    end, { { } }, { next = head }
end

local function pdf_err(n, msg, ...)
    local m = node.new('whatsit', 'pdf_literal')
    m.mode, m.token = 2, '%% Warning: '..string.format(msg, ...)
    node.insert_after(n, n, m)
end

-- 1 infrastructure and bookkeeping

local function tagging_enabled()
    return tex.count['writedocumentstructure'] > 0
end

local function spaces_enabled()
    return tex.count['writehyphensandspaces'] > 0
end

-- we start with the document at the top level
local structure = { {
    index    = 1,
    struct   = 'Document',
    children = { },
} }

-- the parent tree will be filled automatically and separately
local parent_tree = { } -- list of list of structure elements

-- Our four helper attributes
local current_struct = alloc.registernumber('tagging:current:se')
local current_order  = alloc.registernumber('tagging:element:order')
local current_status = alloc.registernumber('tagging:current:status')
local current_lang   = alloc.registernumber('tagging:current:language')

local function current_structure_element()
    return structure[tex.attribute[current_struct]]
end

-- Marker whatsits
local marker_whatsit = alloc.new_whatsit('tagged pdf marker')

local function make_whatsit(t, se, order)
    local n = node.new('whatsit', 'user_defined');
    n.user_id, n.type = marker_whatsit, 108
    n[current_struct] = se or tex.attribute['tagging:current:se']
    n[current_order] = order or tex.attribute['tagging:element:order']
    n.value = t
    return n
end

alloc.luadef('tagging:mci:content', function()
    node.write(make_whatsit{ what = 'content' })
end, 'protected')
alloc.luadef('tagging:mci:markstart', function()
    node.write(make_whatsit{ what = 'mci_start' })
end, 'protected')
alloc.luadef('tagging:mci:markstop', function()
    node.write(make_whatsit{ what = 'mci_stop' })
end, 'protected')
alloc.luadef('tagging:art:markstart', function()
    node.write(make_whatsit{ what = 'art_start', it = token.scan_string() })
end, 'protected')
alloc.luadef('tagging:art:markstop', function()
    node.write(make_whatsit{ what = 'art_stop' })
end, 'protected')

-- 1 structure type table and type aliases

local structure_types = alloc.saved_table('structure types', {
    -- grouping types that may carry a bookmark
    Document   = { type = 'section' },
    Part       = { type = 'section' },
    Art        = { type = 'section' },
    Sect       = { type = 'section' },
    Div        = { type = 'group' },
    -- grouping elements
    BlockQuote = { type = 'group' },
    Caption    = { type = 'group' },
    TOC        = { type = 'group', contains = { TOC=1, TOCI=1, Caption=1 } },
    TOCI       = { contains = { Lbl=1, Reference=1, P=1, NonStruct=1, TOC=1 }, contained = { TOC=1 } },
    Index      = { type = 'group' },
    NonStruct  = { type = 'none' }, -- meaningless grouping
    -- illustration elements
    Figure     = { type = 'inline', needsalt=1 },
    Formula    = { type = 'inline', needsalt=1 },
    Form       = { type = 'inline', needsalt=1 },
    -- block level structure elements (BLSE)
    P          = { type = 'block' },
    H          = { type = 'block' },
    H1         = { type = 'block' }, -- for nonhierarchical tagging (do not use?)
    H2         = { type = 'block' }, --         __________ „ __________
    H3         = { type = 'block' }, --         __________ „ __________
    H4         = { type = 'block' }, --         __________ „ __________
    H5         = { type = 'block' }, --         __________ „ __________
    H6         = { type = 'block' }, --         __________ „ __________
    L          = { type = 'block',  contains = { LI=1, Caption=1 } },
    LI         = { contains = { Lbl=1, LBody=1 }, contained = { L=1 } },
    LBody      = { type = 'contain', contained = { LI=1 } },
    Lbl        = { type = 'block', contained = { Note=1, Bibentry=1, LI=1, TOCI=1 } },
    -- tables (neither BLSE nor ILSE)
    Table      = { type = 'block', contains = { TR=1, THead=1, TBody=1, TFoot=1, Caption=1 } },
    THead      = { contains = { TR=1 }, contained = { Table=1 } },
    TBody      = { contains = { TR=1 }, contained = { Table=1 } },
    TFoot      = { contains = { TR=1 }, contained = { Table=1 } },
    TR         = { contains = { TH=1, TD=1 }, contained = { THead=1, TBody=1, TFoot=1 } },
    TH         = { type = 'contain', contained = { TR=1 } }, -- header cell
    TD         = { type = 'contain', contained = { TR=1 } }, -- data cell
    -- inline structure elements ILSE
    Span       = { type = 'inline' },
    Quote      = { type = 'inline' },
    Note       = { type = 'extern' },
    Reference  = { type = 'inline' },
    BibEntry   = { type = 'inline' },
    Code       = { type = 'inline', attributes = { ['CSS-2.00'] = { ['white-space'] = '(pre)' } } },
    Link       = { type = 'inline' }, -- contains link objects
    Annot      = { type = 'inline' }, -- contains other annotations
    -- ruby/warichu
    Ruby       = { type = 'inline', contains = { RB=1, RT=1, RP=1 } },
    RB         = { contains = { }, contained = { Ruby=1 } },
    RT         = { contains = { }, contained = { Ruby=1 } },
    RP         = { contains = { }, contained = { Ruby=1 } },
    Warichu    = { type = 'inline', contains = { WT=1, WP=1 } },
    WT         = { contains = { }, contained = { Warichu=1 } },
    WP         = { contains = { }, contained = { Warichu=1 } },
})

local structure_type_compatibility = {
    none    = { none=1, section=1, group=1, block=1, inline=1, contain=1 },
    section = { none=1, section=1, group=1, block=1 },
    group   = { none=1, group=1, block=1 },
    extern  = { none=1, group=1, block=1 },
    block   = { none=1, inline=1, extern=1 },
    inline  = { none=1, inline=1, extern=1 },
    contain = { none=1, inline=1, block=1, group=1, extern=1 },
}

local function check_structure_compatibility(parent, child, childtype)
    local p, c = structure_types[parent], structure_types[child]
    childtype = childtype or c.type
    if p.contains then
        return p.contains[child]
    elseif c.contained then
        return c.contained[parent]
    elseif childtype == 'section' and parent == child then
        return false
    else
        return structure_type_compatibility[p.type][childtype]
    end
end

local function determine_parent_node(current, se)
    local c = current
    if tex.count['strictstructuretagging'] > 0 then
        c = check_structure_compatibility(c.struct, se.struct, c.type) and c
    else
        while c and not check_structure_compatibility(c.struct, se.struct, c.type) do
            c = c.parent
        end
    end
    if not c then
        if tagging_enabled() then
            alloc.err('Structure type mismatch: %s in %s',
                    pdf_name(se.struct), pdf_name(current.struct))
        else
            alloc.msg('Warning (minim-pdf): Structure type mismatch (%s in %s)',
                    pdf_name(se.struct), pdf_name(current.struct))
        end
    end
    return c or current
end

function M.add_structure_alias(stype, alias, settings)
    local t, attr = { }, { }
    local info = structure_types[stype] or
        alloc.err('Unknown structure type ‘%s’', stype) and {}
    for k, v in pairs(info) do t[k] = v end
    for k,v in pairs(t.attributes or {}) do attr[k] = v end -- copy to new table
    t.attributes = nil
    for k, v in pairs(settings or {}) do t[k] = v end -- may re-set attributes
    for k,v in pairs(t.attributes or {}) do attr[k] = v end
    if #attr > 0 then t.attributes = attr end
    for _, s in pairs(structure_types) do
        if s.contains and s.contains[stype] then s.contains[alias] = 1 end
        if s.contained and s.contained[stype] then s.contained[alias] = 1 end
    end
    t.aliasof, t.inuse = t.aliasof or stype, false
    structure_types[alias] = t
end

alloc.luadef('struct:addalias', function()
    local settings = load(token.scan_string())()
    local stype    = token.scan_string()
    local alias    = token.scan_string()
    M.add_structure_alias(stype, alias, settings)
end, 'protected')

-- 1 writing the document structure

local function stable_sort_on_order_field(unsorted)
    -- n.b. ‘unsorted’ is likely to closely resemble two concatenated
    -- monotonously increasing lists.
    local sorted, oldsorted = { unsorted[1] }
    local i, next, c = 2, unsorted[2], nil
    while next do
        oldsorted, sorted = sorted, { }
        for _, e in ipairs(oldsorted) do
            c = e.order
            while next and next.order < c do
                table.insert(sorted, next);
                i = i+1; next = unsorted[i]
            end
            table.insert(sorted, e);
        end
        while next and c <= next.order do
            c = next.order
            table.insert(sorted, next);
            i = i+1; next = unsorted[i]
        end
    end
    return sorted
end

local function format_K_array(se)
    local res = { '[' }
    for _, k in ipairs(stable_sort_on_order_field(se.children)) do
        se.mainpage = se.mainpage or k.pageobj
        if k.mcid then
            if se.mainpage == k.pageobj then
                insert_formatted(res, '%d', k.mcid)
            else
                insert_formatted(res, '<< /Type/MCR /Pg %d 0 R /MCID %d >>', k.pageobj, k.mcid)
            end
        elseif k.children then
            insert_formatted(res, '%s 0 R', k.objnum)
        else
            if se.mainpage == k.pageobj then
                insert_formatted(res, '<< /Type/OBJR /Obj %d 0 R >>', k.objnum)
            else
                insert_formatted(res, '<< /Type/OBJR /Obj %d 0 R /Pg %s 0 R >>', k.objnum, k.pageobj)
            end
        end
    end
    table.insert(res, ']')
    return table.concat(res, ' ')
end

local function make_rolemap()
    local aliases = { }
    for k, v in pairs(structure_types) do
        if v.aliasof and v.inuse and v.aliasof ~= k then
            insert_formatted(aliases, '%s%s', pdf_name(k), pdf_name(v.aliasof))
        end
    end
    if #aliases > 0 then
        return '\n/RoleMap << ' .. table.concat(aliases,' ') .. ' >>'
    end
    return ''
end

local function make_attributes(res, t)
    -- is there just one attribute?
    local list = not singleton(t)
    if list then table.insert(res, '[') end
    for ao, ac in pairs(t) do
        insert_formatted(res, '<< /O %s', pdf_name(ao))
        for k,v in pairs(ac) do
            insert_formatted(res, '%s %s', pdf_name(k), v)
        end
        table.insert(res, '>>')
    end
    if list then table.insert(res, ']') end
end

local attribute_classes = alloc.saved_table('attribute classes')
local function make_classmap()
    local classes = { }
    for c, as in pairs(attribute_classes) do
        insert_formatted(classes, '\n%s', pdf_name(c))
        make_attributes(classes, as)
    end
    if #classes > 0 then
        return '\n/ClassMap << ' .. table.concat(classes, ' ') .. ' >>'
    end
    return ''
end

local function write_structure()
    if #structure == 1 then return end
    -- reserve object numbers, prepare for writing
    local root_obj, parent_tree_obj = pdf.reserveobj(), pdf.reserveobj()
    local id_tree, id_tree_obj = { }, pdf.reserveobj()
    structure[1].parent = { objnum = root_obj }
    for _, se in ipairs(structure) do
        if not se.hidden then
            se.objnum = pdf.reserveobj()
            if se.id then
                id_tree[se.id] = se.objnum
            end
        end
    end
    -- update the document catalog
    if tex.count['pdfuaconformancelevel'] > 0 then
        add_to_catalog('/MarkInfo << /Marked true /Suspects false >>')
    else
        add_to_catalog('/MarkInfo << /Marked true >>')
    end
    add_to_catalog('/StructTreeRoot %s 0 R', root_obj)
    -- write the structure tree root
    pdf.immediateobj(root_obj, string.format(
        '<< /Type/StructTreeRoot /K %d 0 R /ParentTree %d 0 R /IDTree %d 0 R%s%s >>',
            structure[1].objnum, parent_tree_obj, id_tree_obj, make_rolemap(), make_classmap()))
    -- write structure elements
    for _, se in ipairs(structure) do
        if not se.hidden then
            local res = { '<<' }
            insert_formatted(res, '/Type/StructElem /S%s /P %d 0 R', pdf_name(se.struct), se.parent.objnum)
            if se.id then insert_formatted(res, '/ID %s', pdf_string(se.id)) end
            if se.lang and se.lang ~= se.parent.lang then insert_formatted(res, '/Lang %s', pdf_string(se.lang)) end
            if se.alt then insert_formatted(res, '/Alt %s', pdf_string(se.alt)) end
            if se.actual then insert_formatted(res, '/ActualText %s', pdf_string(se.actual)) end
            if se.title then insert_formatted(res, '/T %s', pdf_string(se.title)) end
            if #se.children > 0 then insert_formatted(res, '\n/K %s', format_K_array(se)) end
            if se.mainpage then insert_formatted(res, '/Pg %d 0 R', se.mainpage) end
            if se.class then
                table.insert(res, '/C')
                if #se.class > 1 then table.insert(res, '[') end
                for _, c in ipairs(se.class) do
                    insert_formatted(res, '%s', pdf_name(c))
                end
                if #se.class > 1 then table.insert(res, ']') end
            end
            if se.ref then
                table.insert(res, '/Ref')
                table.insert(res, '[')
                for _, c in ipairs(se.ref) do
                    local onum = id_tree[c]
                    if onum then
                        insert_formatted(res, '%d 0 R', onum)
                    else
                        alloc.err('Invalid structure element ID: %s', c)
                    end
                end
                table.insert(res, ']')
            end
            if not is_empty(se.attributes) then
                table.insert(res, '/A')
                make_attributes(res, se.attributes)
            end
            if se.files then
                table.insert(res, '/AF [')
                for _, fs in ipairs(se.files) do
                    insert_formatted(res, '%d 0 R', fs)
                end
                table.insert(res, ']')
            end
            table.insert(res, '>>')
            pdf.immediateobj(se.objnum, table.concat(res, ' '))
        end
    end
    -- write the parent tree (a number tree)
    local res = { '<< /Nums [' }
    for i, parents in ipairs(parent_tree) do
        -- i, parents = StructParents index + 1, list of structure elems
        if type(parents) == 'number' then
            table.insert(res, string.format('%d %d 0 R', i-1, structure[parents].objnum))
        else
            local entry = { }
            insert_formatted(entry, '%d [', i-1)
            for _, p in ipairs(parents) do
                insert_formatted(entry, '%d 0 R', p.objnum)
            end
            table.insert(entry, ']')
            table.insert(res, table.concat(entry, ' '))
        end
    end
    table.insert(res, '] >>')
    pdf.immediateobj(parent_tree_obj, table.concat(res, '\n'))
    -- write the id tree (a name tree)
    local ids = { }
    for k, _ in pairs(id_tree) do
        -- luatex uses the C locale,
        table.insert(ids, k)
    end
    table.sort(ids)
    res = { '<< /Names ['}
    for _, id in ipairs(ids) do
        insert_formatted(res, '%s %d 0 R', pdf_string(id), id_tree[id])
    end
    table.insert(res, '] >>')
    pdf.immediateobj(id_tree_obj, table.concat(res, '\n'))
end

-- 1 languages

-- name|code ↦ nr & nr ↦ code
local language_codes = alloc.saved_table('language codes')

function M.set_language_code(name, code)
    if not language_codes[code] then
        table.insert(language_codes, code)
        language_codes[code] = #language_codes
    end
    language_codes[name] = language_codes[code]
end

if not language_codes.sumerian then
    local defaults = require('minim-languagecodes')
    for name, code in pairs(defaults) do
        M.set_language_code(name, code)
    end
end

-- \setlanguagecode dutch nl_BE
alloc.luadef('setlanguagecode', function()
    M.set_language_code(token.scan_string(), token.scan_string())
end, 'protected')

function M.get_language_code(name_or_code)
    local nr = language_codes[name_or_code]
    return nr and language_codes[nr] or name_or_code
end

function M.get_current_language_code()
    return language_codes[tex.attribute['tagging:current:language']]
end

function M.set_document_language(code)
    structure[1].lang = code
end

alloc.luadef('setdocumentlanguage', function()
    M.set_document_language(M.get_language_code(token.scan_string()))
end, 'protected')

-- \uselanguage patch; provide default document language
-- and associate names with numbers
cb.register('uselanguage', function(name)
    local nr = language_codes[name] or alloc.err('No language code known for ‘%s’', name) and 1
    if not structure[1].lang then M.set_document_language(language_codes[nr]) end
    tex.attribute['tagging:current:language'] = nr
end)

local function write_language()
    add_to_catalog('/Lang %s', pdf_string(structure[1].lang or 'und'))
end

-- 1 marking structure elements

local function get_ancestor_of_type(se, stype)
    while se and se.struct ~= stype do
        if se.level == -1000 then return end
        se = se.parent
    end
    return se and se.parent
end

function M.close_structure_node(stype, raiseerror)
    local strict = tex.count['strictstructuretagging'] > 0
    local current, open = current_structure_element()
    if strict then
        open = current.struct == stype and current.parent
    else
        open = get_ancestor_of_type(current, stype)
    end
    if open then
        tex.setattribute(current_struct, open.index)
    elseif strict then
        alloc.err('Cannot close structure element %s: %s still open', stype, current.struct)
    elseif raiseerror then
        alloc.err('Cannot close structure element %s: no open tag found', stype)
    end
end

alloc.luadef('tagging:stopelement', function()
    M.close_structure_node(token.scan_string(), true)
end, 'protected')

alloc.luadef('tagging:ensurestopelement', function()
    M.close_structure_node(token.scan_string(), false)
end, 'protected')

function M.open_structure_node(n)
    -- retrieve defaults for the structure type
    local info = structure_types[n.struct]
    if not info then
        alloc.err('Unknown structure type %s replaced with NonStruct', n.struct)
        n.struct, info = 'NonStruct', structure_types.NonStruct
    end
    info.inuse = true
    -- attributes: set default from se info
    n.attributes = n.attr or { }; n.attr = nil
    if info.attributes then
        for o,kv in pairs(info.attributes) do
            n.attributes[o] = n.attributes[o] or { }
            for k, v in pairs(kv) do
                n.attributes[o][k] = n.attributes[o][k] or v
            end
        end
    end
    -- bookkeeping: order and parent can be forced (needed for asynchronous elements)
    n.index = #structure + 1
    n.children = { }
    n.order = n.order or tex.getattribute(current_order)
    n.parent = (n.parent and structure[n.parent])
        or determine_parent_node(current_structure_element(), n)
    table.insert(structure, n)
    -- determine the proper language code
    if n.lang then
        n.lang = M.get_language_code(n.lang)
    else
        local lang = tex.getattribute(current_lang)
        n.lang = language_codes[lang]
    end
    -- hacks for out-of-sync elements
    if not n.hidden then table.insert(n.parent.children, n) end
    if not n.async then tex.setattribute(current_struct, #structure) end
end

alloc.luadef('tagging:startelement', function()
    local s = options_scanner()
        :string('id')
        :string('ref', true)
        :string('type') -- 'section', 'group', 'block' etc.
        :argument('alt')
        :argument('actual')
        :argument('title')
        :string('lang')
        :subtable('attr')
        :string('class', true)
        :scan()
    s.struct = token.scan_string()
    M.open_structure_node(s)
end, 'protected')

alloc.luadef('tagging:alt', function()
    current_structure_element().alt = token.scan_string()
end)

alloc.luadef('tagging:actual', function()
    current_structure_element().actual = token.scan_string()
end)

local function add_attribute(se, o, k, v)
    se.attributes = se.attributes or { }
    se.attributes[o] = se.attributes[o] or { }
    se.attributes[o][k] = v
end

alloc.luadef('tagging:attribute', function()
    add_attribute(current_structure_element(),
        token.scan_string(), token.scan_string(), token.scan_string())
end)

alloc.luadef('tagging:ignore:attribute', function()
    -- if \tagging:enabled is false
    token.scan_string()
    token.scan_string()
    token.scan_string()
end)

alloc.luadef('newattributeclass', function()
    local s = options_scanner():subtable('attr')
    attribute_classes[token.scan_string()] = s:scan().attr
end, 'protected')

alloc.luadef('tagging:tagid', function()
    current_structure_element().id = token.scan_string()
end)

alloc.luadef('tagging:getshowstructure', function()
    local e, lst = current_structure_element(), { string.format ('%d',
        tex.attribute[current_struct]) }
    while e do
        table.insert(lst, string.format('%s (%d)', e.struct, e.index))
        e = e.parent
    end
    tex.toks['tagging:showtoks'] = table.concat(lst, ' < ')
end, 'protected')

-- 1 marking content items

-- All content items should be explicitly opened and closed, per page, by the 
-- late_lua nodes constructed beneath. After the page is finished, the MCIDs 
-- will be stored in the parent tree entry associated to the page.

-- For the insertion of these late_lua nodes, see the next section; this one 
-- only deals with the bookkeeping mechanics.

-- Note that we do not nest artifacts within marked content items. This would 
-- be allowed by the spec, but confuses some pdf readers (e.g. poppler).

local mcid_list, pageobj

local function clear_page_tagging_parameters()
    mcid_list, pageobj = { }, nil
    _open_mci_node_ = function (se_num, order)
        pageobj = pageobj or pdf.getpageref(status.total_pages + 1)
        local se = structure[se_num]
        pdf.print(string.format('%s <</MCID %d>> BDC ', pdf_name(se.struct), #mcid_list))
        table.insert(se.children, { mcid = #mcid_list, order = order, pageobj = pageobj })
        table.insert(mcid_list, se)
        -- unhide hidden parents (done here to preserve the correct order)
        if se.hidden then
            table.insert(se.parent.children, se)
            se.hidden = false
        end
    end
end
clear_page_tagging_parameters()

local function new_open_mci_node(se, order)
    local n = node.new('whatsit', 'late_lua')
    n.token = string.format('_open_mci_node_(%d, %d)', se, order)
    return n
end

local function pdf_literal(token)
    local n = node.new('whatsit', 'pdf_literal')
    n.mode, n.token = 1, token
    return n
end

local open_artifacts = { }

cb.register('finish_pdfpage', function(shippingout)
    if shippingout then
        local pageattr = string.gsub(pdf.getpageattributes() or '', ' */StructParents %d+', '' )
        if #mcid_list > 0 then
            pageattr = pageattr..string.format('/StructParents %d', #parent_tree)
            table.insert(parent_tree, mcid_list)
        end
        pdf.setpageattributes(pageattr)
        clear_page_tagging_parameters()
    end
end)

-- 1 content item boundaries and linking (in pre-shipout)

function M.mark_content_items(box)
    local se, order, art, open
    local start_node, end_node, parent_node
    local lastpageobj = pdf.getpageref(status.total_pages + 1)
    -- helper functions for inserting mci markers
    local insert_tags = function(end_parent)
        if not open then return end
        parent_node.list = node.insert_before(parent_node.list, start_node, open)
        node.insert_after(end_parent.list, end_node, pdf_literal('EMC'))
        start_node, end_node, parent_node, open = nil, nil, nil, nil
    end
    local start_content = function(n, b)
        se, order = n[current_struct], n[current_order]
        start_node, end_node, parent_node = n, n, b
    end
    -- traversing all nodes
    for n, b in full_traverse(box) do
        local marker = n.id == WHATSIT_NODE and n.subtype == USER_DEFINED
           and n.user_id == marker_whatsit and n.value
        local stat = n[current_status]
        -- first we start with marking artifacts
        if marker and marker.what == 'art_start' then
            insert_tags(b)
            start_content(n, b)
            local a = string.format('/Artifact << /Type/%s >> BDC', marker.it)
            open_artifacts[stat], open, art = a, pdf_literal(a), stat
        elseif marker and marker.what == 'art_stop' then
            end_node = n
            insert_tags(b)
            if art then open_artifacts[art], art = nil, nil end
        elseif stat and stat >10 and stat ~=art then -- broken artifact
            insert_tags(b);
            start_content(n, b)
            local a = open_artifacts[stat]
            if not a then
                alloc.err('Encountered tail of unknown artifact (see pdf)')
                pdf_err(n, 'unknown artifact nr. %d (this should not be possible)', stat)
                a = '/Artifact << /Type/Unknown >> BDC'
            end
            open, art = pdf_literal(a), stat
        elseif stat then -- inside artifact or tagging disabled
            end_node = n
        -- then attach links to Link elements
        elseif n.id == WHATSIT_NODE and n.subtype == START_LINK then
            local _se, _order = n[current_struct], n[current_order]
            local link = structure[_se]
            if link.struct == 'Link' then
                table.insert(link.children, { objnum = n.objnum, order = _order, lastpageobj = lastpageobj })
                n.link_attr = string.format('%s /StructParent %d', n.link_attr, #parent_tree)
                table.insert(parent_tree, _se)
            else
                alloc.err('Link found outside Link structure element (see pdf)')
                pdf_err(n, 'unmarked link')
            end
        -- handle explicit start and stop nodes
        elseif marker and marker.what == 'mci_start' then
            insert_tags(b);
            start_content(n, b)
            open = new_open_mci_node(se, order)
        elseif marker and marker.what == 'mci_stop' then
            end_node = end_node and n; insert_tags(b)
        -- finally, see if we need to intervene between content nodes
        elseif n.id == RULE_NODE or n.id == GLYPH_NODE or n.id == DISC_NODE
        or marker and marker.what == 'content' then
            local _se, _order = n[current_struct], n[current_order]
            if n.id == RULE_NODE and (n.width == 0 or n.height == 0 and n.depth == 0) then
                -- ignore invisible rules
            elseif not _se or not _order then
                -- unmarkable content should not be possible (but is)
                alloc.err('Unmarkable content on page %d (see pdf)', status.total_pages + 1)
                pdf_err(n, 'possible unmarked content')
            elseif se ~= _se or order ~= _order or not end_node then
                -- new content item on changing attributes
                insert_tags(b);
                start_content(n, b)
                open = new_open_mci_node(se, order)
            else -- nothing changed: continue current mci
                end_node = n
            end
        elseif n.id == GLUE_NODE and n.subtype > 2 and n.subtype < 8 then
        -- parskip or displayskip always closes mci
            insert_tags(b)
        end
    end
    -- close the last mci
    insert_tags(box)
end

cb.register('pre_shipout', function(nr)
    if tagging_enabled() then
        M.mark_content_items(tex.box[nr])
    end
end)

-- 1 links and destinations

local dest_count = alloc.new_count('link dest count')
local function new_dest_name()
    local dest_nr = tex.count[dest_count] + 1
    tex.setcount('global', dest_count, dest_nr)
    return 'hyper:dest:'..dest_nr
end

local function last_dest_name()
    return 'hyper:dest:'..tex.count[dest_count]
end

local function write_new_dest()
    local name = new_dest_name()
    tex.sprint(string.format('\\nameddestination{%s}', name))
    return name
end

-- make available as \newdestinationname, \lastdestinationname
alloc.luadef('newdestinationname', function() tex.sprint(new_dest_name()) end)
alloc.luadef('lastdestinationname', function() tex.sprint(last_dest_name()) end)

-- provide the arguments to \pdfextension startlink
local link_types = { }
local function make_link_attr(s)
    local attr = { 'attr {\\csname minim:linkattr\\endcsname' }
    if s.attr then table.insert(attr, s.attr) end
    if s.alt or s.contents then insert_formatted(attr, '/Contents %s', pdf_string(s.alt or s.contents)) end
    table.insert(attr, '}')
    return attr
end
alloc.luadef('hyper:makelink', function()
    local s = options_scanner()
        :argument('alt'):argument('contents') -- same thing
        :argument('attr')
        :scan()
    local type = token.scan_word()
    local userf = link_types[type]
    if not userf then
        alloc.err('Unknown hyperlink type: %s', type)
        userf = link_types.first
    end
    local user = userf()
    local attr = make_link_attr(s)
    tex.sprint(table.concat(attr, ' '))
    tex.sprint('user {')
    tex.write(user)
    tex.sprint('}\\ignorespaces')
end)

local function scan_escaped_argument(chars_to_escape)
    local stored = { }
    for char in string.utfvalues(chars_to_escape) do
        stored[char] = tex.getcatcode(char)
        tex.setcatcode(char, 12)
    end
    local res = token.scan_argument()
    for char, code in pairs(stored) do
        tex.setcatcode(char, code)
    end
    return res
end

function link_types.dest()
    return string.format('/Subtype/Link /A <</S/GoTo /D %s>>', pdf_string(token.scan_argument()))
end
function link_types.url()
    local url = scan_escaped_argument ('~#$%^&_')
    return string.format('/Subtype/Link /A <</S/URI /URI %s>>', pdf_string(url))
end

function link_types.user() return token.scan_argument() end
function link_types.next() return '/Subtype/Link /A <</S/Named /N/NextPage>>' end
function link_types.prev() return '/Subtype/Link /A <</S/Named /N/PrevPage>>' end
function link_types.first() return '/Subtype/Link /A <</S/Named /N/FirstPage>>' end
function link_types.last() return '/Subtype/Link /A <</S/Named /N/LastPage>>' end

-- 1 bookmarks (outlines)

-- start with a dummy top-level bookmark
local bookmarks = { { count = 0, level = 0 } }
structure[1].bookmark = bookmarks[1]

local function write_bookmarks()
    if #bookmarks == 1 then return end
    -- reserve objects in a row
    for i=1, #bookmarks do
        bookmarks[i].outline_obj = pdf.reserveobj()
    end
    -- write outlines object
    add_to_catalog('/Outlines %s 0 R', bookmarks[1].outline_obj)
    pdf.immediateobj(bookmarks[1].outline_obj, string.format(
        ' <</Type /Outlines /First %s 0 R /Last %s 0 R /Count %s >> ',
        bookmarks[2].outline_obj, bookmarks[1].last.outline_obj, #bookmarks - 1))
    -- write bookmark objects
    for i=2, #bookmarks do -- skip the root (i=1)
        local bm, res = bookmarks[i], { }
        insert_formatted(res, '<< /Title %s\n/Parent %s 0 R /Dest %s', pdf_string(bm.title),
            bm.parent and bm.parent.outline_obj or bookmarks[1].outline_obj, pdf_string(bm.dest))
        if bm.next then insert_formatted(res, '/Next %s 0 R', bm.next.outline_obj) end
        if bm.prev then insert_formatted(res, '/Prev %s 0 R', bm.prev.outline_obj) end
        if bm.struct and bm.struct.objnum then -- false if no structures are written out
            insert_formatted(res, '/SE %s 0 R', bm.struct.objnum)
        end
        if bm.count > 0 then
            insert_formatted(res, '/First %s 0 R /Last %s 0 R /Count %s%s',
                bm.first.outline_obj, bm.last.outline_obj, bm.open and '' or '-', bm.count)
        end
        pdf.immediateobj(bm.outline_obj, table.concat(res,'\n')..' >>')
    end
end

function M.add_bookmark(bm)
    local pbm
    if bm.level then
        for i = #bookmarks, 1, -1 do
            pbm = bookmarks[i]
            if pbm.level < bm.level then
                break
            end
        end
    else
        local se = current_structure_element()
        if se.bookmark then
            return alloc.err('Structure element %s already has a bookmark', pdf_name(se.struct))
        end
        se.bookmark, bm.struct = bm, se
        -- derive parent from strucrure
        pbm = se.parent
        while not pbm.bookmark do
            pbm = pbm.parent
        end
        pbm = pbm.bookmark
    end
    -- initial values; links to other bookmarks
    bm.parent, bm.count = false, 0
    bm.dest = bm.dest or write_new_dest()
    if pbm.last then pbm.last.next = bm end
    bm.parent, bm.prev = pbm, pbm.last
    pbm.first, pbm.last = pbm.first or bm, bm
    bm.level = bm.level or (pbm.level + 1)
    -- update the count until the first closed bookmarks
    repeat
        pbm.count = pbm.count + 1
        pbm = pbm.open and pbm.parent
    until not pbm
    -- append to the list
    table.insert(bookmarks, bm)
end

alloc.luadef('outline', function()
    local bm = options_scanner()
        :keyword('open', 'closed')
        :string('dest')
        :int('level')
        :scan()
    bm.title = token.scan_string()
    M.add_bookmark(bm)
end, 'protected')


-- 1 associated files

local attached_files = { }
local function write_fileattachments()
    if #attached_files > 0 then
        table.sort(attached_files, function(a,b) return a.name < b.name end)
        local afs = { '/AF [' }
        local nms = { '<< /Names [' }
        for _, t in ipairs(attached_files) do
            insert_formatted(afs, '%d 0 R', t.objnum)
            insert_formatted(nms, '%s %d 0 R', t.name, t.objnum)
        end
        table.insert(afs, ']')
        table.insert(nms, '] >>')
        add_to_catalog(table.concat(afs, ' '))
        local efs = pdf.immediateobj(table.concat(nms, ' '))
        add_to_names('/EmbeddedFiles %d 0 R', efs)
    end
end

function M.embed_file(t)
    -- default moddate
    if not t.moddate then
        tex.runtoks(function() tex.print('\\csname minim:makedefaultmoddate\\endcsname') end)
        local moddate = tex.toks['embeddedfiles:moddate']
        if moddate ~= '' then t.moddate = moddate end
    end
    -- embed the file
    local attr = { '/Type/EmbeddedFile' }
    if t.mimetype then insert_formatted(attr, '/Subtype%s', pdf_name(t.mimetype)) end
    if t.moddate then insert_formatted(attr, '/Params << /ModDate %s >>', alloc.pdf_date(t.moddate)) end
    local ef = pdf.obj {
        immediate = true,
        compresslevel = t.uncompressed and 0 or nil,
        type = 'stream',
        file = t.file and kpse.find_file(t.file),
        string = t.string,
        attr = table.concat(attr, ' ') }
    -- write the filespec
    local res = { '<< /Type/Filespec' }
    insert_formatted(res, '/F %s /UF %s /EF << /F %d 0 R /UF %d 0 R >>', t.name, t.name, ef, ef)
    if t.desc then insert_formatted(res, '/Desc %s', pdf_string(t.desc)) end
    if t.relation then insert_formatted(res, '/AFRelationship /%s', t.relation) end
    table.insert(res, '>>')
    local fs = pdf.immediateobj(table.concat(res, ' '))
    -- (globally) attach the file
    return fs, ef
end

alloc.luadef('embedfile', function()
    local t = options_scanner()
        :string('desc')
        :string('file')
        :string('string')
        :string('mimetype')
        :string('moddate')
        :string('relation')
        :string('name')
        :keyword('global')
        :keyword('uncompressed')
        :scan()
    if not t.name then
        t.name = t.file or alloc.err('No name specified for embedded file stream')
    end
    t.name = pdf_string(t.name or '(unnamed)')
    local fs, _ = M.embed_file(t, t.global)
    -- where to attach?
    if t.global then
        table.insert(attached_files, { name = t.name, objnum = fs } )
    elseif tagging_enabled() then
        local se = current_structure_element()
        se.files = se.files or { }
        table.insert(se.files, fs)
    else
        alloc.err('In untagged pdf, \\embedfile must be used with ‘global’ keyword')
        table.insert(attached_files, { name = t.name, objnum = fs } )
    end
end, 'protected')


-- 1 hyphenation

function M.mark_discretionaries(head, gc)
    if not spaces_enabled() then return end
    for disc in node.traverse_id(DISC_NODE, head) do
        if disc.subtype ~= 2 then -- ‘automatic’ (exclude explicit hyphens)
            local pre, post, replace = disc.pre, disc.post, disc.replace
            local se, order = disc[current_struct], disc[current_order]
            -- get the replacement text
            local actual = { }
            for c in node.traverse_id(GLYPH_NODE, replace) do
                table.insert(actual, c.char)
            end
            -- special case: a single hyphen
            if #actual == 0 and pre and pre.char and pre.char == 0x2D then
                actual = '­' -- soft hyphen U+00AD
            elseif #actual > 0 then
                actual = string.utfcharacter(table.unpack(actual))
            else
                goto continue
            end
            -- reserve a structure element (but hide it)
            M.open_structure_node { hidden = true, async = true,
                struct = 'Span', parent = se, order = order, actual = actual }
            -- apply the new se to pre and post
            for n, _ in full_traverse(pre) do n[current_struct] = #structure end
            for n, _ in full_traverse(post) do n[current_struct] = #structure end
        end
        ::continue::
    end
    return true
end

cb.register('pre_linebreak_filter', M.mark_discretionaries)

-- 1 spaces

local space_attr = alloc.new_attribute('space insertion marker')

function M.mark_spaces(head, gc)
    if not spaces_enabled() then return end
    for g in node.traverse_id(GLUE_NODE, head) do
        if g.prev and g.subtype == 13 or g.subtype == 14 then -- (x)spaceskip
            local p = g.prev
            p[space_attr] = p.id == GLYPH_NODE and p.font
                or g.next and g.next.id == GLYPH_NODE and g.next.font
                or font.current()
        end
    end
    return true
end

local function create_space(n)
    local s = node.new('glyph')
    s.char, s.font, s.attr = 0x20, n[space_attr], n.attr
    local b = node.hpack(s)
    b.width, b.height, b.depth = 0, 0, 0
    return b
end

local function insert_spaces(head)
    for n in node.traverse(head) do
        if n[space_attr] then
            node.insert_after(head, n, create_space(n))
        end
    end
end

function M.insert_spaces(head, gc)
    if not spaces_enabled() then return end
    for line in node.traverse_id(HLIST_NODE, head) do
        insert_spaces(line.head)
    end
    return true
end

function M.mark_and_insert_spaces(head, gc, ...)
    if not spaces_enabled() then return end
    M.mark_spaces(head, gc)
    insert_spaces(head)
    return true
end

cb.register('pre_linebreak_filter', M.mark_spaces)
cb.register('post_linebreak_filter', M.insert_spaces)
cb.register('hpack_filter', M.mark_and_insert_spaces)

-- 1 page labels

local pagelabels = { }

function M.page_labels(abs_nr, nr, style, prefix)
    table.insert(pagelabels, { start = abs_nr, st = nr, s = style, p = prefix })
end

local pagelabel_styles = {
    Decimal = 'D',
    Roman = 'R',
    roman = 'r',
    Alphabetic = 'A',
    alphabetic = 'a',
    none = false }

alloc.luadef('setpagelabels', function()
    local prefix = token.scan_keyword('prefix') and token.scan_string()
    local style = token.scan_word()
    local nr = token.scan_int()
    local st = pagelabel_styles[style]
    if st == nil then alloc.err('Unknown page label style »%s«', style) end
    M.page_labels(status.total_pages, nr, st, prefix)
end, 'protected')

local function write_pagelabels()
    if #pagelabels == 0 then return end
    if pagelabels[1].start ~= 0 then
        table.insert(pagelabels, 1, { start = 0, st = 1, s = 'D' })
    end
    local res = { '/PageLabels << /Nums [' }
    for _, l in ipairs(pagelabels) do
        local s, p = l.s and '/S/'..l.s, l.p and ' /P '..pdf_string(l.p)
        table.insert(res, string.format('%d << /St %d %s%s >>', l.start, l.st, s or '', p or ''))
    end
    table.insert(res, ']')
    add_to_catalog(table.concat(res, ' '))
end

-- 1 output intents

local output_intents = { }

function M.add_output_intent(t)
    table.insert(output_intents, t)
end

local function write_output_intents()
    if #output_intents == 0 then return end
    local res = { '[' }
    for _, oi in ipairs(output_intents) do
        local p = pdf.obj { type = 'stream',
            file = kpse.find_file(oi.path),
            compresslevel = 9,
            attr = string.format('/N %d', oi.N),
            immediate = true }
        insert_formatted(res, '<< /Type/OutputIntent /DestOutputProfile %d 0 R', p)
        insert_formatted(res, '/S/%s /OutputConditionIdentifier %s', oi.subtype, pdf_string(oi.id))
        if oi.info then insert_formatted(res, '/Info %s', pdf_string(oi.info)) end
        if oi.condition then insert_formatted(res, '/OutputCondition %s', pdf_string(oi.condition)) end
        if oi.registry then insert_formatted(res, '/RegistryName %s', pdf_string(oi.registry)) end
        table.insert(res, '>>')
    end
    table.insert(res, ']')
    local objnum = pdf.immediateobj(table.concat(res, ' '))
    add_to_catalog('/OutputIntents %d 0 R', objnum)
end

function M.add_default_rgb_output_intent(t)
    t = t or {}
    M.add_output_intent {
        subtype = t.subtype or 'GTS_PDFA1',
        info = t.info or 'IEC 61966-2.1 Default RGB colour space - sRGB',
        condition = t.condition,
        registry = 'http://www.iev.ch',
        id = 'IEC sRGB',
        N = 3, path = 'sRGB.icc' }
end

function M.add_default_cmyk_output_intent(t)
    t = t or {}
    M.add_output_intent {
        subtype = t.subtype or 'GTS_PDFA1',
        info = t.info or 'FOGRA39L Coated',
        condition = t.condition or 'FOGRA39L Coated',
        registry = 'http://www.fogra.org',
        id = 'Offset printing, according to ISO 12647-2:2004/Amd 1, OFCOM, paper type 1 or 2 = coated art, 115 g/m2, tone value increase curves A (CMY) and B (K)',
        N = 4, path = 'FOGRA39L_coated.icc' }
end

alloc.luadef('minim:default:rgb:profile', function() M.add_default_rgb_output_intent() end)
alloc.luadef('minim:default:cmyk:profile', function() M.add_default_cmyk_output_intent() end)

-- 1 pdf/ua

alloc.luadef('tagging:enablepdfua', function()
    add_to_catalog('/ViewerPreferences << /DisplayDocTitle true >>')
    local pageattr = pdf.getpageattributes()
    if pageattr then
        pdf.setpageattributes(pageattr .. ' /Tabs /S')
    else
        pdf.setpageattributes('/Tabs /S')
    end
end)

local function perform_pdfua_checks()
    local xmp = require 'minim-xmp'
    if xmp.get_metadata('dc:title') == '' then
        alloc.err('PDF/UA error: no dc:title metadata')
    end
end

--

cb.register('finish_pdffile', function()
    if tex.count['pdfuaconformancelevel'] > 0 then
        perform_pdfua_checks()
    end
    if tagging_enabled() then
        write_language()
        write_structure()
    end
    write_bookmarks()
    write_pagelabels()
    write_output_intents()
    write_fileattachments()
end)

return M

