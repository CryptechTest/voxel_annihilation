-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Popup Turret
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local function turret_open(structure)
    if structure._turret_open then
        return
    end

    structure._turret_open = true

    local turret = structure.entity_obj:get_bone_override('turret')
    local yawRad = turret.rotation and turret.rotation.vec.y or 0
    local pitchRad = turret.rotation and turret.rotation.vec.x or 0

    local pitch = 0
    local yaw = 0

    local rot_turret = {
        x = math.rad(pitch),
        y = math.rad(yaw),
        z = 0
    }
    local loc_turret = {
        x = 0,
        y = 0 * 0.625,
        z = 0
    }

    -- set rotation to target
    structure.entity_obj:set_bone_override("turret", {
        rotation = {
            vec = rot_turret,
            absolute = true,
            interpolation = 0.5
        },
        position = {
            vec = loc_turret,
            absolute = true,
            interpolation = 0.5
        }
    })
end

local function turret_open_gun(structure)
    if structure._turret_open_gun then
        return
    end

    structure._turret_open_gun = true

    local turret = structure.entity_obj:get_bone_override('gun')
    local yawRad = turret.rotation and turret.rotation.vec.y or 0
    local pitchRad = turret.rotation and turret.rotation.vec.x or 0

    local pitch = 0
    local yaw = 0

    local rot_turret = {
        x = math.rad(pitch),
        y = math.rad(yaw),
        z = 0
    }
    -- set rotation to target
    structure.entity_obj:set_bone_override("gun", {
        rotation = {
            vec = rot_turret,
            absolute = true,
            interpolation = 0.6
        }
    })
end

local function turret_close(structure)
    if not structure._turret_open then
        return
    end

    structure._turret_open = false

    local turret = structure.entity_obj:get_bone_override('turret')
    local yawRad = turret.rotation and turret.rotation.vec.y or 0
    local pitchRad = turret.rotation and turret.rotation.vec.x or 0

    local pitch = 0
    local yaw = 0

    local rot_turret = {
        x = math.rad(pitch),
        y = math.rad(yaw),
        z = 0
    }
    local loc_turret = {
        x = 0,
        y = -(22 - 0) * 0.625,
        z = 0
    }

    -- set rotation to target
    structure.entity_obj:set_bone_override("turret", {
        rotation = {
            vec = rot_turret,
            absolute = true,
            interpolation = 0.8
        },
        position = {
            vec = loc_turret,
            absolute = true,
            interpolation = 0.8
        }
    })
end

local function turret_close_gun(structure)
    if not structure._turret_open_gun then
        return
    end

    structure._turret_open_gun = false

    local turret = structure.entity_obj:get_bone_override('gun')
    local yawRad = turret.rotation and turret.rotation.vec.y or 0
    local pitchRad = turret.rotation and turret.rotation.vec.x or 0

    local pitch = -90
    local yaw = 0

    local rot_turret = {
        x = 0,
        y = 0,
        z = 0
    }
    local rot_gun = {
        x = math.rad(pitch),
        y = math.rad(yaw),
        z = 0
    }

    structure.entity_obj:set_bone_override("turret", {
        rotation = {
            vec = rot_turret,
            absolute = true,
            interpolation = 0.8
        }
    })
    structure.entity_obj:set_bone_override("gun", {
        rotation = {
            vec = rot_gun,
            absolute = true,
            interpolation = 0.8
        }
    })
end

local function rotate_y(vector, angle_yaw)
    local cos_a = math.cos(angle_yaw)
    local sin_a = math.sin(angle_yaw)
    local x = vector.x * cos_a - vector.z * sin_a
    local z = vector.x * sin_a + vector.z * cos_a
    local y = vector.y
    return {
        x = (x),
        y = (y),
        z = -(z)
    }
end

local function num_is_close(target, actual, thrs)
    local target_frac = (target * 0.001) + thrs
    return actual < target + target_frac and actual >= target - target_frac
end

--- Rotate the build turret to face toward the target
---@param structure any
---@param target any
local function do_turret_rotation(structure, target)
    if target == nil or structure == nil then
        return
    end
    local pos = structure.pos
    -- building effect turret rotation
    local yaw, yaw_deg = va_structures.util.calculateYaw(pos, target)
    local turret = structure.entity_obj:get_bone_override('turret')
    local barrel = structure.entity_obj:get_bone_override('gun')
    local yawRad = turret.rotation and turret.rotation.vec.y or 0
    local yawDeg = yaw_deg -- yawDeg = ((yawDeg + (yaw_deg * 1)) / 2) % 360
    if structure._last_dir ~= nil and num_is_close(yawDeg, math.deg(yawRad), 3) then
        -- if rotation complete mark as locked
        structure._target_locked = true
    end
    if structure._last_dir == nil or yaw_deg ~= structure._last_dir.yaw then
        if not num_is_close(yawDeg, math.deg(yawRad), 8) then
            structure._target_locked = false
        end
        structure._last_dir = {}
        structure._last_dir.yaw = yaw_deg
        local rot_turret = {
            x = 0,
            y = math.rad(yawDeg),
            z = 0
        }
        -- set rotation to target
        structure.entity_obj:set_bone_override("turret", {
            rotation = {
                vec = rot_turret,
                absolute = true,
                interpolation = 0.7
            }
        })
    end
end

local function can_see(origin, obj)
    local target_pos = vector.add(obj:get_pos(), vector.new(0, 0.51, 0))
    local ray = core.raycast(origin, target_pos, false, true, nil)
    for pointed_thing in ray do
        if pointed_thing.type == "object" and pointed_thing.ref ~= obj then
            if pointed_thing.ref:get_pos() ~= origin then
                return false
            end
        elseif pointed_thing.type == "node" and pointed_thing.under ~= target_pos then
            if pointed_thing.under ~= origin then
                return false
            end
        end
    end
    return true
