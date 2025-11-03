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

local is_player_near = function(pos)
    local objs = core.get_objects_inside_radius(pos, 64)
    for _, obj in pairs(objs) do
        if obj:is_player() then
            return true;
        end
    end
    return false;
end

local function spawn_particles(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, time, amount)
    if (not is_player_near(pos)) then
        return;
    end
    local animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = (time or 6) + 1
    }
    local texture = {
        name = "va_vapor_anim.png",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.1},
        scale_tween = {{
            x = 0.5,
            y = 1.0
        }, {
            x = 8.8,
            y = 7.1
        }}
    }

    local prt = {
        texture = texture,
        vel = 0.28,
        time = (time or 6),
        size = 0.75 + (lvl or 1),
        glow = 3,
        cols = false
    }

    local v = vector.new()
    v.x = 0.0001
    v.y = 0.001
    v.z = 0.0001
    if math.random(0, 10) > 1 then
        local rx = dir_x * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        local ry = dir_y * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        local rz = dir_z * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        core.add_particlespawner({
            amount = amount,
            pos = pos,
            minpos = {
                x = -0.1,
                y = 0.1,
                z = -0.1
            },
            maxpos = {
                x = 0.1,
                y = 0.25,
                z = 0.1
            },
            minvel = {
                x = rx * 0.8,
                y = (ry * 0.8) + 1.37,
                z = rz * 0.8
            },
            maxvel = {
                x = rx,
                y = ry + 1.25,
                z = rz
            },
            minacc = {
                x = acl_x * 0.7,
                y = acl_y * 0.8,
                z = acl_z * 0.7
            },
            maxacc = {
                x = acl_x,
                y = acl_y + math.random(-0.008, 0),
                z = acl_z
            },
            time = (prt.time + 3) * 0.75,
            minexptime = prt.time - math.random(0, 2),
            maxexptime = prt.time + math.random(0, 1),
            minsize = ((math.random(0.77, 0.93)) * 2 + 1.6) * prt.size,
            maxsize = ((math.random(0.77, 0.93)) * 2 + 1.6) * prt.size,
            collisiondetection = prt.cols,
            vertical = false,
            texture = texture,
            animation = animation,
            glow = prt.glow
        })
    end
end

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
        local mass_group = core.get_item_group(node.name, 'va_geo_vent')
        local value = meta:get_int("va_geo_vent_amount") * 0.01
        if mass_group > 0 then
            has_power = true
            local amount = 1
            if mass_group == 2 then
                amount = 0.80
                base_rate = 0.7
            elseif mass_group == 1 then
                amount = 0.60
                base_rate = 0.4
            end
            local gen = s_obj:get_data():get_energy_generate()
            local generate = value * gen * amount
            local mass = net.mass
            local energy = net.energy
            if energy + gen <= net.energy_storage then
                net.energy = energy + generate
            else
                net.energy = net.energy_storage
            end
            net.energy_supply = net.energy_supply + generate
        end

        if has_power then
            local speed = 70 * base_rate  * (value)
            local overrides = s_obj.entity_obj:get_bone_override('rotor')
            local yawRad = overrides.rotation and overrides.rotation.vec.y or 0
            local yawDeg = math.deg(yawRad)
            yawDeg = (yawDeg + speed) % 360
            local rotation = {
                x = 0,
                y = math.rad(yawDeg),
                z = 0
            }
            s_obj.entity_obj:set_bone_override("rotor", {
                rotation = {
                    vec = rotation,
                    absolute = true,
                    interpolation = 1.0
                }
            })

            local pos_above = vector.add(pos, {
                x = 0,
                y = 1.65,
                z = 0
            })
            -- get wind system data for particle effect
            local vel = va_resources.get_env_wind_vel().velocity
            local dir = math.rad(va_resources.get_env_wind_vel().direction)
            local dir_x = math.sin(dir) * vel
            local dir_z = math.cos(dir) * vel
            spawn_particles(pos_above, dir_x, -1, dir_z, 0.88 * dir_x, -0.167, 0.88 * dir_z, 0.5, 3, 21)
            
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_vox_geothermal_plant_1.gltf",
    textures = {"va_vox_geo_plant_1.png"},
    collisionbox = {-1.25, -0.75, -1.25, 1.25, 1.5, 1.25},
    max_health = 30,
    mass_cost = 56,
    energy_cost = 1300,
    energy_generate = 30,
    energy_storage = 20,
    build_time = 1310,
    self_explosion_radius = 6.20,
    death_explosion_radius = 5.05,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "geothermal_plant"
def.desc = "Geothermal Plant"
def.size = {
    x = 1,
    y = 1.0,
    z = 1
}
def.category = "economy"
def.tier = 2
def.faction = "vox"

-- Register a new Geothermal Plant
Structure.register(def)
