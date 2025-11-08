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
    on_step = function(self, dtime)
        local lifetime = self._lifetime or 0
        lifetime = lifetime + dtime
        if lifetime >= 0.75 then
            self.object:remove()
            return
        end
        self._lifetime = lifetime
        core.chat_send_all(tostring(lifetime))
    end,
}
core.register_entity("va_weapons:light_laser", light_laser)

local function fire_light_laser(shooter, shooter_pos, target_pos, range, base_damage)
    local distance = vector.distance(shooter_pos, target_pos)
    if distance > range then
        return false
    end
    local damage = base_damage * (1 - (distance / range))
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
            laser:set_velocity(vector.multiply(dir, 40))
            laser:set_rotation({x = entity_pitch, y = yaw, z = 0})
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
        end
    end)
    return true
end

va_weapons.register_weapon("light_laser", {
    fire = fire_light_laser
})

va_weapons.register_weapon("heavy_laser", {
    fire = fire_heavy_laser
})
