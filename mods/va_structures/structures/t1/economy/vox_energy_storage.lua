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
    collisionbox = {-0.75, -0.75, -0.75, 0.75, 1.25, 0.75},
    mesh = "va_energy_storage_1.gltf",
    textures = {"va_vox_energy_storage.png"},
    max_health = 20,
    energy_storage = 600,
    mass_cost = 17,
    energy_cost = 170,
    build_time = 411,
    self_explosion_radius = 2.75,
    death_explosion_radius = 2.25,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "energy_storage"
def.desc = "Energy Storage"
def.size = {
    x = 1,
    y = 1,
    z = 1
}
def.category = "economy"
def.tier = 1
def.faction = "vox"

-- Create a new EnergyStorage
local energy_storage = Structure.register(def)

