-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Energy Storage
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local vas_run = function(pos, node, s_obj, run_stage, net)
    --core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then

    end
end

-- Structure metadata definition setup
local def = {
    max_health = 20,
    energy_storage = 1000,
    mass_cost = 2,
    energy_cost = 300,
    vas_run = vas_run
}

-- Setup structure definition
local node_name = "energy_storage"
local node_desc = "Energy Storage"
local size = {
    x = 1,
    y = 0,
    z = 1
}
local category = "economy"
local tier = 1
local faction = "vox"

-- Create a new EnergyStorage
local energy_storage = Structure.register(node_name, node_desc, size, category, tier, faction, def)

