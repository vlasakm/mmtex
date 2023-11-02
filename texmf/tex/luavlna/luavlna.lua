-- Module luavlna
-- code originally created by Patrick Gundlach
-- http://tex.stackexchange.com/q/27780/2891
-- The code was adapted for plain TeX and added some more features
-- 1. It is possible to turn this functionality only for some letters
-- 2. Code now works even for single letters after brackets etc.
--
--

local M = {}
-- local utf_match = unicode.utf8.match
local utf_char  = utf8.char -- unicode.utf8.char
local utf_len   = utf8.len -- unicode.utf8.len

local glue_id  = node.id "glue"
local glyph_id = node.id "glyph"
local hlist_id = node.id "hlist"
local vlist_id = node.id "vlist"
local penalty_id = node.id "penalty"
local math_id  = node.id "math"
local period_char = string.byte(".")

-- we must process only glues with the spaceskip or xspaceskip subtypes
local allowed_space_names = {spaceskip = true, xspaceskip = true}
local allowed_space_types = {}
local glue_subtypes = node.subtypes("glue")
-- convert allowed subtypes names to numbers used in nodes
for k,v in pairs(glue_subtypes) do
  if allowed_space_names[v] then
    allowed_space_types[k] = true
  end
end

local unicode_alphas = "0041-005A0061-007A00AA00B500BA00C0-00D600D8-00F600F8-02C102C6-02D102E0-02E402EC02EE0370-037403760377037A-037D03860388-038A038C038E-03A103A3-03F503F7-0481048A-05270531-055605590561-058705D0-05EA05F0-05F20620-064A066E066F0671-06D306D506E506E606EE06EF06FA-06FC06FF07100712-072F074D-07A507B107CA-07EA07F407F507FA0800-0815081A082408280840-085808A008A2-08AC0904-0939093D09500958-09610971-09770979-097F0985-098C098F09900993-09A809AA-09B009B209B6-09B909BD09CE09DC09DD09DF-09E109F009F10A05-0A0A0A0F0A100A13-0A280A2A-0A300A320A330A350A360A380A390A59-0A5C0A5E0A72-0A740A85-0A8D0A8F-0A910A93-0AA80AAA-0AB00AB20AB30AB5-0AB90ABD0AD00AE00AE10B05-0B0C0B0F0B100B13-0B280B2A-0B300B320B330B35-0B390B3D0B5C0B5D0B5F-0B610B710B830B85-0B8A0B8E-0B900B92-0B950B990B9A0B9C0B9E0B9F0BA30BA40BA8-0BAA0BAE-0BB90BD00C05-0C0C0C0E-0C100C12-0C280C2A-0C330C35-0C390C3D0C580C590C600C610C85-0C8C0C8E-0C900C92-0CA80CAA-0CB30CB5-0CB90CBD0CDE0CE00CE10CF10CF20D05-0D0C0D0E-0D100D12-0D3A0D3D0D4E0D600D610D7A-0D7F0D85-0D960D9A-0DB10DB3-0DBB0DBD0DC0-0DC60E01-0E300E320E330E40-0E460E810E820E840E870E880E8A0E8D0E94-0E970E99-0E9F0EA1-0EA30EA50EA70EAA0EAB0EAD-0EB00EB20EB30EBD0EC0-0EC40EC60EDC-0EDF0F000F40-0F470F49-0F6C0F88-0F8C1000-102A103F1050-1055105A-105D106110651066106E-10701075-1081108E10A0-10C510C710CD10D0-10FA10FC-1248124A-124D1250-12561258125A-125D1260-1288128A-128D1290-12B012B2-12B512B8-12BE12C012C2-12C512C8-12D612D8-13101312-13151318-135A1380-138F13A0-13F41401-166C166F-167F1681-169A16A0-16EA1700-170C170E-17111720-17311740-17511760-176C176E-17701780-17B317D717DC1820-18771880-18A818AA18B0-18F51900-191C1950-196D1970-19741980-19AB19C1-19C71A00-1A161A20-1A541AA71B05-1B331B45-1B4B1B83-1BA01BAE1BAF1BBA-1BE51C00-1C231C4D-1C4F1C5A-1C7D1CE9-1CEC1CEE-1CF11CF51CF61D00-1DBF1E00-1F151F18-1F1D1F20-1F451F48-1F4D1F50-1F571F591F5B1F5D1F5F-1F7D1F80-1FB41FB6-1FBC1FBE1FC2-1FC41FC6-1FCC1FD0-1FD31FD6-1FDB1FE0-1FEC1FF2-1FF41FF6-1FFC2071207F2090-209C21022107210A-211321152119-211D212421262128212A-212D212F-2139213C-213F2145-2149214E218321842C00-2C2E2C30-2C5E2C60-2CE42CEB-2CEE2CF22CF32D00-2D252D272D2D2D30-2D672D6F2D80-2D962DA0-2DA62DA8-2DAE2DB0-2DB62DB8-2DBE2DC0-2DC62DC8-2DCE2DD0-2DD62DD8-2DDE2E2F300530063031-3035303B303C3041-3096309D-309F30A1-30FA30FC-30FF3105-312D3131-318E31A0-31BA31F0-31FF3400-4DB54E00-9FCCA000-A48CA4D0-A4FDA500-A60CA610-A61FA62AA62BA640-A66EA67F-A697A6A0-A6E5A717-A71FA722-A788A78B-A78EA790-A793A7A0-A7AAA7F8-A801A803-A805A807-A80AA80C-A822A840-A873A882-A8B3A8F2-A8F7A8FBA90A-A925A930-A946A960-A97CA984-A9B2A9CFAA00-AA28AA40-AA42AA44-AA4BAA60-AA76AA7AAA80-AAAFAAB1AAB5AAB6AAB9-AABDAAC0AAC2AADB-AADDAAE0-AAEAAAF2-AAF4AB01-AB06AB09-AB0EAB11-AB16AB20-AB26AB28-AB2EABC0-ABE2AC00-D7A3D7B0-D7C6D7CB-D7FBF900-FA6DFA70-FAD9FB00-FB06FB13-FB17FB1DFB1F-FB28FB2A-FB36FB38-FB3CFB3EFB40FB41FB43FB44FB46-FBB1FBD3-FD3DFD50-FD8FFD92-FDC7FDF0-FDFBFE70-FE74FE76-FEFCFF21-FF3AFF41-FF5AFF66-FFBEFFC2-FFC7FFCA-FFCFFFD2-FFD7FFDA-FFDC"


