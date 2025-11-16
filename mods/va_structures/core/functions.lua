va_structures.util = {}

local function randFloat(min, max, precision)
    -- Generate a random floating point number between min and max
    local range = max - min
    local offset = range * math.random()
    local unrounded = min + offset

    -- Return unrounded number if precision isn't given
    if not precision then
        return unrounded
    end

    -- Round number to precision and return
    local powerOfTen = 10 ^ precision
    local n
    n = unrounded * powerOfTen
    n = n + 0.5
    n = math.floor(n)
    n = n / powerOfTen
    return n
end

va_structures.util.randFloat = randFloat

local function calculatePitch(vector1, vector2)
    -- Calculate the difference vector
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    -- Calculate the pitch angle
    local pitch = math.atan2(dy, math.sqrt(dx * dx + dz * dz))
    -- Optional: Convert pitch from radians to degrees
    -- local pitch_degrees = pitch * 180 / math.pi
    local pitch_degrees = math.deg(pitch)
    return pitch, pitch_degrees
end
va_structures.util.calculatePitch = calculatePitch

local function calculateYaw(vector1, vector2)
    -- Calculate yaw for each vector
    local yaw = math.atan2(vector1.x - vector2.x, vector1.z - vector2.z)
    -- Optional: Convert to degrees
    -- local yaw_degrees = yaw * 180 / math.pi
    local yaw_degrees = math.deg(yaw) + 0
    return math.rad(yaw_degrees), yaw_degrees
end
va_structures.util.calculateYaw = calculateYaw

-----------------------------------------------------------------

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

va_structures.util.deepcopy = deepcopy

-----------------------------------------------------------------
-----------------------------------------------------------------

local function flip_vector_yz(v)
    return {x=v.x, y=v.z, z=v.y}
end

-- helper: normalize a vector (returns a unit vector)
local function normalize_vector(v)
    local len = math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
    if len == 0 then
        return {x = 0, y = 0, z = 0}
    end
    return {x = v.x/len, y = v.y/len, z = v.z/len}
end

-- rotate a vector on the surface of its sphere
--   v      – {x,y,z}  (original point)
--   d_phi  – change in azimuth (radians, 0 → +x→+y)
--   d_theta– change in polar (radians, 0 → +z→-z)
local function rotate_on_sphere(v, d_phi, d_theta)
    -- 1. Cartesian → spherical
    local r   = math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
    local phi = math.atan2(v.y, v.x)          -- azimuth  (-π .. +π)
    local theta = math.acos(v.z / r)          -- polar     (0 .. π)

    -- 2. Apply the angular offsets
    phi   = phi   + d_phi
    theta = theta + d_theta

    -- keep theta inside [0, π]
    if theta < 0 then theta = -theta end
    if theta > math.pi then theta = 2*math.pi - theta end

    -- 3. Spherical → Cartesian
    local sin_t = math.sin(theta)
    local x = r * sin_t * math.cos(phi)
    local y = r * sin_t * math.sin(phi)
    local z = r * math.cos(theta)

    return {x=x, y=y, z=z}
end

-- rotate vector v around axis k (both normalized) by angle theta (rad)
local function rotate_vector(v, k, theta)
    local cos_t = math.cos(theta)
    local sin_t = math.sin(theta)

    local vx, vy, vz = v.x, v.y, v.z
    local kx, ky, kz = k.x, k.y, k.z

    -- Rodrigues’ rotation formula
    local rx = (cos_t + (1-cos_t)*kx*kx) * vx
            + ((1-cos_t)*kx*ky - sin_t*kz) * vy
            + ((1-cos_t)*kx*kz + sin_t*ky) * vz

    local ry = ((1-cos_t)*ky*kx + sin_t*kz) * vx
            + (cos_t + (1-cos_t)*ky*ky) * vy
            + ((1-cos_t)*ky*kz - sin_t*kx) * vz

    local rz = ((1-cos_t)*kz*kx - sin_t*ky) * vx
            + ((1-cos_t)*kz*ky + sin_t*kx) * vy
            + (cos_t + (1-cos_t)*kz*kz) * vz

    return {x=rx, y=ry, z=rz}
end

va_structures.util.flip_vector_yz = flip_vector_yz
va_structures.util.normalize_vector = normalize_vector
va_structures.util.rotate_on_sphere = rotate_on_sphere
va_structures.util.rotate_vector = rotate_vector

