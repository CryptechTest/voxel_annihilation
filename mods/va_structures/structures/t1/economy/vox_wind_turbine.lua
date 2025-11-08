-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Wind Turbine
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
        local wind = va_resources.get_env_wind_vel()
        local wind_vel = wind.velocity
        local wind_dir = wind.direction

        if wind_vel > 0 then
            local energy = net.energy
            local gen = s_obj:get_data():get_energy_generate()
            local gen_win = gen * wind_vel
            if energy + gen_win <= net.energy_storage + 1 then
                net.energy = energy + gen_win
            else
                net.energy = net.energy_storage
            end
            net.energy_supply = net.energy_supply + gen_win
        end

        if wind_vel > 0 then
            local arm = s_obj.entity_obj:get_bone_override('fan')
            local yawRad = arm.rotation and arm.rotation.vec.y or 0
            local yawDeg = math.deg(yawRad)
            yawDeg = ((yawDeg + wind_dir) / 2) % 360
            local rot_arm = {
                x = 0,
                y = math.rad(yawDeg),
                z = 0
            }
            local speed = math.min(200, 100 * (wind_vel * 1))
            local rotor = s_obj.entity_obj:get_bone_override('rotor')
            local rollRad = rotor.rotation and rotor.rotation.vec.z or 0
            local rollDeg = math.deg(rollRad)
            rollDeg = (rollDeg + speed) % 360
            local rot_rotor = {
                x = 0,
                y = 0,
                z = math.rad(rollDeg)
            }
            s_obj.entity_obj:set_bone_override("fan", {
                rotation = {
                    vec = rot_arm,
                    absolute = true,
                    interpolation = 1.0
                }
            })
            s_obj.entity_obj:set_bone_override("rotor", {
                rotation = {
                    vec = rot_rotor,
                    absolute = true,
                    interpolation = 1.0
                }
            })
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_wind_turbine_1.gltf",
    textures = {"va_vox_wind_turbine_1.png"},
    collisionbox = {-0.75, -0.5, -0.75, 0.75, 1.45, 0.75},
    max_health = 12,
    energy_generate = 1, -- this used as a percent here
    energy_storage = 0.05,
    mass_cost = 4,
    energy_cost = 17.5,
    build_time = 160,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "wind_turbine"
def.desc = "Wind Turbine"
def.size = {
    x = 1,
    y = 2,
    z = 1
}
def.category = "economy"
def.tier = 1
def.faction = "vox"

def.generator_type = true

def.do_rotate = false

-- Register a new Wind Turbine
Structure.register(def)

