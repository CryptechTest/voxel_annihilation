-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Bot Lab
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
        if #self.process_queue > 0 then
            local owner = s_obj.owner
            local process = table.remove(self.process_queue, 1)
            local unit_name = process.unit_name
            va_units.spawn_unit(unit_name, owner, pos)
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_bot_lab_1.gltf",
    textures = {"va_vox_bot_lab_1.png"},
    collisionbox = {-0.75, -0.75, -0.75, 0.75, 0.75, 0.75},
    max_health = 30,
    mass_cost = 25.0,
    energy_cost = 100,
    build_time = 500,
    build_output_list = {
        ['va_units:vox_constructor'] = true,
        ['va_units:vox_scout'] = true,
        ['va_units:vox_fast_infrantry'] = true,
        ['va_units:vox_light_plasma'] = true
    },
    vas_run = vas_run
}

-- Setup structure definition
def.name = "bot_lab"
def.desc = "Bot Lab"
def.size = {
    x = 2,
    y = 1,
    z = 2
}
def.category = "build"
def.tier = 1
def.faction = "vox"

-- Register a new Solar Collector
Structure.register(def)