end

local function find_target(structure, dist, net)
    local cost = structure:get_data():get_energy_consume()
    local energy = net.energy
    if energy - cost < 0 then
        return nil
    end
    local pos = vector.add(structure.pos, vector.new(0, 1.35, 0))
    local objs = core.get_objects_inside_radius(pos, dist + 0.55)
    local targets = {}
    for _, obj in pairs(objs) do
        local o_pos = obj:get_pos()
        if vector.distance(pos, o_pos) < dist + 1 then
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent._is_va_unit then
                    if ent._team_uuid ~= structure.team_uuid then
                        if can_see(pos, obj) then
                            table.insert(targets, obj)
                        end
                    end
                elseif ent._is_va_structure then
                    if ent._team_uuid ~= structure.team_uuid then
                        if can_see(pos, obj) then
                            table.insert(targets, obj)
                        end
                    end
                end
            end
        end
    end
    if #targets > 0 then
        return targets[1]
    end
    return nil
end

local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    local damage = 7
    local range = 17
    if run_stage == "weapon" then
        -- weapons run
        local meta = core.get_meta(pos)
        if meta:get_int("attack_mode") == 3 then
            return
        end
        local target = s_obj._last_target or find_target(s_obj, range + 1, net)
        if target and not s_obj._target_locked then
            s_obj._last_target = target
            if s_obj._out_index > 3 then
                do_turret_rotation(s_obj, target:get_pos())
            elseif s_obj._out_index <= -3 then
                s_obj._out_index = 1
            end
        end
    elseif run_stage == "main" then
        -- main run
        local meta = core.get_meta(pos)
        if meta:get_int("attack_mode") == 3 then
            return
        end

        local target = s_obj._last_target or find_target(s_obj, range, net)

        if s_obj._out_index == 0 then
            s_obj._turret_open = true
            s_obj._turret_open_gun = true
            s_obj._out_index = -1
        end

        if s_obj._out_index == -1 then
            turret_close_gun(s_obj)
            s_obj._out_index = -2
            core.after(0.85, function()
                turret_close(s_obj)
                s_obj._out_index = -3
            end)
            return
        elseif s_obj._out_index == -2 then
            turret_close(s_obj)
            s_obj._out_index = -3
            return
        end

        if s_obj._out_index == 1 then
            turret_open(s_obj)
            s_obj._out_index = 2
            core.after(0.5, function()
                turret_open_gun(s_obj)
                s_obj._out_index = 3
            end)
            target = find_target(s_obj, range, net)
            return
        elseif s_obj._out_index == 2 then
            turret_open_gun(s_obj)
            s_obj._out_index = 3
            return
        end

        if target and s_obj._out_index == -3 then
            s_obj._out_index = 1
            return
        end
        if not target and s_obj._out_index <= -3 then
            return
        end
        if s_obj._last_target and s_obj._out_index == 3 then
            s_obj._out_index = 4
        end
        if not s_obj._last_target and s_obj._out_index > 3 then
            s_obj._out_index = s_obj._out_index + 1
            if s_obj._out_index >= 10 then
                s_obj._out_index = -1
                return
            end
        end

        if s_obj._fire_index > 0 then
            s_obj._fire_index = s_obj._fire_index - 1
        end

        if target and target.get_pos and s_obj._out_index > 3 and s_obj._fire_index == 0 then
            s_obj._last_target = target
            s_obj._out_index = 5
            s_obj._fire_index = 2
            local yaw, yaw_deg = va_structures.util.calculateYaw(pos, target:get_pos())
            local turret_end = {
                x = (0 * 1 / 16) * 0.66,
                y = (17 * 1 / 16) * 0.66,
                z = (15 * 1 / 16) * 0.66
            }

            local turret_end_pos = rotate_y(turret_end, yaw)
            local o_pos = vector.add(s_obj.pos, turret_end_pos)
            local t_pos = vector.add(target:get_pos(), vector.new(0, 0.25, 0))
            local shooter = s_obj.entity_obj

            local cost = s_obj:get_data():get_energy_consume()
            local energy = net.energy
            if energy - cost >= 0 then
                do_turret_rotation(s_obj, target:get_pos())
                if s_obj._target_locked then
                    net.energy = energy - cost
                    local weapon = va_weapons.get_weapon("lightning")
                    local x = va_structures.util.randFloat(-0.1, 0.1)
                    local y = va_structures.util.randFloat(-0.1, 0.1)
                    local z = va_structures.util.randFloat(-0.1, 0.1)
                    local tr_pos = vector.add(t_pos, vector.new(x, y, z))
                    weapon.fire(shooter, o_pos, tr_pos, range, damage)
                    s_obj._last_target = nil
                    s_obj._target_locked = false
                end
            end
            net.energy_demand = net.energy_demand + cost
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_vox_pop_up_turret.gltf",
    textures = {"va_vox_pop_up_turret.png"},
    collisionbox = {-0.525, -0.5, -0.525, 0.525, 0.95, 0.525},
    max_health = 133,
    mass_cost = 34,
    energy_cost = 160,
    build_time = 465,
    energy_consume = 2,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "pop_up_turret"
def.desc = "Pop-up Turret"
def.size = {
    x = 0.0,
    y = 1.65,
    z = 0.0
}
def.category = "utility"
def.tier = 1
def.faction = "vox"

def.do_rotate = false

-- Register a new Popup Turret
Structure.register(def)

