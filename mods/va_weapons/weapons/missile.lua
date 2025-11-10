core.register_node("va_weapons:missile_ammo", {
    description = "Missile",
    group = { not_in_creative_inventory = 1 },
    drawtype = "plantlike",
    tiles = { "va_weapons_missile.png" },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    is_ground_content = false,
})

local missile = {
    initial_properties = {
        physical = false,
        collide_with_objects = true,
        visual = "wielditem",
        pointable = false,
        wield_item = "va_weapons:missile_ammo",
        glow = 3,
        visual_size = { x = 0.5, y = 0.5, z = 0.5 }
    },
    _start_pos = nil,
    _range = 16,
    on_step = function(self, dtime)
        local lifetime = self._lifetime or 0
        lifetime = lifetime + dtime
        if lifetime >= 10 then
            self.object:remove()
            return
        end
        self._lifetime = lifetime
        local pos = self.object:get_pos()
        if not pos then
            return
        end
        if not self._start_pos then
            self._start_pos = pos
        end
        if vector.distance(self._start_pos, pos) >= self._range then
            physics_api.update_physics(self.object)
            --rotate to face movement direction
            local vel = self.object:get_velocity()
            local yaw = core.dir_to_yaw(vel)
            local entity_pitch = math.atan2(vel.y, math.sqrt(vel.x * vel.x + vel.z * vel.z)) - math.pi / 2
            self.object:set_rotation({ x = entity_pitch, y = yaw, z = 0 })
        end
    end,
}

core.register_entity("va_weapons:missile", missile)

va_weapons.register_weapon("missile", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local splash_radius = 2
        local splash_damage = base_damage * 0.4
        -- Fire the missile and deal damage
        core.after(0, function()
            core.sound_play("va_weapons_missile", {
                pos = shooter_pos,
                gain = 1.0,
                pitch = 1.0,
            })
            -- Create the missile entity
            local missile_entity = core.add_entity(shooter_pos, "va_weapons:missile")
            if missile_entity then
                local dir = vector.direction(shooter_pos, target_pos)
                local yaw = core.dir_to_yaw(dir)
                local entity_pitch = math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z)) - math.pi / 2
                missile_entity:set_velocity(vector.multiply(dir, 15))
                missile_entity:set_rotation({ x = entity_pitch, y = yaw, z = 0 })
                local luaent = missile_entity:get_luaentity()
                if luaent then
                    luaent._range = range
                end
            end
            local attached = missile_entity:get_luaentity().object or missile_entity
            core.add_particlespawner({
                amount = 2700,
                time = 30,
                attached = attached,
                minvel = { x = -0.1, y = -0.1, z = -0.1 },
                maxvel = { x = 0.1, y = 0.1, z = 0.1 },
                minacc = { x = 0, y = 0, z = 0 },
                maxacc = { x = 0, y = 0, z = 0 },
                minexptime = 2.0,
                maxexptime = 2.0,
                minsize = 1.0,
                maxsize = 5.0,
                texture = { name = "va_weapons_missile_particle.png", alpha_tween = { 1, 0 } },
                glow = 4,
                drag = { x = 0.9, y = 0.9, z = 0.9 },
            })
            core.add_particlespawner({
                amount = 150,
                time = 30,
                attached = attached,
                minvel = { x = -0.1, y = -0.1, z = -0.1 },
                maxvel = { x = 0.1, y = 0.1, z = 0.1 },
                minacc = { x = 0, y = 0, z = 0 },
                maxacc = { x = 0, y = 0, z = 0 },
                minexptime = 0.5,
                maxexptime = 1.0,
                minsize = 0.05,
                maxsize = 0.5,
                texture = "va_weapons_plasma_particle.png",
                glow = 14,
            })
        end)
        return true
    end
})

va_weapons.register_weapon("guided_missile", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local splash_radius = 2
        local splash_damage = base_damage * 0.4
        -- Fire the guided missile and deal damage
        core.after(0, function()
            core.sound_play("va_weapons_missile", {
                pos = shooter_pos,
                gain = 1.0,
                pitch = 1.0,
            })
        end)
        return true
    end
})
