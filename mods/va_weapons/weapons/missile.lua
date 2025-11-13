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

local function set_fire(pos)
    local node_under = core.get_node(pos).name
    local nodedef = core.registered_nodes[node_under]
    if not nodedef then
        return
    end
    if nodedef.on_ignite then
        nodedef.on_ignite(pos, nil)
    elseif core.get_item_group(node_under, "flammable") >= 1
        and core.get_node(vector.add(pos, { x = 0, y = 1, z = 0 })).name == "air" then
        core.set_node(vector.add(pos, { x = 0, y = 1, z = 0 }), { name = "fire:basic_flame" })
    end
end

local function destroy_effect_particle(pos, radius)
    -- itterate over the radius and create light node_pos
    for x = -radius, radius do
        for y = -radius, radius do
            for z = -radius, radius do
                local dist = math.sqrt(x * x + y * y + z * z)
                if dist <= radius then
                    local light_pos = vector.round(vector.add(pos, { x = x, y = y, z = z }))
                    local n = core.get_node(light_pos)
                    local light_level = math.random(8, 12)
                    if n and n.name == "air" or n.name == "va_weapons:dummy_light_" .. light_level then
                        core.set_node(light_pos, {name = "va_weapons:dummy_light_" .. light_level})
                        -- remove the light node after a short delay
                        core.after(0.2, function()
                            n = core.get_node(light_pos)
                            if n and n.name == "va_weapons:dummy_light_" .. light_level then
                                core.remove_node(light_pos)
                            end
                        end)
                    end                    
                end
            end
        end
    end
    core.add_particle({
        pos = pos,
        velocity = vector.new(),
        acceleration = vector.new(),
        expirationtime = 0.64,
        size = radius * 16,
        collisiondetection = false,
        vertical = false,
        texture = { name = "va_weapons_explosion_boom_2.png", alpha_tween = { 1, 0.25 } },
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
            name = "va_weapons_explosion_vapor.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = { 1, 0 },
            scale_tween = { {
                x = 0.5,
                y = 0.5
            }, {
                x = 5,
                y = 5
            } }
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
            name = "va_weapons_explosion_smoke.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = { 1, 0 },
            scale_tween = { {
                x = 0.25,
                y = 0.25
            }, {
                x = 6,
                y = 5
            } }
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
            name = "va_weapons_explosion_spark.png",
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
    _range = 12,
    _damage = 1,
    _splash_radius = 1,
    _splash_damage = 10,
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
            destroy_effect_particle(pos, self._splash_radius)
            local sound_pitch = 1.25
            core.sound_play("va_weapons_explosion", {
                pos = pos,
                gain = 0.15,
                pitch = sound_pitch,
            })
            local objects = core.get_objects_inside_radius(pos, self._splash_radius)
            local target_units = {}
            local target_structures = {}
            for _, obj in ipairs(objects) do
                if obj ~= self.object and not obj:is_player() then
                    -- check if it is a unit or structure to deal damage to
                    if obj:get_luaentity() and obj:get_luaentity()._is_va_unit then
                        table.insert(target_units, obj)
                    elseif obj:get_luaentity() and obj:get_luaentity()._is_va_structure then
                        table.insert(target_structures, obj)
                    end
                end
            end
            -- deal splash damage to target_units and target_structures here
            for _, unit in ipairs(target_units) do
                local upos = unit:get_pos()
                local distance = vector.distance(pos, upos)
                local damage = self._splash_damage * (1 - (distance / self._splash_radius))
                local id = unit:get_luaentity()._id
                if id ~= nil then
                    local target = va_units.get_unit_by_id(id)
                    if target and target.object then
                        target.object:punch(self.object, 1.0, {
                            full_punch_interval = 1.0,
                            damage_groups = { explosion = damage }
                        }, nil)
                    end
                end
            end
            for _, structure in ipairs(target_structures) do
                local spos = structure:get_pos()
                local distance = vector.distance(pos, spos)
                local damage = self._splash_damage * (1 - (distance / self._splash_radius))
                local id = structure:get_luaentity()._id
                if id then
                    local target = va_structures.get_active_structure(spos)
                    if target then
                        target:damage(damage, "explosion")
                    end
                end
            end
            set_fire(vector.add(current_node_pos, { x = 0, y = -1, z = 0 }))
            self.object:remove()
            return
        end
        if node_pos.x ~= current_node_pos.x or
            node_pos.y ~= current_node_pos.y or
            node_pos.z ~= current_node_pos.z then
            -- Moved to a new node, check for collision
            local n = core.get_node(current_node_pos)
            if n and core.registered_nodes[n.name] and core.registered_nodes[n.name].walkable and n.name ~= "barrier:barrier" then
                -- Handle collision (e.g., explode)
                destroy_effect_particle(pos, self._splash_radius)
                local sound_pitch = 1.25
                core.sound_play("va_weapons_explosion", {
                    pos = pos,
                    gain = 0.15,
                    pitch = sound_pitch,
                })
                local objects = core.get_objects_inside_radius(pos, self._splash_radius)
                local target_units = {}
                local target_structures = {}
                for _, obj in ipairs(objects) do
                    if obj ~= self.object and not obj:is_player() then
                        -- check if it is a unit or structure to deal damage to
                        if obj:get_luaentity() and obj:get_luaentity()._is_va_unit then
                            table.insert(target_units, obj)
                        elseif obj:get_luaentity() and obj:get_luaentity()._is_va_structure then
                            table.insert(target_structures, obj)
                        end
                    end
                end
                -- deal splash damage to target_units and target_structures here
                for _, unit in ipairs(target_units) do
                    local distance = vector.distance(pos, unit:get_pos())
                    local damage = self._splash_damage * (1 - (distance / self._splash_radius))
                    local id = unit:get_luaentity()._id
                    if id ~= nil then
                        local target = va_units.get_unit_by_id(id)
                        if target and target.object then
                            target.object:punch(self.object, 1.0, {
                                full_punch_interval = 1.0,
                                damage_groups = { explosion = damage }
                            }, nil)
                        end
                    end
                end
                for _, structure in ipairs(target_structures) do
                    local distance = vector.distance(pos, structure:get_pos())
                    local damage = self._splash_damage * (1 - (distance / self._splash_radius))
                    va_structures.get_active_structure_by_id(structure:get_luaentity()._id):damage(damage, "explosion")
                end
                set_fire(vector.add(current_node_pos, { x = 0, y = -1, z = 0 }))

                self.object:remove()
                return
            end
        end
        local light_pos = vector.round(pos)
        local n = core.get_node(light_pos)
        local light_level = math.random(1, 4)
        if n and n.name ~= "air" and n.name ~= "va_weapons:dummy_light_" .. light_level then
            return
        end
        core.set_node(light_pos, {name = "va_weapons:dummy_light_" .. light_level})
        -- remove the light node after a short delay
        core.after(0.1, function()
            n = core.get_node(light_pos)
            if n and n.name == "va_weapons:dummy_light_" .. light_level then
                core.remove_node(light_pos)
            end
        end)
    end,
}

core.register_entity("va_weapons:missile", missile)

va_weapons.register_weapon("missile", {
    base_damage = 80,
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
                    luaent._damage = damage
                    luaent._splash_radius = splash_radius
                    luaent._splash_damage = splash_damage
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
                amount = 5400,
                time = 30,
                attached = attached,
                minvel = { x = -0.1, y = -0.1, z = -0.1 },
                maxvel = { x = 0.1, y = 0.1, z = 0.1 },
                minacc = { x = 0, y = 0, z = 0 },
                maxacc = { x = 0, y = 0, z = 0 },
                minexptime = 0.25,
                maxexptime = 0.5,
                minsize = 0.05,
                maxsize = 0.5,
                texture = { name = "va_weapons_plasma_particle.png", alpha_tween = { 1, 0 } },
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
