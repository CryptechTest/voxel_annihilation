-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Build Turret
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local find_build_target = function(pos, s)
    local dist = s:get_data().construction_distance
    local objs = minetest.get_objects_inside_radius(pos, dist + 0.55)
    for _, obj in pairs(objs) do
        local o_pos = obj:get_pos()
        if obj:get_luaentity() then
            local ent = obj:get_luaentity()
            local structure = va_structures.get_active_structure(o_pos)
            if structure and not s:equals(structure) then
                if structure.is_constructed == false then
                    s._build_target = structure
                    --core.log("found work for build_turret!")
                    break
                end
            end
        end
    end
end

local function num_is_close(target, actual, thrs)
    local target_frac = (target * 0.001) + thrs
    return actual < target + target_frac and actual >= target - target_frac
end

local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then

        if s_obj._build_target == nil then
            -- find build target
            find_build_target(pos, s_obj)
        end

        if s_obj._build_target ~= nil then
            if s_obj._target_locked then
                local e_use = s_obj:get_data():get_energy_consume()
                if net.energy - e_use >= 0 then
                    net.energy = net.energy - e_use
                    -- do build...
                    local b_power = s_obj:get_data():get_build_power()
                    s_obj._build_target:construct_with_power(net, b_power, s_obj)
                    --core.log("turret assisting build...")
                end
                net.energy_demand = net.energy_demand + e_use
            end
            if s_obj._build_target.is_constructed then
                s_obj._build_target = nil
                s_obj._last_dir = nil
                return
            end

            local target = s_obj._build_target.pos
            local yaw, yaw_deg = va_structures.util.calculateYaw(pos, target)
            local turret = s_obj.entity_obj:get_bone_override('turret')
            local yawRad = turret.rotation and turret.rotation.vec.y or 0
            local yawDeg = yaw_deg
            --yawDeg = ((yawDeg + (yaw_deg * 1)) / 2) % 360
            if s_obj._last_dir ~= nil and num_is_close(yaw_deg, math.deg(yawRad), 20) then
                s_obj._target_locked = true
            end
            if s_obj._last_dir == nil or yaw_deg ~= s_obj._last_dir then
                s_obj._target_locked = false
                s_obj._last_dir = yawDeg
                local rot_turret = {
                    x = 0,
                    y = math.rad(yawDeg),
                    z = 0
                }
                s_obj.entity_obj:set_bone_override("turret", {
                    rotation = {
                        vec = rot_turret,
                        absolute = true,
                        interpolation = 1.0
                    }
                })
            end
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_build_turret_1.gltf",
    textures = {"va_vox_build_turret_1.png"},
    collisionbox = {-0.75, -0.75, -0.75, 0.75, 0.75, 0.75},
    max_health = 17,
    energy_generate = 0,
    energy_storage = 0,
    mass_cost = 20,
    energy_cost = 200,
    energy_consume = 0.1,
    build_time = 300,
    build_power = 8,
    construction_distance = 16,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "build_turret"
def.desc = "Build Turret"
def.size = {
    x = 1,
    y = 0,
    z = 1
}
def.category = "build"
def.tier = 1
def.faction = "vox"

def.do_rotate = false

-- Create a new Build Turret
local build_turret = Structure.register(def)
