-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Energy Converter
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
        local gen = s_obj:get_data():get_mass_extract()
        local cost = s_obj:get_data():get_energy_consume()
        local energy = net.energy
        local mass = net.mass
        if energy - cost > 0 then
            net.energy = energy - cost
            net.mass = mass + gen
            net.energy_demand = net.energy_demand + cost
            net.mass_supply = net.mass_supply + gen
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_energy_converter_1.gltf",
    textures = {"va_vox_energy_converter_1.png"},
    collisionbox = {-0.75, -0.75, -0.75, 0.75, 0.75, 0.75},
    max_health = 20,
    mass_extract = 0.1,
    mass_storage = 5,
    mass_cost = 0.1,
    energy_consume = 7,
    energy_cost = 115,
    vas_run = vas_run
}

-- Setup structure definition
local node_name = "energy_converter"
local node_desc = "Energy Converter"
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

