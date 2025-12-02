local dirs = {{ -- along x beside
    x = 1,
    y = 0,
    z = 0
}, {
    x = -1,
    y = 0,
    z = 0
}, { -- along z beside
    x = 0,
    y = 0,
    z = 1
}, {
    x = 0,
    y = 0,
    z = -1
}, { -- nodes on y
    x = 0,
    y = 1,
    z = 0
}, {
    x = 0,
    y = -1,
    z = 0
}, { -- self
    x = 0,
    y = 0,
    z = 0
}}

local function set_fire(hit_pos)
    for _, dir in pairs(dirs) do
        local pos = vector.add(hit_pos, dir)
        local node = core.get_node(pos).name
        local nodedef = core.registered_nodes[node]
        if nodedef then
            if nodedef.on_ignite then
                nodedef.on_ignite(pos, nil)
            elseif (core.get_item_group(node, "flammable") >= 1)
                and core.get_node(vector.add(pos, vector.new(0,1,0))).name == "air" then
                core.set_node(vector.add(pos, vector.new(0,1,0)), { name = "fire:basic_flame" })
            end
        end
    end
end

local function destroy_effect_particle(pos, radius)
    for x = -radius, radius do
        for y = -radius, radius do
            for z = -radius, radius do
                local dist = math.sqrt(x * x + y * y + z * z)
                if dist <= radius then
                    local light_pos = vector.round(vector.add(pos, { x = x, y = y, z = z }))
                    local n = core.get_node(light_pos)
                    local light_level = math.random(4, 8)
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
        expirationtime = 0.72,
        size = radius * 4,
        collisiondetection = false,
        vertical = false,
        texture ={ name = "va_weapons_explosion_boom_1.png", alpha_tween = { 1, 0.5 } },
        glow = 15
    })
    core.add_particle({
        pos = vector.add(pos, {x=0, y=0.1, z=0}),
        velocity = vector.new(),
        acceleration = vector.new(),
        expirationtime = 0.64,
        size = radius * 8,
        collisiondetection = false,
        vertical = false,
        texture ={ name = "va_weapons_explosion_boom_2.png", alpha_tween = { 1, 0.25 } },
        glow = 15
    })
    core.add_particlespawner({
        amount = 8,
        time = 0.3,
        minpos = vector.subtract(pos, radius / 4),
        maxpos = vector.add(pos, radius / 4),
        minvel = {
            x = -0.75,
            y = -0.5,
            z = -0.75
        },
        maxvel = {
            x = 0.75,
            y = 1,
            z = 0.75
        },
        minacc = vector.new(0, -0.5, 0),
        maxacc = vector.new(0, -0.2, 0),
        minexptime = 3,
        maxexptime = 4,
        minsize = radius * 4,
        maxsize = radius * 6,
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
        amount = 8,
        time = 0.25,
        minpos = vector.subtract(pos, radius / 4),
        maxpos = vector.add(pos, radius / 4),
        minvel = {
            x = -0.45,
            y = -0.5,
            z = -0.45
        },
        maxvel = {
            x = 0.45,
            y = 1.0,
            z = 0.45
        },
        minacc = vector.new(0, -0.5, 0),
        maxacc = vector.new(0, -0.2, 0),
        minexptime = 2,
        maxexptime = 3,
        minsize = radius * 2,
        maxsize = radius * 3,
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
        amount = 57,
        time = 0.1,
        minpos = vector.subtract(pos, radius / 5),
        maxpos = vector.add(pos, radius / 5),
        minvel = {
            x = -1.25,
            y = 0.25,
            z = -1.25
        },
        maxvel = {
            x = 1.25,
            y = 3.51,
            z = 1.25
        },
        minacc = {
            x = -0.75,
            y = -3.25,
            z = -0.75
        },
        maxacc = {
            x = 0.75,
            y = -1.75,
            z = 0.75
        },
        minexptime = 0.6,
        maxexptime = 1.27,
        minsize = radius * 0.67,
        maxsize = radius * 0.95,
        texture = {
            name = "va_weapons_explosion_spark.png",
            blend = "alpha",
            scale = 1,
            alpha = 1.0,
            alpha_tween = { 1, 0.25 },
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

local function calc_damage(damage_base, dist, max_range)
    -- calculate damage and falloff
    local falloff = math.max(0, 1 - (dist / max_range)^2)
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
                        damage_groups = { plasma = damage }
                    }, nil)
                end
            end
        end
    end
end

local function do_plasma_hit_effects(pos, damage)
    -- show hit effect
    destroy_effect_particle(pos, 1)
    -- more damage is lower pitch
    local sound_pitch = math.max(0.5, 1.25 - (damage / 100))
    -- play hit sound
    core.sound_play("va_weapons_plasma", {
        pos = pos,
        gain = 0.15,
        pitch = sound_pitch,
    })
end

-- Handle collision (e.g., explode)
local function do_plasma_hit(pos, node_pos, damager)
    local damage = damager._damage
    -- damage near objects
    damage_near(pos, damage, 1.5, damager)
    -- do hit effect
    do_plasma_hit_effects(pos, damage)
    -- spawn fire
    set_fire(node_pos)
end

local plasma = {
    initial_properties = {
        physical = false,
        collide_with_objects = true,
        visual = "sprite",
        textures = {"va_weapons_plasma.png"},
        glow = 14,
        visual_size = { x = 0, y = 0 },
    },
    _damage = 0,
    _is_va_weapon = true,
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
        -- unit only hit check
        local collides_unit, colliding_unit = va_units.check_collision(next_pos)
        if collides_unit and colliding_unit then
            -- Deal damage to the object/
            colliding_unit:punch(self.object, 1.0, {
                full_punch_interval = 1.0,
                damage_groups = { plasma = self._damage }
            }, nil)
            do_plasma_hit_effects(pos, self._damage)
            self.object:remove()
            return
        end
        -- structure only hit check...
        local collides_structure, colliding_structure = va_structures.check_collision(next_pos)
        if collides_structure and colliding_structure then
            -- Deal damage to the object/
            colliding_structure:punch(self.object, 1.0, {
                full_punch_interval = 1.0,
                damage_groups = { plasma = self._damage }
            }, nil)
            do_plasma_hit_effects(pos, self._damage)
            self.object:remove()
            return
        end
        -- check node hit
        local node = core.get_node(node_pos)
        if node and core.registered_nodes[node.name] and core.registered_nodes[node.name].walkable and node.name ~= "barrier:barrier" then
            do_plasma_hit(pos, node_pos, self)
            self.object:remove()
            return
        end
        if node_pos.x ~= current_node_pos.x or
           node_pos.y ~= current_node_pos.y or
           node_pos.z ~= current_node_pos.z then
            -- Moved to a new node, check for collision
            local n = core.get_node(current_node_pos)
            if n and core.registered_nodes[n.name] and core.registered_nodes[n.name].walkable and n.name ~= "barrier:barrier" then
                do_plasma_hit(pos, node_pos, self)
                self.object:remove()
                return
            end
        end
        -- spawn light effect
        local light_pos = vector.round(pos)
        local n = core.get_node(light_pos)
        local light_level = math.random(4, 8)
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
core.register_entity("va_weapons:plasma", plasma)

va_weapons.register_weapon("plasma", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage, launch_vector)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local splash_radius = math.max(1, math.floor(base_damage / 2))
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
                if launch_vector == nil then
                    local dir = vector.direction(shooter_pos, target_pos)
                    local yaw = core.dir_to_yaw(dir)
                    local entity_pitch = math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z)) - math.pi/2
                    plasma_entity:set_velocity(vector.multiply(dir, 20))
                    plasma_entity:set_rotation({x = entity_pitch, y = yaw, z = 0})
                else
                    plasma_entity:set_velocity(launch_vector.velocity)
                    --plasma_entity:set_rotation({x = launch_vector.pitch, y = launch_vector.yaw, z = 0})
                end
                local size = math.max(0.05, math.min(0.667, 0.05 + (base_damage / 100) * (0.667 - 0.05)))
                --core.chat_send_all("base_damage: " .. tostring(base_damage) .. " size:" .. tostring(size))
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