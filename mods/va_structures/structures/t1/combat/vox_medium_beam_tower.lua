-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Light Laser Tower
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local function get_formspec(structure)
    if not structure then
        return
    end

    local pos = structure.pos
    local meta = core.get_meta(pos)
    local desc = structure.desc

    local formspec = "size[8,8]" .. "no_prepend[]" .. "formspec_version[10]" -- .. "allow_close[false]"

    formspec = formspec .. "style_type[label;font_size=22;font=bold]"
    formspec = formspec .. "label[0.0,-0.1;" .. desc .. " - Control]" .. "bgcolor[#101010;]"
    formspec = formspec .. "style_type[label;font_size=16;font=bold]"

    -- fire at will
    -- return fire
    -- hold fire
    local attack_mode = meta:get_int("attack_mode")

    local attck_y = 1.0
    formspec = formspec .. "label[4.5," .. (attck_y + 0.1) .. ";Attack Mode]"
    formspec =
        formspec .. "dropdown[4.5,2.5;" .. (attck_y + 0.5) .. ";attack_mode;Fire at Will,Return Fire,Hold Fire;" ..
            (attack_mode > 0 and attack_mode or 1) .. ";true]"

    formspec = formspec .. "style[attack_cancel;bgcolor=" .. "#ffee00ff" .. "]"
    formspec = formspec .. "button[2.0,7.3;2.0,1;attack_cancel;Clear Target]"

    formspec = formspec .. "style[quit;bgcolor=" .. "#ff0000ff" .. "]"
    formspec = formspec .. "button_exit[6.5,7.3;1.5,1;quit;Exit]"

    return formspec
end

local function on_receive_fields(structure, player, formname, fields)
    if not structure then
        return
    end
    local pos = structure.pos
    local meta = core.get_meta(pos)
    -- local owner = meta:get_string("owner") or ""

    -- core.log(dump(fields))

    if fields.attack_mode then
        if meta:get_int("attack_mode") ~= tonumber(fields.attack_mode) then
            meta:set_int("attack_mode", tonumber(fields.attack_mode))
        end
    end

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
    local pitch, pitch_deg = va_structures.util.calculatePitch(pos, target)
    local turret = structure.entity_obj:get_bone_override('turret')
    local yawRad = turret.rotation and turret.rotation.vec.y or 0
    local yawDeg = yaw_deg -- yawDeg = ((yawDeg + (yaw_deg * 1)) / 2) % 360
    if structure._last_dir ~= nil and num_is_close(yawDeg, math.deg(yawRad), 3) then
        -- if rotation complete mark as locked
        structure._target_locked = true
    end
    if structure._last_dir == nil or yaw_deg ~= structure._last_dir then
        if not num_is_close(yawDeg, math.deg(yawRad), 28) then
            structure._target_locked = false
        end
        structure._last_dir = yawDeg
        local rot_turret = {
            x = math.rad(pitch_deg),
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

local function find_target(structure, dist)
    local pos = vector.add(structure.pos, vector.new(0, 1.35, 0))
    local objs = core.get_objects_inside_radius(pos, dist + 0.55)
    local targets = {}
    for _, obj in pairs(objs) do
        local o_pos = obj:get_pos()
        if vector.distance(pos, o_pos) < dist + 1 then
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent._is_va_unit then
                    if ent._owner_name ~= structure.owner then
                        if can_see(pos, obj) then
                            table.insert(targets, obj)
                        end
                    end
                elseif ent._is_va_structure then
                    if ent._owner_name ~= structure.owner then
                        if can_see(pos, obj) then
                            table.insert(targets, obj)
                        end
                    end
                end
            end
        end
    end
    if #targets > 0 then
        return targets[1]:get_pos()
    end
    return nil
end

local function rotate_y(vector, angle_yaw, angle_pitch)
    local cos_a = math.cos(angle_yaw)
    local sin_a = math.sin(angle_yaw)
    local sin_p = math.cos(angle_pitch)
    local cos_p = math.cos(angle_pitch)
    local x = vector.x * cos_a - vector.z * sin_a
    local z = vector.x * sin_a + vector.z * cos_a
    local y = vector.y * cos_p
    local x1 = x * cos_p - z * sin_p
    local z1 = x * sin_p + z * cos_p
    return {
        x = (x),
        y = (y),
        z = -(z)
    }
end

local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then
        local recent_hit = false
        if core.get_us_time() - s_obj.last_hit < 13 * 1000 * 1000 then
            recent_hit = true
        end

        local meta = core.get_meta(pos)
        if meta:get_int("attack_mode") == 3 then
            return
        end

        local shooter = s_obj.entity_obj
        local damage = 4
        local range = 16
        local target = find_target(s_obj, range)

        if target then
            local yaw, yaw_deg = va_structures.util.calculateYaw(pos, target)
            local pitch, pitch_deg = va_structures.util.calculatePitch(target, pos)

            local turret_end = {
                x = (0 * 1 / 16) * 0.88,
                y = (36 * 1 / 16) * 0.50,
                z = (24 * 1 / 16) * 0.88
            }

            local turret_end_pos = rotate_y(turret_end, yaw, pitch)
            local o_pos = vector.add(s_obj.pos, turret_end_pos)
            local t_pos = vector.add(target, vector.new(0, 0.3, 0))

            local cost = s_obj:get_data():get_energy_consume()
            local energy = net.energy
            if energy - cost >= 0 then
                do_turret_rotation(s_obj, target)
                if s_obj._target_locked then
                    net.energy = energy - cost
                    local weapon = va_weapons.get_weapon("beam")
                    weapon.fire(shooter, o_pos, t_pos, range, damage)
                end
            end
            net.energy_demand = net.energy_demand + cost
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_vox_light_laser_tower.gltf",
    textures = {"va_vox_light_laser_tower.png"},
    collisionbox = {-0.45, -0.5, -0.45, 0.45, 1.8, 0.45},
    max_health = 143,
    mass_cost = 19,
    energy_cost = 150,
    energy_consume = 2,
    build_time = 480,
    formspec = get_formspec,
    on_receive_fields = on_receive_fields,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "medium_beam_tower"
def.desc = "Medium Beam Tower"
def.size = {
    x = 1,
    y = 1.95,
    z = 1
}
def.category = "combat"
def.tier = 1
def.faction = "vox"

def.do_rotate = false

-- Register a new Light Laser Tower
Structure.register(def)

