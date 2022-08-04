-----------------------------------------------------------------------
--         FILE:  luaotfload-t3.lua
--  DESCRIPTION:  part of luaotfload / Type 3
-----------------------------------------------------------------------
do -- block to avoid to many local variables error
 assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
     name          = "luaotfload-t3",
     version       = "3.22",       --TAGVERSION
     date          = "2022-06-15", --TAGDATE
     description   = "luaotfload submodule / Type 3 font handling",
     license       = "GPL v2.0",
     author        = "Marcel Krüger",
     copyright     = "Luaotfload Development Team",     
 }
end

--[[
local function u8_to_utf16be(s)
  local d = {}
  local i = 0
  for _, cp, cp2 in utf8.codes(s) do
    i = i + 1
    if cp > 0x10000 then
      cp = cp - 0x10000
      local high = (cp>>10) | 0xD800
      local low = (cp&0x3FF) | 0xDC00
      d[i] = string.format('%04X%04X', high, low)
    else
      d[i] = string.format('%04X', cp)
    end
  end
  return table.concat(d, '', 1, i)
end
]]

local function t3factory(basename, designsize, callback)
  local count = 0
  local gid_to_t3 = {}
  local t3_to_gid = {}
  return function(size)
    local fids = {}
    return function(gid, width, unicode)
      local t3id = gid_to_t3[gid]
      if not t3id then
        t3id = count
        count = count + 1
        gid_to_t3[gid] = t3id
        t3_to_gid[t3id] = gid
      end
      local t3fid, t3cid = t3id >> 8, ~(t3id & 0xFF)
      local fid = fids[t3fid + 1]
      local fontdir = fid and font.getfont(fid)
      local characters = fontdir and fontdir.characters
      if not (characters and characters[t3cid]) then
        characters = characters or {}
        -- First create the character
        local char = {
          width = width,
          height = 0, -- We never look at these two anyway
          depth = 0,
          tounicode = unicode,
        }
        characters[t3cid] = char
        if fid then -- Font already exists
          font.addcharacters(fid, {
            characters = {
              [t3cid] = char,
            },
          })
        else
          fontdir = {
            name = basename .. '_' .. basesize .. '_' .. t3fid,
            format = 'type3',
            psname = 'none',
            filename = 'not_a_real_filename', -- Can't be null to ensure reuse
            fullname = basename .. basesize .. '_' .. t3fid,
            characters = characters,
            designsize = basesize,
            size = size,
            cidinfo = {}, -- Can't be null to ensure reuse
            attributes = '/FontDescriptor<<\z
              /Type/FontDescriptor\z
              /FontName/VirtualLuaFont\z
              /Flags 4\z
              /ItalicAngle 0\z
            >>', -- TODO: Needs work
            t3_handler = function(stage, _, cid)
              cid = cid and assert(t3_to_gid[(t3fid << 8) | ~cid])
              return callback(stage, cid)
            end
          }
          fid = font.define(fontdir)
          fids[t3fid + 1] = fid
        end
      end
      vf.font(fid)
      vf.char(t3cid)
    end
  end
end

luatexbase.add_to_callback('provide_charproc_data', function(stage, fid, ...)
  local fontdir = font.getfont(fid)
  if not fontdir then error'Unknown font' end
  local handler = fontdir.t3_handler
  if not handler then error'Missing t3handler in Type 3 font' end
  return handler(stage, fid, ...)
end, 'luaotfload.t3')

return t3factory
--[===[
          function callback(stage, cid)
            if stage == 1 then
                local char = assert(characters[cid])
                local head = assert(char.head)
                local resource = tex.saveboxresource(head, nil--[[attributes]], nil--[[resources]], true--[[immediate]], 0--[[mode]], nil--[[margin]])
                local name = string.format('/F%i', pdf.getxformname(resource))
                local resources = characters.resources
                if resources then
                  characters.resources = string.format('%s %s %i 0 R', resources, name, resource)
                else
                  characters.resources = string.format('%s %i 0 R', name, resource)
                end
                char.resource = name
              elseif stage == 2 then
                local char = assert(characters[cid])
                width = char.width/65781
                return pdf.obj{
                  type = 'stream',
                  immediate = true,
                  -- objnum =
                  -- attr =
                  -- compresslevel =
                  string = string.format('%g 0 d0 %s Do', width, char.resource)
                }, width
              elseif stage == 3 then
                return 65781/655360, string.format('/XObject<<%s>>', characters.resources)
              end
              print(stage, fid, cid)
            end,
          }
]===]
