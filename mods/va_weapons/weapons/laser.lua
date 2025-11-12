local function hit_effect_particle_light(pos, dir, radius)
    core.add_particle({
        pos = pos,
        velocity = vector.new(),
        acceleration = vector.new(),
        expirationtime = 0.30,
        size = radius * 8,
        collisiondetection = false,
        vertical = false,
        texture = { name = "va_light_laser_hit.png^[colorize:#ff0000:20", alpha_tween = { 1, 0.25 } },
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
            name = "va_explosion_spark.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = { 1, 0.5 },
            scale_tween = { {
                x = 1.0,
                y = 1.0
            }, {
                x = 0,
                y = 0
            } }
        },
        collisiondetection = true,
        glow = 15
    })
end

local function hit_effect_particle_heavy(pos, dir, radius)
    core.add_particle({
        pos = pos,
        velocity = vector.new(),
        acceleration = vector.new(),
        expirationtime = 0.425,
        size = radius * 8,
        collisiondetection = false,
        vertical = false,
        texture = { name = "va_heavy_laser_hit.png^[colorize:#00ff00:20", alpha_tween = { 1, 0.5 } },
        glow = 15
    })
    core.add_particlespawner({
        amount = 47,
        time = 0.10,
        minpos = vector.subtract(pos, radius / 5),
        maxpos = vector.add(pos, radius / 5),
        minvel = {
            x = -1.0 * dir.x,
            y = 2.5 * dir.y,
            z = -1.0 * dir.z
        },
        maxvel = {
            x = 3.0 * dir.x,
            y = 3.5 * dir.y,
            z = 3.0 * dir.z
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
        minexptime = 0.80,
        maxexptime = 2.00,
        minsize = radius * 0.88,
        maxsize = radius * 1.60,
        texture = {
            name = "va_explosion_spark.png^[colorize:#00ff00:alpha",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = { 1, 0.5 },
            scale_tween = { {
                x = 1.0,
                y = 1.0
            }, {
                x = 0,
                y = 0
            } }
        },
        collisiondetection = true,
        glow = 15
    })
end

--- on step tick for laser
---@param self any
---@param dtime any
local function on_step(self, dtime)
    if self._disposing then
        return
    end
    local pos = self.object:get_pos()
    if not self._start_pos then
        self._start_pos = pos
    end
    if not pos then
        self.object:remove()
        return
    end
    -- check travel distance and remove if over range
    local traveled_distance = vector.distance(self._start_pos, pos)
    if traveled_distance >= self._range then
        self._disposing = true
        self.object:remove()
        return
    end
    -- calculate damage and falloff
    local falloff = math.max(0, 1 - (traveled_distance / self._range)^2)
    local damage = math.max(1, math.floor(self._damage * falloff))
    -- check for collision with objects
    local objects = core.get_objects_inside_radius(pos, 0.4)
    local obj2 = core.get_objects_inside_radius(vector.subtract(pos, vector.new(0,0.8,0)), 0.4)
    for _, obj in ipairs(obj2) do
        table.insert(objects, obj)
    end
    local hit_obj = false
    for _, obj in ipairs(objects) do
        if obj ~= self.object and not obj:is_player() then
            local ent = obj:get_luaentity()
            local is_laser = false
            local is_missile = false
            if ent and ent.name then
                if ent.name == "va_weapons:light_laser" or ent.name == "va_weapons:heavy_laser" then
                    is_laser = true
                elseif ent.name == "va_weapons:missile" then
                    is_missile = true
                end
            end
            local is_valid_target = false
            -- check for valid target
            if ent._is_va_unit or is_missile then
                is_valid_target = true
            end
            if not is_laser and is_valid_target then
                -- Deal damage to the object
                obj:punch(self.object, 1.0, {
                    full_punch_interval = 1.0,
                    damage_groups = { laser = damage }
                }, nil)
                hit_obj = true
            end
        end
    end
    if not hit_obj then
        -- structure only check...
        local collides, colliding = va_structures.check_collision(pos)
        if collides and colliding then
            hit_obj = true
            -- Deal damage to the object
            colliding:punch(self.object, 1.0, {
                full_punch_interval = 1.0,
                damage_groups = { laser = damage }
            }, nil)
        end
    end
    --check for collision with nodes
    local node = core.get_node(pos)
    local def = node and core.registered_nodes[node.name]
    if def and def.walkable and node.name ~= "barrier:barrier" then
        hit_obj = true
    end
    -- hit effect
    if hit_obj and self._last_pos then
        -- use last pos for hit position effect so effect doesn't spawn inside object
        local hit_pos = vector.add(self._last_pos, vector.new(0,0.05,0))
        local hit_dir = vector.direction(pos, self._last_pos)
        if self.object:get_luaentity().name == "va_weapons:heavy_laser" then
            hit_effect_particle_heavy(hit_pos, hit_dir, 1.0)
        else
            hit_effect_particle_light(hit_pos, hit_dir, 0.5)
        end
    end
    -- remove on hit
    if hit_obj then
        self._disposing = true
        core.after(0, function()
            self.object:remove()
        end)
        return
    end
    -- update last position
    self._last_pos = self.object:get_pos()
end

-----------------------------------------------------------------

core.register_craftitem("va_weapons:light_laser_ammo", {
    description = "Laser Weapon Ammo",
    inventory_image = "va_weapons_light_laser.png",
    group = {not_in_creative_inventory=1},
})

local light_laser = {
    initial_properties = {
        physical = false,
        collide_with_objects = true,
        visual = "wielditem",
        pointable = false,
        wield_item = "va_weapons:light_laser_ammo",
        glow = 14,
        visual_size = { x = 0.2, y = 1.0, z = 0.2}
    },
    _range = 64,
    _damage = 4,
    _start_pos = nil,
    _last_pos = nil,
    on_activate = function(self, staticdata, dtime_s)
        self._start_pos = self.object:get_pos()
    end,
    on_step = on_step,
}
core.register_entity("va_weapons:light_laser", light_laser)

local function fire_light_laser(shooter, shooter_pos, target_pos, range, base_damage)
    local distance = vector.distance(shooter_pos, target_pos)
    if distance > range then
        return false
    end

    -- Fire the laser and deal damage
    local gain = 1.0
    local sound_pitch = 1.15

    core.after(0, function()
        core.sound_play("va_weapons_laser", {
            pos = shooter_pos,
            gain = gain,
            pitch = sound_pitch,
        })
        -- Create the laser entity
        local laser = core.add_entity(shooter_pos, "va_weapons:light_laser")
        if laser then
            local dir = vector.direction(shooter_pos, target_pos)
            local yaw = core.dir_to_yaw(dir)
            local entity_pitch = math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z)) - math.pi/2
            laser:set_velocity(vector.multiply(dir, 30))
            laser:set_rotation({x = entity_pitch, y = yaw, z = 0})
            local luaent = laser:get_luaentity()
            if luaent then
                luaent._range = range
                luaent._damage = base_damage
            end
        end
    end)
    return true
