-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Solar Collector
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
        local pos_above = vector.add(pos, {
            x = 0,
            y = 1,
            z = 0
        })
        local light_level = minetest.get_node_light(pos_above)
        if light_level > 10 then
            local gen = s_obj:get_data():get_energy_generate()
            local energy = net.energy
            if energy + gen <= net.energy_storage + 1 then
                net.energy = energy + gen
            else
                net.energy = net.energy_storage
            end
            net.energy_supply = net.energy_supply + gen
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_solar_collector_1.gltf",
    textures = {"va_vox_solar_collector_2.png"},
    collisionbox = {-0.75, -0.75, -0.75, 0.75, 1, 0.75},
    max_health = 25,
    energy_generate = 2,
    energy_storage = 5,
    mass_cost = 15.5,
    energy_cost = 0,
    build_time = 260,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "solar_collector"
def.desc = "Solar Collector"
def.size = {
    x = 1,
    y = 0,
    z = 1
}
def.category = "economy"
def.tier = 1
def.faction = "vox"

-- Register a new Solar Collector
Structure.register(def)

