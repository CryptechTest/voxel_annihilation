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
        if energy - cost >= 0 then
            net.energy = energy - cost
            if net.mass + gen <= net.mass_storage then
                net.mass = mass + gen
            else
                net.mass = net.mass_storage
            end
            net.mass_supply = net.mass_supply + gen
        end
        net.energy_demand = net.energy_demand + cost
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
    build_time = 260,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "energy_converter"
def.desc = "Energy Converter"
def.size = {
    x = 1,
    y = 0,
    z = 1
}
def.category = "economy"
def.tier = 1
def.faction = "vox"

-- Create a new SolarCollector
local solar_collector = Structure.register(def)