-- construct table with unicode alphas for later testing
local alpha_tbl = {}
for start, finish in unicode_alphas:gmatch("(....)-(....)") do
  for i = tonumber(start, 16), tonumber(finish, 16) do
    alpha_tbl[utf_char(i)] = true
  end
end




local alpha = string.char(37).."a" -- alpha class, entering 
-- percent char directly caused error
local alphas = {}
-- the following function is not used anymore
-- local match_char = function(x) return utf_match(x,alpha) end
local match_table = function(x, chars)
  local chars=chars or {} 
  return chars[x] 
end 
local singlechars = {} -- {a=true,i=true,z=true, v=true, u=true, o = true} 

local initials = {}

local getchar = function(n)
  local real_char = n.char
  -- test if char is valid utf8 value, return dummy value otherwise
  if (real_char >= 57344 and real_char <= 63743) or (real_char >= 983040 and real_char <= 1048573) or real_char >= 1048576  then 
    return "a" 
  end
  return utf_char(real_char)
end

local main_language = nil

-- when main_language is set, we will not use lang info in the nodes, but 
-- main language instead
local get_language = function(lang)
  return main_language or lang
end

local set_main_language = function(lang)
  main_language = lang
end

local debug = false
local tex4ht = false
-- Enable processing only for certain letters
-- must be table in the {char = true, char2=true} form
local set_singlechars= function(lang,c)
  --print("Set single chars lua")
  if type(lang) == "table" then
    for _,l in pairs(lang) do
      singlechars[l] = c
    end
  else
    local lang = tonumber(lang)
    -- for k,_ in pairs(c) do print(k) end
    singlechars[lang] = c
  end
end

local set_initials = function(lang,c)
  if type(lang) == "table" then
    for _,l in pairs(lang) do
      initials[l] = c
    end
  else
    local lang = tonumber(lang)
    initials[lang]=c
  end
end


local debug_tex4ht = function(head,p)
  --[[ local w = node.new("glyph")
  w.lang = tex.lang
  w.font = font.current()
  w.char = 64
  ]]
  --node.remove(head,node.prev(p))
  local w = node.new("whatsit", "special")
  w.data = "t4ht=<span style='background-color:red;width:2pt;'> </span>"
  return w, head
end

local debug_node = function(head,p)
  local w
  if tex4ht then
    w, head = debug_tex4ht(head,p)
  else
    w = node.new("whatsit","pdf_literal")                          
    w.data = "q 1 0 1 RG 1 0 1 rg 0 0 m 0 5 l 2 5 l 2 0 l b Q"           
  end
  node.insert_after(head,head,w)                                       
  node.insert_after(head,w,p)                                          
  -- return w
