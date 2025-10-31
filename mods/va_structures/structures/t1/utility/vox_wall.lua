-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Wall
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then

    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_vox_wall_1.gltf",
    textures = {"va_vox_wall_1.png"},
    collisionbox = {-0.5, -0.75, -0.5, 0.5, 0.5, 0.5},
    max_health = 280,
    mass_cost = 0.8,
    build_time = 30,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "wall"
def.desc = "Wall"
def.size = {
    x = 1,
    y = 0,
    z = 1
}
def.category = "utility"
def.tier = 1
def.faction = "vox"

-- Register a new Wall
Structure.register(def)

