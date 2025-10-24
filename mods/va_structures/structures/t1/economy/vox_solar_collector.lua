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
    --core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then
        local pos_above = vector.add(pos, {x=0,y=1,z=0})
        local light_level = minetest.get_node_light(pos_above)
        if light_level > 10 then
            local gen = s_obj:get_data():get_energy_generate()
            local energy = net.energy
            if energy + gen <= net.energy_storage then
                net.energy = energy + gen
            end
        end
    end
end

-- Structure metadata definition setup
local def = {
    max_health = 25,
    energy_generate = 5,
    energy_storage = 10,
    mass_cost = 20,
    energy_cost = 0,
    vas_run = vas_run
}

-- Setup structure definition
local node_name = "solar_collector"
local node_desc = "Solar Collector"
local size = {
    x = 1,
    y = 0,
    z = 1
}
local category = "economy"
local tier = 1
local faction = "vox"

-- Create a new SolarCollector
local solar_collector = Structure.register(node_name, node_desc, size, category, tier, faction, def)