-----------------------------------------------------------------
-----------------------------------------------------------------
-- Particles
-----------------------------------------------------------------

local function build_effect_particle(pos, texture, _dir, dist, size, count, r, center)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    local dir = vector.multiply(_dir, {
        x = 0.8,
        y = 0.8,
        z = 0.8
    })
    local dir = vector.multiply(dir, ((size + 1) / 2))
    local t = 1 + (dist * 0.2) - randFloat(0.2, 0.4)
    local texture = texture
    if math.random(0, 1) == 0 then
        texture = texture .. "^[transformR90"
    end
    local minpos = {
        x = pos.x - r,
        y = pos.y - r,
        z = pos.z - r
    }
    local maxpos = {
        x = pos.x + r + (_dir.x * dist) - (dir.x * r * 2),
        y = pos.y + r + (_dir.y * dist) - (dir.y * r * 2),
        z = pos.z + r + (_dir.z * dist) - (dir.z * r * 2)
    }
    if center then
        minpos = {
            x = pos.x - r + (_dir.x * dist * 0.3),
            y = pos.y - r + (_dir.y * dist * 0.3),
            z = pos.z - r + (_dir.z * dist * 0.3)
        }
        maxpos = {
            x = pos.x + r + (_dir.x * dist * 0.55),
            y = pos.y + r + (_dir.y * dist * 0.55),
            z = pos.z + r + (_dir.z * dist * 0.55)
        }
        count = math.min(32, count)
    else
        count = math.min(40, count)
    end
    local def = {
        amount = count,
        minpos = minpos,
        maxpos = maxpos,
        minvel = {
            x = dir.x,
            y = dir.y,
            z = dir.z
        },
        maxvel = {
            x = dir.x,
            y = dir.y,
            z = dir.z
        },
        minacc = {
            x = -dir.x * 0.15,
            y = randFloat(-0.02, -0.01) * grav,
            z = -dir.z * 0.15
        },
        maxacc = {
            x = dir.x * 0.15,
            y = randFloat(0.01, 0.02) * grav,
            z = dir.z * 0.15
        },
        time = t * 0.88,
        minexptime = t - 0.28,
        maxexptime = t,
        minsize = randFloat(1.02, 1.42) * ((size + 0.5) / 2),
        maxsize = randFloat(1.05, 1.44) * ((size + 0.81) / 2),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = texture,
            alpha = 1,
            alpha_tween = {1, 0.88},
            scale_tween = {{
                x = 1.5,
                y = 1.5
            }, {
                x = 0.0,
                y = 0.0
            }},
            blend = "alpha"
        },
        glow = 13
    }

    core.add_particlespawner(def);
end

local function build_effect_particles(pos, dist)
    local dir = {
        x = 0,
        y = 1,
        z = 0
    }
    local dist = dist or 1.5
    local size = 2
    local count = 28
    local radius = 0.8
    build_effect_particle(pos, "va_structures_energy_particle.png", dir, dist, size, count, radius, false)
end

local function build_effect_particles_halt(pos, dist)
    local dir = {
        x = 0,
        y = 1,
        z = 0
    }
    local dist = dist or 1.5
    local size = 2
    local count = 25
    local radius = 0.9
    build_effect_particle(pos, "va_structures_energy_particle_halt.png", dir, dist, size, count, radius, false)
end

local function build_effect_particles_cancel(pos, dist)
    local dir = {
        x = 0,
        y = 1,
        z = 0
    }
    local dist = dist or 1.5
    local size = 2
    local count = 70
    local radius = 0.9
    build_effect_particle(pos, "va_structures_energy_particle_halt.png^[colorize:#FF0000:200", dir, dist, size, count,
        radius, false)
end

va_structures.particle_build_effect = build_effect_particles
va_structures.particle_build_effect_halt = build_effect_particles_halt
va_structures.particle_build_effect_cancel = build_effect_particles_cancel

-----------------------------------------------------------------

local function particle_build_effects(target, source, count, color)

    --beam_effect(source, target, min, count)
    va_structures.show_build_beam_effect(source, target, count, color)

end

va_structures.particle_build_effects = particle_build_effects

-----------------------------------------------------------------

