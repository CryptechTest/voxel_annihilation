---@diagnostic disable-next-line: lowercase-global
va_structures = {}

local path = core.get_modpath("va_structures")

dofile(path .. "/core" .. "/functions.lua")
dofile(path .. "/core" .. "/api.lua")
dofile(path .. "/core" .. "/registration.lua")
dofile(path .. "/core" .. "/globalstep.lua")
dofile(path .. "/extra_nodes.lua")

-----------------------------------------------------------------
-----------------------------------------------------------------
