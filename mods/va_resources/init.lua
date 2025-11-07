---@diagnostic disable-next-line: lowercase-global
va_resources = {}

local modname = core.get_current_modname()
local mod_path = core.get_modpath(modname)

-- mass
dofile(mod_path .. "/src/mass.lua")
dofile(mod_path .. "/src/mass_mapgen.lua")
dofile(mod_path .. "/src/mass_entity.lua")
-- wind
dofile(mod_path .. "/src/windstep.lua")
-- geothermal
dofile(mod_path .. "/src/geothermal.lua")
dofile(mod_path .. "/src/geo_mapgen.lua")
dofile(mod_path .. "/src/geo_entity.lua")

-- rocks and foilage...
dofile(mod_path .. "/src/rocks.lua")
dofile(mod_path .. "/src/plants.lua")

dofile(mod_path .. "/api.lua")