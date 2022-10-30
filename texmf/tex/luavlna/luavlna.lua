-- Module luavlna
-- code originally created by Patrick Gundlach
-- http://tex.stackexchange.com/q/27780/2891
-- The code was adapted for plain TeX and added some more features
-- 1. It is possible to turn this functionality only for some letters
-- 2. Code now works even for single letters after brackets etc.
--
local M = {}
local utf_match = unicode.utf8.match
local utf_char  = unicode.utf8.char
local utf_len   = unicode.utf8.len

local glue_id  = node.id "glue"
local glyph_id = node.id "glyph"
local hlist_id = node.id "hlist"
local vlist_id = node.id "vlist"
local penalty_id = node.id "penalty"
local math_id  = node.id "math"
local period_char = string.byte(".")

local alpha = string.char(37).."a" -- alpha class, entering 
-- percent char directly caused error
local alphas = {}
local match_char = function(x) return utf_match(x,alpha) end
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
    status = utf_match(c, alpha)
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
      if id == glue_id then
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
