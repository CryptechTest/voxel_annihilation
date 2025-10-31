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
    build_effect_particle(pos, "va_structure_energy_particle.png", dir, dist, size, count, radius, false)
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
    build_effect_particle(pos, "va_structure_energy_particle_halt.png", dir, dist, size, count, radius, false)
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
    build_effect_particle(pos, "va_structure_energy_particle_halt.png^[colorize:#FF0000:200", dir, dist, size, count,
        radius, false)
end

va_structures.particle_build_effect = build_effect_particles
va_structures.particle_build_effect_halt = build_effect_particles_halt
va_structures.particle_build_effect_cancel = build_effect_particles_cancel

-----------------------------------------------------------------

local function spawn_build_effect_particle(pos, texture, _dir, dist, size, count, radius)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    local _vel = vector.multiply(_dir, {
        x = 2.0,
        y = 2.0,
        z = 2.0
    })
    local vel = vector.multiply(_vel, size)
    local t = 1.5 + (dist * 0.1) - randFloat(0.2, 0.4)
    local texture = texture
    if math.random(0, 1) == 0 then
        texture = texture .. "^[transformR90"
    end
    local r = radius
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
            x = -vel.x * 0.15,
            y = randFloat(-0.02, -0.01) * grav,
            z = -vel.z * 0.15
        },
        maxacc = {
            x = vel.x * 0.15,
            y = randFloat(0.01, 0.02) * grav,
            z = vel.z * 0.15
        },
        time = t * 0.5,
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
                x = 1.0,
                y = 1.0
            }, {
                x = 1.5,
                y = 1.5
            }},
            blend = "alpha"
        },
        glow = 13
    }

    core.add_particlespawner(def);
end

local function spawn_particle(pos, dir, i, dist)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    dir = vector.multiply(dir, {
        x = 1.05,
        y = 1.05,
        z = 1.05
    })
    local i = (dist - (dist - i * 0.1)) * 0.064
    local t = 0.6 + i
    local def = {
        pos = pos,
        velocity = {
            x = dir.x,
            y = dir.y,
            z = dir.z
        },
        acceleration = {
            x = 0,
            y = randFloat(-0.02, 0.05) * grav,
            z = 0
        },

        expirationtime = t,
        size = randFloat(1.32, 1.6),
        collisiondetection = false,
        collision_removal = false,
        object_collision = false,
        vertical = false,

        texture = {
            name = "va_structure_energy_particle.png",
            alpha = 1.0,
            alpha_tween = {1, 0},
            scale_tween = {{
                x = 0.5,
                y = 0.5
            }, {
                x = 1.3,
                y = 1.3
            }},
            blend = "alpha"
        },
        glow = 12
    }

    minetest.add_particle(def);
end

local function beam_effect(pos1, pos2, min, count)
    local dir = vector.direction(pos1, pos2)
    local step_min = 0.5
    local step = vector.multiply(dir, {
        x = step_min,
        y = step_min,
        z = step_min
    })
    local min = min or 5

    minetest.after(0, function()
        local i = 1
        local cur_pos = vector.add(pos1, vector.multiply(dir, {
            x = 0.2,
            y = 0.2,
            z = 0.2
        }))
        while (vector.distance(cur_pos, pos2) > step_min * min) do
            if true then
                -- spawn_particle(cur_pos, dir, i, vector.distance(cur_pos, pos2))
                local dist = vector.distance(cur_pos, pos2)
                local size = 0.2
                local dist2 = vector.distance(cur_pos, pos1)
                local r = 0.025 * dist2
                spawn_build_effect_particle(cur_pos, "va_structure_energy_particle.png", dir, dist, size, count, r)
            end
            cur_pos = vector.add(cur_pos, step)
            i = i + 1
            if i > 256 then
                break
            end
        end
    end)

    return true
end

local function particle_build_effects(target, source, min, count)

    --beam_effect(source, target, min, count)
    va_structures.show_build_beam_effect(source, target, min, count)

end

va_structures.particle_build_effects = particle_build_effects


local function spawn_build_beam_particles(pos, texture, _dir, dist, count)
    local grav = 1;
    if (pos.y > 4000) then
        grav = 0.4;
    end
    local count = count * 3
    if dist < 3 then
        count = count * 0.5
    end
    local size = 0.67
    local vel = vector.multiply(_dir, math.max(1.2, dist * 0.227))
    local t = 1.0 + math.min(dist * 0.333, 3.92)
    if dist <= 3 then
        t = t - 0.65
        vel = vector.multiply(vel, 0.9)
    elseif dist <= 5 then
        t = t + 0.5
    end
    if dist <= 8 then
        t = t + 0.45
        vel = vector.multiply(vel, 1.05)
    end
    if dist >= 13 then
        t = t - 0.55
    end
    local texture = texture
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


local function show_build_beam_effect(pos1, pos2, min, count)
    local dir = vector.direction(pos1, pos2)
    local step_min = 0.5
    local step = vector.multiply(dir, {
        x = step_min,
        y = step_min,
        z = step_min
    })
    local min = min or 5

    minetest.after(0, function()
        local i = 1
        local cur_pos = vector.add(pos1, vector.multiply(dir, {
            x = 0.2,
            y = 0.2,
            z = 0.2
        }))
        local dist = vector.distance(cur_pos, pos2)
        spawn_build_beam_particles(cur_pos, "va_structure_energy_particle.png", dir, dist, count)

        --[[while (vector.distance(cur_pos, pos2) > step_min * min) do
            if true then
                -- spawn_particle(cur_pos, dir, i, vector.distance(cur_pos, pos2))
                local dist = vector.distance(cur_pos, pos2)
                local size = 0.2
                local dist2 = vector.distance(cur_pos, pos1)
                local r = 0.025 * dist2
                spawn_build_effect_particle(cur_pos, "va_structure_energy_particle.png", dir, dist, size, count, r)
            end
            cur_pos = vector.add(cur_pos, step)
            i = i + 1
            if i > 256 then
                break
            end
        end]]
    end)

    return true
end

va_structures.show_build_beam_effect = show_build_beam_effect

-----------------------------------------------------------------

local function destroy_effect_particle(pos, radius)
    minetest.add_particle({
        pos = pos,
        velocity = vector.new(),
        acceleration = vector.new(),
        expirationtime = 0.64,
        size = radius * 16,
        collisiondetection = false,
        vertical = false,
        texture = "va_explosion_boom.png",
        glow = 15
    })
    minetest.add_particlespawner({
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
    minetest.add_particlespawner({
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
    minetest.add_particlespawner({
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