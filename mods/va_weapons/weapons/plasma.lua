local plasma = {
    physical = false,
    collide_with_objects = true,
    visual = "sprite",
    textures = {"va_weapons_plasma.png"},
    glow = 14,
    visual_size = { x = 0, y = 0 },
    _damage = 0,
    on_step = function(self, dtime)
        local lifetime = self._lifetime or 0
        lifetime = lifetime + dtime
        if lifetime > 10 then
            self.object:remove()
            return
        end
        self._lifetime = lifetime
        physics_api.update_physics(self.object)
        local pos = self.object:get_pos()
        if not pos then
            return
        end
        -- Check for collision with objects
        local objects = core.get_objects_inside_radius(pos, 1)
        for _, obj in ipairs(objects) do
            if obj ~= self.object and not obj:is_player() then
                -- more damage is lower pitch
                local sound_pitch = math.max(0.5, 1.25 - (self._damage / 100))
                core.sound_play("va_weapons_plasma", {
                    pos = pos,
                    gain = 0.15,
                    pitch = sound_pitch,
                })
                -- Handle collision (e.g., deal damage)

                self.object:remove()
                return
            end
        end
        --check for collision with nodes
        local next_pos = vector.add(pos, vector.multiply(self.object:get_velocity(), dtime))
        local node_pos = {
            x = math.floor(next_pos.x + 0.5),
            y = math.floor(next_pos.y + 0.5),
            z = math.floor(next_pos.z + 0.5)
        }
        local current_node_pos = {
            x = math.floor(pos.x + 0.5),
            y = math.floor(pos.y + 0.5),
            z = math.floor(pos.z + 0.5)
        }
        local node = core.get_node(node_pos)
        if node and core.registered_nodes[node.name] and core.registered_nodes[node.name].walkable and node.name ~= "barrier:barrier" then
            -- Handle collision (e.g., explode)
            local sound_pitch = math.max(0.5, 1.25 - (self._damage / 100))
            core.sound_play("va_weapons_plasma", {
                pos = pos,
                gain = 0.15,
                pitch = sound_pitch,
            })
            self.object:remove()
            return
        end
        if node_pos.x ~= current_node_pos.x or
           node_pos.y ~= current_node_pos.y or
           node_pos.z ~= current_node_pos.z then
            -- Moved to a new node, check for collision
            local n = core.get_node(node_pos)
            if n and core.registered_nodes[n.name] and core.registered_nodes[n.name].walkable and n.name ~= "barrier:barrier" then
                -- Handle collision (e.g., explode)
                local sound_pitch = math.max(0.5, 1.25 - (self._damage / 100))
                core.sound_play("va_weapons_plasma", {
                    pos = pos,
                    gain = 0.15,
                    pitch = sound_pitch,
                })
                self.object:remove()
                return
            end
        end
    end,
}
core.register_entity("va_weapons:plasma", plasma)

va_weapons.register_weapon("plasma", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local splash_radius = 3
        local splash_damage = base_damage * 0.3
        local gain = 1.0
        -- deeper pitch for higher damage
        local sound_pitch = math.max(1.0, 2.5 - (base_damage / 100))
        core.after(0, function()
            core.sound_play("va_weapons_plasma", {
                pos = shooter_pos,
                gain = gain,
                pitch = sound_pitch,
            })
            -- Create the plasma entity
            local plasma_entity = core.add_entity(shooter_pos, "va_weapons:plasma")
            if plasma_entity then
                plasma_entity:get_luaentity()._damage = base_damage
                local dir = vector.direction(shooter_pos, target_pos)
                local yaw = core.dir_to_yaw(dir)
                local entity_pitch = math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z)) - math.pi/2
                plasma_entity:set_velocity(vector.multiply(dir, 20))
                plasma_entity:set_rotation({x = entity_pitch, y = yaw, z = 0})
                local size = math.min(1.5, (base_damage / 100))
                plasma_entity:set_properties({ visual_size = { x = size, y = size }, collisionbox = { -size/3, -size/3, -size/3, size/3, size/3, size/3 } })
                local attached = plasma_entity:get_luaentity().object or plasma_entity
                -- DEBUG: spawn particles at shooter's position to verify spawner works
                core.add_particlespawner({
                    amount = 300,
                    time = 10,
                    attached = attached,
                    minvel = {x=-size, y=-size, z=-size},
                    maxvel = {x=size, y=size, z=size},
                    minacc = {x=0, y=0, z=0},
                    maxacc = {x=0, y=0, z=0},
                    minexptime = 0.5,
                    maxexptime = 1.0,
                    minsize = 0.1,
                    maxsize = 0.5,
                    texture = { name = "va_weapons_plasma_particle.png", alpha_tween = { 1, 0 } },
                    glow = 14,
                })
            end
        end)
        -- Fire the plasma cannon and deal damage
        return true
    end
})