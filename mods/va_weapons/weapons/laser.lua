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
    on_activate = function(self, staticdata, dtime_s)
        self._start_pos = self.object:get_pos()
    end,
    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        if not self._start_pos then
            self._start_pos = pos
        end
        if not pos then
            self.object:remove()
            return
        end
        local traveled_distance = vector.distance(self._start_pos, pos)
        if traveled_distance >= self._range then
            self.object:remove()
            return
        end
        -- check for collision with objects
        local objects = core.get_objects_inside_radius(pos, 0.4)
        for _, obj in ipairs(objects) do
            if obj ~= self.object and not obj:is_player() then
                local ent = obj:get_luaentity()
                local is_laser = false
                if ent and ent.name then
                    if ent.name == "va_weapons:light_laser" or ent.name == "va_weapons:heavy_laser" then
                        is_laser = true
                    end
                end
                if not is_laser then
                    local falloff = math.max(0, 1 - (traveled_distance / self._range)^2)
                    local damage = math.max(1, math.floor(self._damage * falloff))
                    -- Deal damage to the object
                    obj:punch(self.object, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = { laser = damage }
                    }, nil)
                    self.object:remove()
                    return
                end
            end
        end
        --check for collision with nodes
        local node = core.get_node(pos)
        local def = node and core.registered_nodes[node.name]
        if def and def.walkable  and node.name ~= "barrier:barrier" then
            self.object:remove()
            return
        end
    end,
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
    on_step = function(self, dtime)
        local lifetime = self._lifetime or 0
        lifetime = lifetime + dtime
        if lifetime >= 1.0 then
            self.object:remove()
            return
        end
        self._lifetime = lifetime
    end,
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