local function spawn_build_beam_particles(pos, texture, _dir, dist, count)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    count = count * 1.5
    if dist < 2.5 then
        count = math.floor(count * 0.4)
    end
    local size = 0.357
    local vel = vector.multiply(_dir, math.max(1.2, dist * 0.227))
    local t = 1.0 + math.min(dist * 0.322, 3.92)
    if dist <= 1.75 then
        t = t - 0.85
        vel = vector.multiply(vel, 0.75)
    elseif dist <= 3 then
        t = t - 0.65
        vel = vector.multiply(vel, 0.9)
    elseif dist <= 5 then
        t = t + 0.55
    end
    if dist <= 8 then
        t = t + 0.525
        vel = vector.multiply(vel, 1.1)
    end
    if dist >= 13 then
        t = t - 0.45
    elseif dist >= 9 then
        t = t - 0.20
    end
    texture = texture
    if math.random(0, 1) == 0 then
        texture = texture .. "^[transformR90"
    end
    local r = 0.02
    local minpos = {
        x = pos.x - r,
        y = pos.y - r,
        z = pos.z - r
    }
    local maxpos = {
        x = pos.x + r,
        y = pos.y + r,
        z = pos.z + r
    }
    local def = {
        amount = count,
        minpos = minpos,
        maxpos = maxpos,
        minvel = {
            x = vel.x,
            y = vel.y,
            z = vel.z
        },
        maxvel = {
            x = vel.x,
            y = vel.y,
            z = vel.z
        },
        minacc = {
            x = -vel.x * 0.05,
            y = randFloat(-0.01, -0.001) * grav,
            z = -vel.z * 0.05
        },
        maxacc = {
            x = vel.x * 0.05,
            y = randFloat(0.001, 0.01) * grav,
            z = vel.z * 0.05
        },
        time = math.max(1, t * 0.5),
        minexptime = t - 0.21,
        maxexptime = t,
        minsize = randFloat(1.02, 1.42) * ((size + 0.5) / 2),
        maxsize = randFloat(1.05, 1.44) * ((size + 0.81) / 2),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = texture,
            alpha = 1,
            alpha_tween = {1, 0.7},
            scale_tween = {{
                x = 1.0,
                y = 1.0
            }, {
                x = 2.8,
                y = 2.8
            }},
            blend = "alpha"
        },
        glow = 13
    }

    core.add_particlespawner(def);
end

local function spawn_reclaim_beam_particles(pos, texture, _dir, dist, count)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    count = count * 2
    if dist < 3 then
        count = count * 0.5
    end
    local size = 0.357
    local vel = vector.multiply(_dir, math.max(1.2, dist * 0.228))
    local t = 1.0 + math.min(dist * 0.312, 3.93)
    if dist <= 3 then
        t = t - 0.65
        vel = vector.multiply(vel, 0.9)
    elseif dist <= 5 then
        t = t + 0.5
    end
    if dist <= 8 then
        t = t + 0.325
        vel = vector.multiply(vel, 1.07)
    end
    if dist >= 13 then
        t = t - 0.65
    elseif dist >= 9 then
        t = t - 0.27
    end
    if math.random(0, 1) == 0 then
        texture = texture .. "^[transformR90"
    end
    local r = 0.088
    local minpos = {
        x = pos.x - r,
        y = pos.y - r,
        z = pos.z - r
    }
    local maxpos = {
        x = pos.x + r,
        y = pos.y + r + 0.07,
        z = pos.z + r
    }
    local def = {
        amount = count,
        minpos = minpos,
        maxpos = maxpos,
        minvel = {
            x = vel.x,
            y = vel.y,
            z = vel.z
        },
        maxvel = {
            x = vel.x,
            y = vel.y,
            z = vel.z
        },
        minacc = {
            x = -vel.x * 0.005,
            y = randFloat(-0.01, -0.001) * grav,
            z = -vel.z * 0.005
        },
        maxacc = {
            x = vel.x * 0.005,
            y = randFloat(0.001, 0.01) * grav,
            z = vel.z * 0.005
        },
        time = math.max(1.2, t * 0.5),
        minexptime = t - 0.21,
        maxexptime = t,
        minsize = randFloat(1.02, 1.42) * ((size + 0.5) / 2),
        maxsize = randFloat(1.05, 1.44) * ((size + 0.81) / 2),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = texture,
            alpha = 1,
            alpha_tween = {1.0, 0.7},
            scale_tween = {{
                x = 3.6,
                y = 3.6
            }, {
                x = 0.7,
                y = 0.7
            }},
            blend = "alpha"
        },
        glow = 13
    }

    core.add_particlespawner(def);
