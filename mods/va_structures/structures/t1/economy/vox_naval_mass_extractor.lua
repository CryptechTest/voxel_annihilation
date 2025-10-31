-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Mass Extractor
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local vas_run = function(pos, node, s_obj, run_stage, net)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then

        local pos_below = vector.subtract(pos, {
            x = 0,
            y = 1,
            z = 0
        })
        local base_rate = 1
        local has_power = false
        local node = core.get_node(pos_below)
        local meta = core.get_meta(pos_below)
        local mass_group = core.get_item_group(node.name, 'va_mass')
        local value = meta:get_int("va_mass_amount") * 0.01
        if mass_group > 0 then
            local amount = 1
            if mass_group == 2 then
                amount = 0.8
                base_rate = 0.7
            elseif mass_group == 1 then
                amount = 0.6
                base_rate = 0.4
            end
            local cost = s_obj:get_data():get_energy_consume()
            local gen = s_obj:get_data():get_mass_extract()
            local extract = value * gen * amount
            local mass = net.mass
            local energy = net.energy
            if energy - cost >= 0 then
                net.energy = energy - cost
                if mass + extract <= net.mass_storage then
                    net.mass = mass + extract
                else
                    net.mass = net.mass_storage
                end
                net.mass_supply = net.mass_supply + extract
                has_power = true
            end
            net.energy_demand = net.energy_demand + cost
        end

        if has_power then
            local speed = 90 * base_rate  * (value)
            local overrides = s_obj.entity_obj:get_bone_override('top')
            local yawRad = overrides.rotation and overrides.rotation.vec.y or 0
            local yawDeg = math.deg(yawRad)
            yawDeg = (yawDeg + speed) % 360
            local rotation = {
                x = 0,
                y = math.rad(yawDeg),
                z = 0
            }
            s_obj.entity_obj:set_bone_override("top", {
                rotation = {
                    vec = rotation,
                    absolute = true,
                    interpolation = 1.0
                }
            })

            local pos_above = vector.add(pos, {
                x = 0,
                y = 1,
                z = 0
            })
            if core.get_node(pos_above).name == "default:water_source" then
                va_structures.water_effect_particle(s_obj.entity_obj, 7)
            end
            
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_mass_extractor_1.gltf",
    textures = {"va_vox_mass_extractor_1.png"},
    collisionbox = {-0.75, -0.75, -0.75, 0.75, 0.70, 0.75},
    max_health = 16,
    mass_storage = 5,
    mass_extract = 1, -- this used as a percent here
    mass_cost = 5,
    energy_cost = 50,
    energy_consume = 0.3,
    build_time = 180,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "naval_mass_extractor"
def.desc = "Naval Mass Extractor"
def.size = {
    x = 1,
    y = 0,
    z = 1
}
def.category = "economy"
def.tier = 1
def.faction = "vox"
def.under_water_type = true

-- Register a new Mass Extractor
Structure.register(def)
