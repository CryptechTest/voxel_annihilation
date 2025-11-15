-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Heavy Laser Tower
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
    local pitchRad = turret.rotation and turret.rotation.vec.x or 0
    local yawDeg = yaw_deg -- yawDeg = ((yawDeg + (yaw_deg * 1)) / 2) % 360
    if structure._last_dir ~= nil and num_is_close(yawDeg, math.deg(yawRad), 3) and num_is_close(pitch_deg, math.deg(pitchRad), 2) then
        -- if rotation complete mark as locked
        structure._target_locked = true
    end
    if structure._last_dir == nil or yaw_deg ~= structure._last_dir.yaw or pitch_deg ~= structure._last_dir.pitch then
        if not num_is_close(yawDeg, math.deg(yawRad), 28) or not num_is_close(pitch_deg, math.deg(pitchRad), 20) then
            structure._target_locked = false
        end
        structure._last_dir = {}
        structure._last_dir.yaw = yaw_deg
        structure._last_dir.pitch = pitch_deg
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
                interpolation = 0.6
            }
        })
    end
end

local function muzzle_effect_particle(origin, dir)
    --Fire flash
    --[[core.add_particle({
        pos = origin,
        expirationtime = 0.1,
        size = 2,
        collisiondetection = false,
        vertical = false,
        texture = "va_structures_explosion_2.png^[colorize:#00ff00:alpha",
        glow = 13,
    })]]
    local r = 0.1
    local s_vel = vector.multiply(dir, 2.0)
    local s_vel_min = vector.subtract(s_vel, {x=math.random(-r,r), y=math.random(-r,r), z=math.random(-r,r)})
    local s_vel_max = vector.add(s_vel, {x=math.random(-r,r), y=math.random(-r,r), z=math.random(-r,r)})
    local s_pos = {x=origin.x+dir.x*0.01, y=origin.y+dir.y*0.01, z=origin.z+dir.z*0.01}
    core.add_particlespawner({
        amount = 15,
        time = 0.075,
        minpos = {x=s_pos.x-0.01, y=s_pos.y-0.01, z=s_pos.z-0.01},
        maxpos = {x=s_pos.x+0.01, y=s_pos.y+0.01, z=s_pos.z+0.01},
        minvel = s_vel_min,
        maxvel = s_vel_max,
        minacc = {x=-0.25, y=-0.28, z=-0.25},
        maxacc = {x=0.25, y=0.28, z=0.25},
        minexptime = 0.1,
        maxexptime = 0.3,
        minsize = 0.3,
        maxsize = 0.4,
        texture = {
            name = "va_explosion_spark.png^[colorize:#00ff00:alpha",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = { 1, 0.25 },
            scale_tween = { {
                x = 1.5,
                y = 1.5
            }, {
                x = 0.25,
                y = 0.25
            } }
        },
        glow = 14,
    })
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

-- Rotate a 3‑D vector `v` first by a yaw around the Y‑axis,
-- then by a pitch around the X‑axis.
-- Angles are in radians (positive yaw → rotate toward +Z, positive pitch → toward +Z).
local function rotate_yaw_pitch(v, yaw, pitch)
    local cy = math.cos(yaw)
    local sy = math.sin(yaw)
    local cp = math.cos(pitch)
    local sp = math.sin(pitch)

    -- ---------- Yaw (around Y) ----------
    -- Right‑handed system: x′ = x cosθ + z sinθ
    --                       z′ = –x sinθ + z cosθ
    local x1 = v.x * cy + v.z * sy
    local z1 = -v.x * sy + v.z * cy
    local y1 = v.y            -- Y is unchanged by yaw

    -- ---------- Pitch (around X) ----------
    -- y′ = y cosφ – z sinφ
    -- z′ = y sinφ + z cosφ
    local y2 = y1 * cp - z1 * sp
    local z2 = y1 * sp + z1 * cp

    return {x = x1, y = y2, z = z2}
end

