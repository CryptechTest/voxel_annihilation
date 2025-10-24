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

local function build_effect_particles(pos)
    local dir = {
        x = 0,
        y = 1,
        z = 0
    }
    local dist = 1.5
    local size = 2
    local count = 60
    local radius = 0.75
    build_effect_particle(pos, "va_structure_energy_particle.png", dir, dist, size, count, radius, false)
end

local function build_effect_particles_halt(pos)
    local dir = {
        x = 0,
        y = 1,
        z = 0
    }
    local dist = 1.5
    local size = 2
    local count = 20
    local radius = 0.5
    build_effect_particle(pos, "va_structure_energy_particle_halt.png", dir, dist, size, count, radius, false)
end

va_structures.particle_build_effect = build_effect_particles
va_structures.particle_build_effect_halt = build_effect_particles_halt