end

local function show_build_beam_effect(pos1, pos2, count, color)
    color = color or "#00ff00"
    local dir = vector.direction(pos1, pos2)
    core.after(0, function()
        local cur_pos = vector.add(pos1, vector.multiply(dir, {
            x = 0.2,
            y = 0.2,
            z = 0.2
        }))
        local dist = vector.distance(cur_pos, pos2)
        spawn_build_beam_particles(cur_pos, "va_structures_effect_build_particle.png^[colorize:"..color..":alpha", dir, dist, count)
    end)
    return true
end
va_structures.show_build_beam_effect = show_build_beam_effect

function va_structures.show_reclaim_beam_effect(target, source, count, color)
    color = color or "#00ff00"
    core.after(0, function()
        local dir = vector.direction(target, source)
        local cur_pos = vector.add(source, vector.multiply(dir, {
            x = 0.2,
            y = 0.2,
            z = 0.2
        }))
        local dist = vector.distance(target, cur_pos)
        spawn_reclaim_beam_particles(target, "va_structures_effect_build_particle.png^[colorize:"..color..":alpha", dir, dist, count)
    end)
end

-----------------------------------------------------------------

local function destroy_effect_particle(pos, radius)
    core.add_particle({
        pos = pos,
        velocity = vector.new(),
        acceleration = vector.new(),
        expirationtime = 0.64,
        size = radius * 16,
        collisiondetection = false,
        vertical = false,
        texture = "va_structures_explosion_2.png",
        glow = 15
    })
    core.add_particlespawner({
        amount = 12,
        time = 0.6,
        minpos = vector.subtract(pos, radius / 4),
        maxpos = vector.add(pos, radius / 4),
        minvel = {
            x = -1,
            y = -0.5,
            z = -1
        },
        maxvel = {
            x = 1,
            y = 1,
            z = 1
        },
        minacc = vector.new(),
        maxacc = vector.new(),
        minexptime = 3,
        maxexptime = 7,
        minsize = radius * 4,
        maxsize = radius * 7,
        texture = {
            name = "va_explosion_vapor.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = {1, 0},
            scale_tween = {{
                x = 0.5,
                y = 0.5
            }, {
                x = 5,
                y = 5
            }}
        },
        collisiondetection = true,
        glow = 3
    })
    core.add_particlespawner({
        amount = 16,
        time = 0.8,
        minpos = vector.subtract(pos, radius / 3),
        maxpos = vector.add(pos, radius / 3),
        minvel = {
            x = -1,
            y = -0.5,
            z = -1
        },
        maxvel = {
            x = 1,
            y = 1.25,
            z = 1
        },
        minacc = vector.new(),
        maxacc = vector.new(),
        minexptime = 2,
        maxexptime = 5,
        minsize = radius * 3,
        maxsize = radius * 6,
        -- texture = "tnt_smoke.png",
        texture = {
            name = "va_explosion_smoke.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = {1, 0},
            scale_tween = {{
                x = 0.25,
                y = 0.25
            }, {
                x = 6,
                y = 5
            }}
        },
        collisiondetection = true,
        glow = 5
    })
    core.add_particlespawner({
        amount = 72,
        time = 0.45,
        minpos = vector.subtract(pos, radius / 2),
        maxpos = vector.add(pos, radius / 2),
        minvel = {
            x = -3.5,
            y = -3.5,
            z = -3.5
        },
        maxvel = {
            x = 3.5,
            y = 5.0,
            z = 3.5
        },
        minacc = {
            x = -0.5,
            y = -2.0,
            z = -0.5
        },
        maxacc = {
            x = 0.5,
            y = 0.5,
            z = 0.5
        },
        minexptime = 0.5,
        maxexptime = 2,
        minsize = radius * 0.2,
        maxsize = radius * 0.6,
        texture = {
            name = "va_explosion_spark.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = {1, 0.5},
            scale_tween = {{
                x = 1.0,
                y = 1.0
            }, {
                x = 0,
                y = 0
            }}
        },
        collisiondetection = true,
        glow = 15
    })

