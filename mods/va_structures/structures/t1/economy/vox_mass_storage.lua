-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Mass Storage
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
    collisionbox = {-0.75, -0.75, -0.75, 0.75, 1.25, 0.75},
    mesh = "va_energy_storage_1.gltf",
    textures = {"va_vox_energy_storage.png"},
    max_health = 20,
    mass_storage = 300,
    mass_cost = 33,
    energy_cost = 57,
    build_time = 292,
    self_explosion_radius = 2.0,
    death_explosion_radius = 1.5,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "mass_storage"
def.desc = "Mass Storage"
def.size = {
    x = 1,
    y = 1,
    z = 1
}
def.category = "economy"
def.tier = 1
def.faction = "vox"

-- Register a new EnergyStorage
Structure.register(def)