local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    if run_stage == "weapon" then
        -- weapons run
        local meta = core.get_meta(pos)
        if meta:get_int("attack_mode") == 3 then
            return
        end
        local range = 16
        local target = s_obj._last_target or find_target(s_obj, range)
        if target and not s_obj._target_locked then
            s_obj._last_target = target
           do_turret_rotation(s_obj, target)
        end
    elseif run_stage == "main" then
        local meta = core.get_meta(pos)
        if meta:get_int("attack_mode") == 3 then
            return
        end

        local shooter = s_obj.entity_obj
        local damage = 10
        local range = 27
        local target = s_obj._last_target or find_target(s_obj, range)

        if target then
            s_obj._last_target = target
            local yaw, yaw_deg = va_structures.util.calculateYaw(pos, target)
            local pitch, pitch_deg = va_structures.util.calculatePitch(pos, target)
            local turret_end_1_a = {
                x = (-10.5 * 1 / 16) * 0.66,
                y = (0.0 * 1 / 16) * 0.66,
                z = (-44 * 1 / 16) * 0.66
            }
            local turret_end_1_b = {
                x = (-10.5 * 1 / 16) * 0.66,
                y = (0.0 * 1 / 16) * 0.66,
                z = (-24 * 1 / 16) * 0.66
            }
            local turret_end_2_a = {
                x = (10.5 * 1 / 16) * 0.66,
                y = (0.0 * 1 / 16) * 0.66,
                z = (-44 * 1 / 16) * 0.66
            }
            local turret_end_2_b = {
                x = (10.5 * 1 / 16) * 0.66,
                y = (0.0 * 1 / 16) * 0.66,
                z = (-24 * 1 / 16) * 0.66
            }

            local turret_end_pos_1 = rotate_yaw_pitch(turret_end_1_a, yaw, pitch)
            local turret_end_pos_1_b = rotate_yaw_pitch(turret_end_1_b, yaw, pitch)
            local turret_end_pos_2 = rotate_yaw_pitch(turret_end_2_a, yaw, pitch)
            local turret_end_pos_2_b = rotate_yaw_pitch(turret_end_2_b, yaw, pitch)
            -- pos 1
            local o_pos_1 = vector.add(s_obj.pos, turret_end_pos_1)
            o_pos_1 = vector.add(o_pos_1, {x=0,y=(38.5 * 1 / 16) * 0.66,z=0})
            local o_pos_1_b = vector.add(s_obj.pos, turret_end_pos_1_b)
            o_pos_1_b = vector.add(o_pos_1_b, {x=0,y=(38.5 * 1 / 16) * 0.66,z=0})
            -- pos 2
            local o_pos_2 = vector.add(s_obj.pos, turret_end_pos_2)
            o_pos_2 = vector.add(o_pos_2, {x=0,y=(38.5 * 1 / 16) * 0.66,z=0})
            local o_pos_2_b = vector.add(s_obj.pos, turret_end_pos_2_b)
            o_pos_2_b = vector.add(o_pos_2_b, {x=0,y=(38.5 * 1 / 16) * 0.66,z=0})
            -- target pos
            local t_pos = vector.add(target, vector.new(0, 0.175, 0))

            local cost = s_obj:get_data():get_energy_consume()
            local energy = net.energy
            if energy - cost >= 0 then
                do_turret_rotation(s_obj, target)
                s_obj._fire_index = s_obj._fire_index - 1
                if s_obj._target_locked and s_obj._fire_index <= 0 then
                    s_obj._fire_index = 1
                    net.energy = energy - cost
                    local weapon = va_weapons.get_weapon("heavy_laser")
                    local x = va_structures.util.randFloat(-0.1, 0.1)
                    local y = va_structures.util.randFloat(-0.1, 0.1)
                    local z = va_structures.util.randFloat(-0.1, 0.1)
                    local tr_pos = vector.add(t_pos, vector.new(x, y, z))
                    if s_obj._out_index == 0 then
                        s_obj._out_index = 1
                        local dir = vector.direction(o_pos_1_b, target)
                        muzzle_effect_particle(o_pos_1_b, dir)
                        weapon.fire(shooter, o_pos_1, tr_pos, range, damage)
                    else
                        s_obj._out_index = 0
                        local dir = vector.direction(o_pos_2_b, target)
                        muzzle_effect_particle(o_pos_2_b, dir)
                        weapon.fire(shooter, o_pos_2, tr_pos, range, damage)
                    end
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
    mesh = "va_vox_heavy_laser_tower.gltf",
    textures = {"va_vox_heavy_laser_tower.png"},
    collisionbox = {-0.475, -0.5, -0.475, 0.475, 2.15, 0.475},
    max_health = 260,
    mass_cost = 44,
    energy_cost = 470,
    energy_consume = 3,
    build_time = 1250,
    formspec = get_formspec,
    on_receive_fields = on_receive_fields,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "heavy_laser_tower"
def.desc = "Heavy Laser Tower"
def.size = {
    x = 1,
    y = 2.55,
    z = 1
}
def.category = "combat"
def.tier = 1
def.faction = "vox"

def.do_rotate = false

-- Register a new Heavy Laser Tower
Structure.register(def)