end

va_structures.destroy_effect_particle = destroy_effect_particle

-----------------------------------------------------------------
-----------------------------------------------------------------
-- Sounds

local function explode_effect_sound(pos, r)
    core.sound_play("va_weapons_explosion", {
        pos = pos,
        gain = 1.25,
        pitch = 1.0,
        max_hear_distance = math.min(r * 20, 64)
    }, true)
end

va_structures.explode_effect_sound = explode_effect_sound


function va_structures.water_effect_particle(parent, count)
    local grav = 1;
    local dist = 10
    local t = 1 + (dist * 0.2) - randFloat(0.2, 0.4)
    local texture = "bubble.png"
    local size = 0.4
    local radius = 0.6
    local minpos = {x=-radius, y=0.6, z=-radius}
    local maxpos = {x=radius, y=0.6, z=radius}
    local def = {
        attached = parent,
        amount = count,
        minpos = minpos,
        maxpos = maxpos,
        minvel = {
            x = -0.1,
            y = 0.2,
            z = -0.1
        },
        maxvel = {
            x = 0.1,
            y = 0.4,
            z = 0.1
        },
        minacc = {
            x = -1 * 0.25,
            y = randFloat(0.01, 0.02) * grav,
            z = -1 * 0.25
        },
        maxacc = {
            x = 1 * 0.25,
            y = randFloat(0.025, 0.05) * grav,
            z = 1 * 0.25
        },
        time = t * 0.1,
        minexptime = t - 0.28,
        maxexptime = t,
        minsize = randFloat(1.02, 1.42) * ((size + 0.5) / 2),
        maxsize = randFloat(1.05, 1.44) * ((size + 0.81) / 2),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = texture,
            alpha = 1,
            alpha_tween = {1, 0.1},
            scale_tween = {{
                x = 1.0,
                y = 1.0
            }, {
                x = 1.5,
                y = 1.5
            }},
            blend = "alpha"
        },
        glow = 5
    }

    core.add_particlespawner(def);
end


local function reclaim_effect_particle(pos, texture, _dir, dist, size, count, r)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    local dir = vector.multiply(_dir, ((size + 1) / 2))
    local t = 1 + (dist * 0.275) - randFloat(0.05, 0.2)
    if math.random(0, 1) == 0 then
        texture = texture .. "^[transformR90"
    end
    local minpos = {
        x = pos.x - r,
        y = pos.y - r,
        z = pos.z - r
    }
    local maxpos = {
        x = pos.x + r,
        y = pos.y + r,
        z = pos.z + r
    }
    count = math.min(40, count)
    local def = {
        amount = count,
        minpos = minpos,
        maxpos = maxpos,
        minvel = {
            x = dir.x - 0.1,
            y = dir.y - 0.0,
            z = dir.z - 0.1
        },
        maxvel = {
            x = dir.x * 1,
            y = 0.1 + dir.y * 1,
            z = dir.z * 1
        },
        minacc = {
            x = -dir.x * 0.275,
            y = -dir.y * 0.275 + randFloat(-0.25, -0.125) * grav,
            z = -dir.z * 0.275
        },
        maxacc = {
            x = dir.x * 0.275,
            y = dir.y * randFloat(-0.001, -0.01) * grav,
            z = dir.z * 0.275
        },
        time = t * 0.647,
        minexptime = t - 0.25,
        maxexptime = t + 1,
        minsize = randFloat(1.02, 1.42) * ((size + 0.5) / 2),
        maxsize = randFloat(1.05, 1.44) * ((size + 0.81) / 2),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = texture,
            alpha = 1,
            alpha_tween = {1, 0.08},
            scale_tween = {{
                x = 1.0,
                y = 1.0
            }, {
                x = 2.0,
                y = 2.0
            }},
            blend = "alpha"
        },
        glow = 11
    }
    core.add_particlespawner(def);
end

function va_structures.reclaim_effect_particles(pos, pow, dir, color)
    color = color or "#00ff00"
    dir = vector.multiply(dir, 0.5)
    local dist = pow * 0.075 or 0.75
    local size = 0.121
    local count = pow * 15
    local radius = 0.33
    reclaim_effect_particle(pos, "va_explosion_spark.png^[colorize:"..color..":alpha", dir, dist, size, count, radius)
end