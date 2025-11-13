---@diagnostic disable-next-line: lowercase-global
va_structures = {}

local path = core.get_modpath("va_structures")

dofile(path .. "/core" .. "/functions.lua")
dofile(path .. "/core" .. "/api.lua")
dofile(path .. "/core" .. "/registration.lua")
dofile(path .. "/core" .. "/globalstep.lua")
dofile(path .. "/core" .. "/extra_nodes.lua")

-----------------------------------------------------------------
-----------------------------------------------------------------

-- TODO: this is temp!
core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    va_structures.add_player_actor(name, "vox", 1)
end)
