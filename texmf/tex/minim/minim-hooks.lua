
local cb = require ('minim-callbacks')

local M = { }

-- Add a callback just before a box is shipped out, opposite to 
-- 'finish_pdfpage'.

cb.new_callback('pre_shipout', 'simple')

M.primitive_shipout = tex.shipout
function tex.shipout(nr)
    cb.call_callback('pre_shipout', nr)
    M.primitive_shipout(nr)
end

return M