end


local set_debug= function(x)
  debug = x
end

local set_tex4ht = function()
  tex4ht = true
end

local insert_penalty = function(head)
  local p = node.new("penalty")                                           
  p.penalty = 10000                                                       
  local debug = debug or false
  if debug then
    local w = debug_node(head,p)
  else
    node.insert_after(head,head,p) 
  end
  return head
end

local replace_with_thin_space = function(head)
  local gluenode = node.new(node.id("glue"))
  local gluespec = node.new(node.id("glue_spec"))
  gluenode.width = tex.sp("0.2em")
  -- gluenode.spec = gluespec
  gluenode.next = head.next
  gluenode.prev = head.prev
  gluenode.next.prev = gluenode
  gluenode.prev.next = gluenode
  return gluenode
end

local is_alpha = function(c)
  local status = alphas[c]
  if not status then 
    status = alpha_tbl[c]
    alphas[c] = status
  end
  return status
end

-- find whether letter is uppercase
local up_table = {}
local is_uppercase= function(c)
  if not is_alpha(c) then return false end
  local status = up_table[c]
  if status ~= nil then
    return status
  end
  status = unicode.utf8.upper(c) == c
  up_table[c] = status
  return status
end

local is_number = function(word)
  return tonumber(string.sub(word, -1)) ~= nil
end

local init_buffer = ""
local is_initial = function(c, lang)
  -- space is not initial
  if c == " " then 
    init_buffer = ""
    return false
  end
  -- look in the initals table
  if lang then
    -- insert the current character to the init_buffer
    -- and try to find the string in the initial table
    -- for the current language
    init_buffer = init_buffer .. c
    local tbl = initials[lang] or {}
    if tbl[init_buffer] then return true end
  end
  return is_uppercase(c)
end

local cut_off_end_chars = function(word, dot)
  local last = string.sub(word, -1)
  while word ~= "" and (not dot or last ~= ".") and not is_alpha(last) do
    word = string.sub(word, 1, -2) -- remove last char
    last = string.sub(word, -1)
  end
  return word
end

local part_until_non_alpha = function(word)
  for i = 1, #word do
    local c = word:sub(i,i)
    if not is_alpha(c) then
      word = string.sub(word, 1, i-1)
      break
    end
  end
  return word
end


function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end


local presi = (require "luavlna-presi")
local si = Set(require "luavlna-si")

local is_unit = function(word)
  if M.no_unit==true then return false end
  word = part_until_non_alpha(word)
  if si[word] then
    return true
  end
  for _, prefix in pairs(presi) do
    s, e = string.find(word, prefix)
    if s == 1 then
      local unit = string.sub(word, e+1)
      if si[unit] then
        return true
      end
    end
  end
  return false
end

local predegrees = Set (require "luavlna-predegrees")
local sufdegrees = Set (require "luavlna-sufdegrees")

