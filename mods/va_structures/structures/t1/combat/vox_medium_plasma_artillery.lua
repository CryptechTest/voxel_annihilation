-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Plasma Artillery
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

local function muzzle_effect_particle(origin, dir)
    --Fire flash
    core.add_particle({
        pos = origin,
        expirationtime = 0.1,
        size = 2.5,
        collisiondetection = false,
        vertical = false,
        texture = "va_structures_explosion_2.png",
        glow = 13,
    })
    local r = 0.25
    local s_vel = vector.multiply(dir, 2.75)
    local s_vel_min = vector.subtract(s_vel, {x=math.random(-r,r), y=math.random(-r,r), z=math.random(-r,r)})
    local s_vel_max = vector.add(s_vel, {x=math.random(-r,r), y=math.random(-r,r), z=math.random(-r,r)})
    local s_pos = {x=origin.x+dir.x*0.01, y=origin.y+dir.y*0.01, z=origin.z+dir.z*0.01}
    core.add_particlespawner({
        amount = 27,
        time = 0.075,
        minpos = {x=s_pos.x-0.01, y=s_pos.y-0.01, z=s_pos.z-0.01},
        maxpos = {x=s_pos.x+0.01, y=s_pos.y+0.01, z=s_pos.z+0.01},
        minvel = s_vel_min,
        maxvel = s_vel_max,
        minacc = {x=-0.25, y=-0.28, z=-0.25},
        maxacc = {x=0.25, y=0.28, z=0.25},
        minexptime = 0.2,
        maxexptime = 0.5,
        minsize = 0.2,
        maxsize = 0.4,
        texture = {
            name = "va_explosion_spark.png",
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
    local dist = vector.distance(pos, target)
    -- building effect turret rotation
    local yaw, yaw_deg = va_structures.util.calculateYaw(pos, target)
    local pitch, pitch_deg = va_structures.util.calculatePitch(pos, target)
    pitch_deg = math.min(50, pitch_deg + (dist * 1.08))
    pitch_deg = math.min(88, math.max(-10, pitch_deg))
    local turret = structure.entity_obj:get_bone_override('turret')
    local barrel = structure.entity_obj:get_bone_override('barrels')
    local yawRad = turret.rotation and turret.rotation.vec.y or 0
    local pitchRad = barrel.rotation and barrel.rotation.vec.x or 0
    local yawDeg = yaw_deg -- yawDeg = ((yawDeg + (yaw_deg * 1)) / 2) % 360
    if structure._last_dir ~= nil and num_is_close(yawDeg, math.deg(yawRad), 3) and num_is_close(pitch_deg, math.deg(pitchRad), 2) then
        -- if rotation complete mark as locked
        structure._target_locked = true
    end
    if structure._last_dir == nil or yaw_deg ~= structure._last_dir.yaw or pitch_deg ~= structure._last_dir.pitch then
        if not num_is_close(yawDeg, math.deg(yawRad), 8) or not num_is_close(pitch_deg, math.deg(pitchRad), 10) then
            structure._target_locked = false
        end
        structure._last_dir = {}
        structure._last_dir.yaw = yaw_deg
        structure._last_dir.pitch = pitch_deg
        local rot_turret = {
            x = 0,
            y = math.rad(yawDeg),
            z = 0
        }
        local rot_barrel = {
            x = math.rad(pitch_deg),
            y = 0,
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
        structure.entity_obj:set_bone_override("barrels", {
            rotation = {
                vec = rot_barrel,
                absolute = true,
                interpolation = 0.8
            }
        })
    end
end

local function can_see(origin, obj)
    local node_count = 0
    local target_pos = vector.add(obj:get_pos(), vector.new(0, 0.51, 0))
    local ray = core.raycast(origin, target_pos, false, true, nil)
    for pointed_thing in ray do
        if pointed_thing.type == "object" and pointed_thing.ref ~= obj then
            if pointed_thing.ref:get_pos() ~= origin then
                node_count = node_count + 0.5
            end
        elseif pointed_thing.type == "node" and pointed_thing.under ~= target_pos then
            if pointed_thing.under ~= origin then
                node_count = node_count + 1
            end
        end
    end
    return node_count < 8
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
        return targets[1]:get_pos()
    end
    return nil
end

local function rotate_y(vector, angle_yaw, angle_pitch)
    local cos_a = math.cos(angle_yaw)
    local sin_a = math.sin(angle_yaw)
    local sin_p = math.sin(angle_pitch)
    local cos_p = math.cos(angle_pitch)
    local x = vector.x * cos_a - vector.z * sin_a
    local z = vector.x * sin_a + vector.z * cos_a
    local y = vector.y * cos_p - vector.y * sin_p
    return {
        x = x,
        y = -y,
        z = -z
    }
end

local function get_spread(spread)
    return (math.random(-32768, 32768)/65536)*spread
end

local function calc_plasma_volley(origin, target)
    local projectile_speed = 1.2
    local projectile_gravity = -9.81
    local spread = 0.175
    local shot_amount = 2;

    local dist = vector.distance(origin, target)
    local n_dist = dist * 0.01
    --Get port position to use based on facing
    local dir = vector.normalize(target - origin);
    local vel = vector.multiply(dir, 12)
    vel.y = vel.y + (n_dist * (0 + math.abs(projectile_gravity))*3.5)
    --local pitch, pitch_deg = va_structures.util.calculatePitch(origin, target)
    local pitch_deg = (3 + ((dist)*1.5)) % 360
    local yaw, yaw_deg = va_structures.util.calculateYaw(origin, target)
    --Set projectile port origin position
    local function get_port_pos()
        if shot_amount == 1 then
            local port_a = {x = 0, y = 0.0 + (dir.y * 1), z = -0.5}
            port_a = vector.add(origin, vector.rotate_around_axis(port_a, {x = 0, y = 1, z = 0}, -yaw))
            return port_a, port_a
        else
            local port_a_s = {x = -0.325, y = (1.03125)*n_dist, z = 1.07}
            local port_b_s = {x = 0.325, y = (1.03125)*n_dist, z = 1.07}
            local pitch_rad = math.rad(pitch_deg)
            local port_a = vector.add(vector.add(origin, rotate_y(port_a_s, yaw, pitch_rad)), {x = 0, y = 0.55 + (1*dist*0.02), z = 0})
            local port_b = vector.add(vector.add(origin, rotate_y(port_b_s, yaw, pitch_rad)), {x = 0, y = 0.55 + (1*dist*0.02), z = 0})
            return port_a, port_b
        end
    end

    local port_a, port_b = get_port_pos()
    local l_vel = {x=((dir.x+get_spread(spread))*projectile_speed)+vel.x,
                    y=((dir.y+get_spread(spread))*projectile_speed)+vel.y,
                    z=((dir.z+get_spread(spread))*projectile_speed)+vel.z}

    --Combine velocity with launch velocity
    return {vec = {velocity = l_vel, direction = vector.normalize(l_vel)}, port_a = port_a, port_b = port_b}
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
        local range = 48
        local target = s_obj._last_target or find_target(s_obj, range)
        if target and not s_obj._target_locked then
            s_obj._last_target = target
           do_turret_rotation(s_obj, target)
        end
    elseif run_stage == "main" then
        -- main run
        local meta = core.get_meta(pos)
        if meta:get_int("attack_mode") == 3 then
            return
        end

        local shooter = s_obj.entity_obj
        local damage = 10
        local range = 48
        local target = s_obj._last_target or find_target(s_obj, range)

        if target then
            s_obj._last_target = target
            local o_pos = vector.new(s_obj.pos)
            local t_pos = vector.add(target, vector.new(0, 0.1, 0))
            local cost = s_obj:get_data():get_energy_consume()
            local energy = net.energy
            if energy - cost >= 0 then
                do_turret_rotation(s_obj, target)
                s_obj._fire_index = s_obj._fire_index - 1
                if s_obj._target_locked and s_obj._fire_index <= 0 then
                    s_obj._fire_index = 2
                    net.energy = energy - cost
                    local weapon = va_weapons.get_weapon("plasma")
                    local x = va_structures.util.randFloat(-0.2, 0.2)
                    local y = va_structures.util.randFloat(-0.1, 0.2)
                    local z = va_structures.util.randFloat(-0.2, 0.2)
                    local tr_pos = vector.add(t_pos, vector.new(x, y, z))
                    local l_vec = calc_plasma_volley(o_pos, t_pos)
                    local r1 = math.random(0,1)
                    if r1 == 0 then
                        core.after(0.0, function ()
                            muzzle_effect_particle(l_vec.port_a, l_vec.vec.direction)
                            weapon.fire(shooter, l_vec.port_a, tr_pos, range, damage, l_vec.vec)
                        end)
                        core.after(0.25, function ()
                            muzzle_effect_particle(l_vec.port_b, l_vec.vec.direction)
                            weapon.fire(shooter, l_vec.port_b, tr_pos, range, damage, l_vec.vec)
                        end)
                    else
                        core.after(0.25, function ()
                            muzzle_effect_particle(l_vec.port_a, l_vec.vec.direction)
                            weapon.fire(shooter, l_vec.port_a, tr_pos, range, damage, l_vec.vec)
                        end)
                        core.after(0.0, function ()
                            muzzle_effect_particle(l_vec.port_b, l_vec.vec.direction)
                            weapon.fire(shooter, l_vec.port_b, tr_pos, range, damage, l_vec.vec)
                        end)
                    end
                    s_obj._last_target = nil
                end
            end
            net.energy_demand = net.energy_demand + cost
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_vox_medium_plasma_artillery.gltf",
    textures = {"va_vox_medium_plasma_artillery.png"},
    textures_color = {"va_vox_medium_plasma_artillery_team.png"},
    collisionbox = {-0.85, -0.5, -0.85, 0.85, 1.05, 0.85},
    max_health = 305,
    mass_cost = 125,
    energy_cost = 1250,
    build_time = 2140,
    formspec = get_formspec,
    on_receive_fields = on_receive_fields,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "medium_plasma_artillery"
def.desc = "Plasma Artillery"
def.size = {
    x = 1,
    y = 1,
    z = 1
}
def.category = "combat"
def.tier = 1
def.faction = "vox"

def.do_rotate = false

-- Register a new Plasma Artillery
Structure.register(def)

