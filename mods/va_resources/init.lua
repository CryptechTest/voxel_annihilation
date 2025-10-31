va_resources = {}

local path = core.get_modpath("va_resources")

dofile(path .. "/api.lua")

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
