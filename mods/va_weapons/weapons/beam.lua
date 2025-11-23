core.register_craftitem("va_weapons:beam_ammo", {
    description = "Beam Weapon Ammo",
    inventory_image = "va_weapons_beam.png",
    group = {
        not_in_creative_inventory = 1
    }
})

local function hit_effect_particle_beam(pos, dir, radius)
    core.add_particle({
        pos = pos,
        velocity = vector.new(),
        acceleration = vector.new(),
        expirationtime = 0.30,
        size = radius * 8,
        collisiondetection = false,
        vertical = false,
        texture = {
            name = "va_weapons_light_laser_hit.png^[colorize:#0898ff:alpha",
            alpha_tween = {
                1,
                0.25,
                scale_tween = {{
                    x = 1.0,
                    y = 1.0
                }, {
                    x = 0,
                    y = 0
                }}
            }
        },
        glow = 15
    })
    core.add_particlespawner({
        amount = 42,
        time = 0.10,
        minpos = vector.subtract(pos, radius / 5),
        maxpos = vector.add(pos, radius / 5),
        minvel = {
            x = -0.5 * dir.x,
            y = 2.0 * dir.y,
            z = -0.5 * dir.z
        },
        maxvel = {
            x = 2.0 * dir.x,
            y = 3.0 * dir.y,
            z = 2.0 * dir.z
        },
        minacc = {
            x = -0.20,
            y = -3.50,
            z = -0.20
        },
        maxacc = {
            x = 0.20,
            y = -3.0,
            z = 0.20
        },
        minexptime = 0.50,
        maxexptime = 1.75,
        minsize = radius * 0.88,
        maxsize = radius * 1.50,
        texture = {
            name = "va_weapons_explosion_spark.png^[colorize:#0898ff:alpha",
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

local function calc_damage(damage_base, dist, max_range)
    -- calculate damage and falloff
    local falloff = math.max(0, 1 - (dist / max_range) ^ 2)
    return math.max(0, math.floor(damage_base * falloff))
end

local function damage_near(hit_pos, damage_base, radius, damager)
    local objects = core.get_objects_inside_radius(hit_pos, radius * 2)
    for _, obj in ipairs(objects) do
        local pos = obj:get_pos()
        local distance = vector.distance(hit_pos, pos)
        if obj ~= damager.object and not obj:is_player() then
            local ent = obj:get_luaentity()
            if ent._is_va_weapon then
                -- ignore other weapon entity
            elseif ent._is_va_structure then
                local s = va_structures.get_active_structure(pos)
                if s and distance <= radius then
                    local damage = calc_damage(damage_base, distance, radius + 0.5)
                    if damage > 0 then
                        s:damage(damage, "plasma")
                    end
                end
            elseif ent._is_va_unit then
                local damage = calc_damage(damage_base, distance, radius)
                if damage > 0 and obj.punch then
                    obj:punch(damager.object, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = {
                            plasma = damage
                        }
                    }, nil)
                end
            end
        end
    end
end

local function on_step(self, dtime)
    local lifetime = self._lifetime or 0
    lifetime = lifetime + dtime
    if lifetime >= 3.0 then
        self.object:remove()
        return
    end
    self._time = self._time + 1
    if self._time >= 20 then
        self._time = 0
    end
    self._lifetime = lifetime
    local start_pos = self._start_pos
    local dir = self._dir
    if not start_pos or not dir then
        return
    end
    local max_length = self._range or 1.0
    local end_pos = vector.add(start_pos, vector.multiply(dir, max_length))
    local ray = core.raycast(start_pos, end_pos, true, true)
    local hit = false
    local hit_pos = nil
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            hit = true
            local distance = vector.distance(start_pos, pointed_thing.under)
            if not hit_pos or distance < vector.distance(start_pos, hit_pos) then
                hit_pos = pointed_thing.under
            end
        elseif pointed_thing.type == "object" then
            local entity = pointed_thing.ref
            if entity then
                if entity:get_luaentity() and entity:get_luaentity().name ~= "va_weapons:beam" then
                    hit = true
                    local distance = vector.distance(start_pos, pointed_thing.ref:get_pos())
                    if not hit_pos or distance < vector.distance(start_pos, hit_pos) then
                        hit_pos = pointed_thing.ref:get_pos()
                    end
                end
            end
        end
    end
    local new_length, mid_pos
    if hit and hit_pos then
        new_length = vector.distance(start_pos, hit_pos)
        mid_pos = vector.add(start_pos, vector.multiply(dir, new_length / 2))
    else
        new_length = max_length
        mid_pos = vector.add(start_pos, vector.multiply(dir, new_length / 2))
    end
    self.object:set_properties({
        visual_size = {
            x = 0.2,
            y = new_length * 0.52,
            z = 0.2
        }
    })
    self.object:set_pos(mid_pos)
    if hit and hit_pos and self._time == 1 then
        damage_near(hit_pos, self._damage * 0.333, 1.05, self)
        local _dir = vector.direction(hit_pos, start_pos)
        local e_pos = vector.add(hit_pos, {
            x = 0,
            y = dir.y + 0.15,
            z = 0
        })
        hit_effect_particle_beam(e_pos, _dir, 1)
    end
end

local beam = {
    initial_properties = {
        physical = false,
        collide_with_objects = true,
        visual = "wielditem",
        pointable = false,
        wield_item = "va_weapons:beam_ammo",
        glow = 14,
        visual_size = {
            x = 0.2,
            y = 1.0,
            z = 0.2
        }
    },
    _range = 64,
    _damage = 4,
    _time = 0,
    _start_pos = nil,
    _last_pos = nil,
    on_activate = function(self, staticdata, dtime_s)
        self._start_pos = self.object:get_pos()
    end,
    on_step = on_step
}

core.register_entity("va_weapons:beam", beam)

va_weapons.register_weapon("beam", {
    range = 32,
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        -- no damage falloff for beam weapons
        -- attach beam entity to shooter
        core.after(0, function()
            core.sound_play("va_weapons_beam", {
                pos = shooter_pos,
                gain = 1.0,
                pitch = 1.0
            })
            local beam_entity = core.add_entity(shooter_pos, "va_weapons:beam")
            if beam_entity then
                local dir = vector.direction(shooter_pos, target_pos)
                local yaw = core.dir_to_yaw(dir)
                local entity_pitch = math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z)) - math.pi / 2
                beam_entity:set_rotation({
                    x = entity_pitch,
                    y = yaw,
                    z = 0
                })
                local beam_length = math.min(distance, range)
                beam_entity:set_properties({
                    visual_size = {
                        x = 0.2,
                        y = beam_length * 0.5,
                        z = 0.2
                    }
                })
                local beam_pos = vector.add(shooter_pos, vector.multiply(dir, beam_length / 2))
                beam_entity:set_pos(beam_pos)
                local luaent = beam_entity:get_luaentity()
                if luaent then
                    luaent._range = range
                    luaent._damage = base_damage
                    luaent._dir = dir -- store original direction
                end
            end
        end)
        return true
    end
})

va_weapons.register_weapon("emp_beam", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = 0 -- EMP does not deal direct damage
        local emp_duration = 3 / base_damage
        -- Fire the EMP beam and deal damage
        core.after(0, function()
            core.sound_play("va_weapons_beam", {
                pos = shooter_pos,
                gain = 1.0,
                pitch = 1.0
            })
        end)
        return true
    end
})
