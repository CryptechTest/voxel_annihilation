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

local color_index = 1
local colors = {"#ff0000", "#0000ff", "#00ff00", "#ffff00", "#ff00ff", "#00ffff", "#800080", "#008080", "#c0c0c0", "#a52a2a", "#deb887", "#5f9ea0", "#7fff00", "#dda0dd", "#add8e6", "#9932CC"}

-- TODO: this is temp!
core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    va_structures.add_player_actor(name, "vox", 1, colors[color_index])
    color_index = color_index + 1
    if color_index > 16 then
        color_index = 1
    end
end)