end

-----------------------------------------------------------------

core.register_craftitem("va_weapons:heavy_laser_ammo", {
    description = "Heavy Laser Weapon Ammo",
    inventory_image = "va_weapons_heavy_laser.png",
    group = {not_in_creative_inventory=1},
})

local heavy_laser = {
    initial_properties = {
        physical = false,
        collide_with_objects = true,
        visual = "wielditem",
        pointable = false,
        wield_item = "va_weapons:heavy_laser_ammo",
        glow = 14,
        visual_size = { x = 0.3, y = 1.5, z = 0.3}
    },
    _range = 64,
    _damage = 10,
    _start_pos = nil,
    _last_pos = nil,
    on_activate = function(self, staticdata, dtime_s)
        self._start_pos = self.object:get_pos()
    end,
    on_step = on_step,
}
core.register_entity("va_weapons:heavy_laser", heavy_laser)

local function fire_heavy_laser(shooter, shooter_pos, target_pos, range, base_damage)
    local distance = vector.distance(shooter_pos, target_pos)
    if distance > range then
        return false
    end
    local damage = base_damage -- no falloff
    -- Fire the laser and deal damage
    local gain = 1.0
    local pitch = 0.65
    core.after(0, function()
        core.sound_play("va_weapons_laser", {
            pos = shooter_pos,
            gain = gain,
            pitch = pitch,
        })
        -- Create the laser entity
        local laser = core.add_entity(shooter_pos, "va_weapons:heavy_laser")
        if laser then
            local dir = vector.direction(shooter_pos, target_pos)
            local yaw = core.dir_to_yaw(dir)
            local entity_pitch = math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z)) - math.pi/2
            laser:set_velocity(vector.multiply(dir, 40))
            laser:set_rotation({x = entity_pitch, y = yaw, z = 0})
            local luaent = laser:get_luaentity()
            if luaent then
                luaent._damage = damage
            end
        end
    end)
    return true
end

-----------------------------------------------------------------

va_weapons.register_weapon("light_laser", {
    fire = fire_light_laser,
    range = 16,
    base_damage = 4
})

va_weapons.register_weapon("heavy_laser", {
    fire = fire_heavy_laser,
    range = 64,
    base_damage = 16
})
