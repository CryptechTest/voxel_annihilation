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
            if ent._is_va_unit then
                local unit = va_units.get_unit_by_id(obj:get_guid())
                if unit and not unit.object:get_luaentity()._is_constructed then
                    s._build_target = {
                        structure = nil,
                        unit = unit
                    }
                end
            elseif ent._is_va_structure then
                local structure = va_structures.get_active_structure(o_pos)
                if structure and not s:equals(structure) then
                    if structure.is_constructed == false or structure:is_damaged() then
                        s._build_target = {
                            structure = structure,
                            unit = nil
                        }
                        -- core.log("found work for build_turret!")
                        break
                    end
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
            -- reset build target if target is disposed
            if s_obj._build_target.structure and s_obj._build_target.structure._disposed then
                s_obj._build_target = nil
                s_obj._last_dir = nil
                s_obj._target_locked = false
                return
            elseif s_obj._build_target.unit and s_obj._build_target.unit.object then
                local t_obj = s_obj._build_target.unit.object
                if not t_obj or not t_obj:get_luaentity() or t_obj:get_luaentity()._marked_for_removal then
                    s_obj._build_target = nil
                    s_obj._last_dir = nil
                    s_obj._target_locked = false
                    return
                end
            end
        end

        if s_obj._build_target ~= nil then
            local t_structure = s_obj._build_target.structure
            local t_unit = s_obj._build_target.unit

            -- structure building unit is attached to
            local s_building = nil
            local s_attach = t_unit and t_unit.object:get_attach() or nil

            if s_attach then
                -- get the attached structure for the target unit
                t_structure = va_structures.get_active_structure(s_attach:get_pos())
                s_obj._build_target.structure = t_structure
                -- target unit building variable storage
                s_building = (t_structure and t_structure.process_queue[1]) or nil
            end

            if s_obj._target_locked then
                -- target locked, do resource draw
                local e_use = s_obj:get_data():get_energy_consume()
                if net.energy - e_use >= 0 then
                    net.energy = net.energy - e_use
                    local hp_max = t_unit and core.registered_entities[t_unit.object:get_luaentity().name].hp_max or 10
                    local b_power = s_obj:get_data():get_build_power()
                    -- do build or repair
                    if t_unit and t_unit.object:get_hp() < hp_max then
                        s_obj:repair_unit_with_power(net, t_unit, b_power)
                    elseif t_structure and not s_building and not t_structure.is_constructed then
                        t_structure:construct_with_power(net, b_power, s_obj)
                    elseif t_structure and not s_building and t_structure:is_damaged() then
                        t_structure:repair_with_power(net, b_power, s_obj)
                    elseif t_unit and not t_unit.object:get_luaentity()._is_constructed then
                        s_obj:build_unit_with_power(net, t_unit, b_power, t_structure)
                    end
                    -- core.log("turret assisting build...")
                end
                net.energy_demand = net.energy_demand + e_use
            end

            -- structure check for complete
            if t_structure and s_building == nil and (t_structure.is_constructed and not t_structure:is_damaged()) then
                s_obj._build_target = nil
                s_obj._last_dir = nil
                s_obj._target_locked = false
                return
            end

            -- unit check for complete
            if t_unit and s_building and s_building.build_time >= s_building.build_time_max then
                s_obj._build_target = nil
                s_obj._last_dir = nil
                s_obj._target_locked = false
                return
            elseif t_unit and t_unit.object:get_luaentity()._is_constructed then
                s_obj._build_target = nil
                s_obj._last_dir = nil
                s_obj._target_locked = false
                return
            end

            -- get target pos
            local target = nil
            if t_structure and not s_building then
                target = t_structure.pos
            elseif t_unit then
                target = t_unit.object:get_pos()
            else
                return
            end
            -- building effect turret rotation
            local yaw, yaw_deg = va_structures.util.calculateYaw(pos, target)
            local turret = s_obj.entity_obj:get_bone_override('turret')
            local yawRad = turret.rotation and turret.rotation.vec.y or 0
            local yawDeg = yaw_deg -- yawDeg = ((yawDeg + (yaw_deg * 1)) / 2) % 360
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

-- Register a new Build Turret
Structure.register(def)