local function prevent_single_letter (head)                                   
  local singlechars = singlechars  -- or {} 
  -- match_char matches all single letters, but this method is abbandoned
  -- in favor of using table with enabled letters. With this method, multiple
  -- languages are supported
  local test_fn = match_table -- singlechars and match_table or match_char
  local space = true
  local init = false
  local anchor = head
  local wasnumber = false
  local word = ""
  local no_predegrees = M.no_predegrees
  local no_sufdegrees = M.no_sufdegrees
  local no_initials   = M.no_initials
  local in_math = false
  while head do
    local id = head.id 
    local nextn = head.next
    if nextn == nil then break end
    -- local skip = node.has_attribute(head, luatexbase.attributes.preventsinglestatus) 
    local skip = node.has_attribute(head, M.preventsingleid)
    if id == math_id then
      if head.subtype == 0 then
        word = ""
        in_math = true
      else
        in_math = false
        if is_number(word) then wasnumber = true end
        word = ""
      end
    end
    if skip ~= 1 and not in_math  then 
      if id == glue_id and allowed_space_types[head.subtype]  then
        if wasnumber then
          if word ~= "" then
            wasnumber = false
            word = cut_off_end_chars(word, false)
            if is_unit(word) then
              anchor = replace_with_thin_space(anchor)
              insert_penalty(anchor.prev)
            end
          end
        elseif is_number(word) then
          wasnumber = true
        else
          word = cut_off_end_chars(word, true)
          if no_predegrees ~= true and predegrees[word] then
            insert_penalty(head.prev)
          elseif no_sufdegrees ~= true and sufdegrees[word] then
            insert_penalty(anchor.prev)
          end
        end
        space=true
        anchor = head
        word = ""
        init = is_initial " " -- reset initials
      elseif space==true and id == glyph_id and is_alpha(getchar(head)) then -- a letter 
        local lang = get_language(head.lang)
        local char = getchar(head)
        word = char
        init = is_initial(char,lang)
        local s = singlechars[lang] or {} -- load singlechars for node's lang
        --[[
        for k, n in pairs(singlechars) do
        for c,_ in pairs(n) do
        --print(type(k), c)
        end
        end
        --]]
        if test_fn(char, s) and nextn ~= nil and nextn.id == glue_id then    -- only if we are at a one letter word
          head = insert_penalty(head)
        end                                                                       
        space = false
        -- handle initials
        -- uppercase letter followed by period (code 46)
      elseif no_initials~=true and init and head.id == glyph_id and head.char == period_char and nextn.id == glue_id  then 
        head = insert_penalty(head)
      elseif head.id == glyph_id then
        local char = getchar(head)
        word = word .. char
        init = is_initial(char, head.lang)
        -- hlist support
      elseif head.id == hlist_id then
        prevent_single_letter(head.head)
        -- vlist support
      elseif head.id == vlist_id then
        prevent_single_letter(head.head)
      end              
    elseif id == glyph_id and in_math then
      word = word .. getchar(head)
    end
    head = head.next                                                            
  end                                                                             
  return  true
end               

local hyphenate_langs = {}
local hyphenchar = string.byte("-")
-- don't break if the next or previous char is hyphen, in order to support ligaturing of dashes
local is_hyphen_ligature = function(n)
  local next_node = n.next
  -- split_hyphens code
  if next_node and next_node.id == glyph_id and next_node.char == hyphenchar then
    return true
  end
  local prev_node = n.prev
  if prev_node and prev_node.id == glyph_id and prev_node.char == hyphenchar then
    return true
  end
  return false
end

-- detect if the current character is a hyphen
local function is_breakable_hyphen(n)
  return n.id == glyph_id and hyphenate_langs[n.lang] and n.char == hyphenchar and n.next 
end

-- don't process hyphens if the next node is penalty
-- necessary to support \nobreakdash
local function is_next_penalty(n)
  local next_node = n.next
  if next_node and next_node.id == penalty_id then
    return true
  end
end

-- split hyphens should be active only inside words, there is no need to break
-- standalone hyphens 
local function is_next_glyph(n)
  local next_node = n.next
  return next_node and next_node.id == glyph_id
end


-- Enable hyphenation of words that contain hyphens
-- and repeating of the explicit hyphen on a new line when
-- the hyphen is hyphenated
-- It should be used in the `hyphenate` callback
-- based on ShreewatsaR's code from:
-- https://tex.stackexchange.com/a/417883/2891
local break_hyphens = function(head, tail)
    local glyph_id = node.id("glyph")
    local n = head
    while n do
       local skip = node.has_attribute(n, M.preventsingleid)
       if skip ~= 1 and is_breakable_hyphen(n) and not is_next_penalty(n) and is_next_glyph(n) and not is_hyphen_ligature(n)  then
          -- Insert an infinite penalty before, and a zero-width glue node after, the hyphen.
          -- Like writing "\nobreak-\hspace{0pt}" or equivalently "\penalty10000-\hskip0pt"
         local p = node.new(node.id('penalty'))
         p.penalty = 10000
         head, p = node.insert_before(head, n, p)
         local g = node.new(node.id('glue'))
         head, g = node.insert_after(head, n, g)
         -- insert the discretionary
         local disc = node.new("disc")
         disc.penalty = tex.hyphenpenalty
         disc.subtype = 2
         disc.pre = node.copy(n)
         disc.post = node.copy(n)
         disc.replace = node.copy(n)
         node.insert_before(head, g, disc)
         -- insert another penalty
         node.insert_before(head, g, node.copy(p))
         node.remove(head,n)
         n = g
       end
       n = n.next
    end
   lang.hyphenate(head, tail)
end

M.preventsingle = prevent_single_letter
M.singlechars = set_singlechars
M.initials    = set_initials
M.set_tex4ht  = set_tex4ht
M.debug = set_debug
M.set_main_language = set_main_language
M.split_hyphen_langs = hyphenate_langs
M.split_hyphens = break_hyphens
return M
