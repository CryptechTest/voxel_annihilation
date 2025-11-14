core.register_craftitem("va_weapons:lightning_ammo_1", {
    description = "Lightning Weapon Ammo",
    inventory_image = "lightning_lightning_1.png^[transformFY",
    group = { not_in_creative_inventory = 1 },
})

core.register_craftitem("va_weapons:lightning_ammo_2", {
    description = "Lightning Weapon Ammo",
    inventory_image = "lightning_lightning_2.png^[transformFY",
    group = { not_in_creative_inventory = 1 },
})

core.register_craftitem("va_weapons:lightning_ammo_3", {
    description = "Lightning Weapon Ammo",
    inventory_image = "lightning_lightning_3.png^[transformFY",
    group = { not_in_creative_inventory = 1 },
})

for i = 1, 3 do
    local lightning = {
        initial_properties = {
            physical = false,
            collide_with_objects = true,
            visual = "wielditem",
            pointable = false,
            wield_item = "va_weapons:lightning_ammo_" .. i,
            glow = 14,
            visual_size = { x = 0.3, y = 1.5, z = 0.3 }
        },
        _is_va_weapon = true,
        on_step = function(self, dtime)
            local lifetime = self._lifetime or 0
            lifetime = lifetime + dtime
            if lifetime >= 0.2 then
                self.object:remove()
                return
            end
            self._lifetime = lifetime
            -- create light node at current position
            local pos = self.object:get_pos()
            if pos then
                local light_pos = vector.round(pos)
                local node = core.get_node(light_pos)
                local light_level = math.random(10, 14)
                if node and node.name ~= "air" and node.name ~= "va_weapons:dummy_light_" .. light_level then
                    return
                end
                core.set_node(light_pos, {name = "va_weapons:dummy_light_" .. light_level})
                -- remove the light node after a short delay
                core.after(0.1, function()
                    node = core.get_node(light_pos)
                    if node and node.name == "va_weapons:dummy_light_" .. light_level then
                        core.remove_node(light_pos)
                    end
                end)
            end
        end,
    }
    core.register_entity("va_weapons:lightning_" .. i, lightning)
end

va_weapons.register_weapon("lightning", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        range = math.min(range, 8)
        local damage = base_damage
        local jump_distance = 2
        -- Fire the lightning and deal damage
        local gain = 1.0
        local pitch = 1.2
        core.after(0, function()
            core.sound_play("va_weapons_lightning", {
                pos = shooter_pos,
                gain = gain,
                pitch = pitch,
            })
            -- Create the lightning entity, changing between 3 variants for visual variety
            for i = 1, 25 do
                local lightning_variant = math.random(1, 3)
                core.after(i * 0.04,
                    function()
                        -- redefine the shooter_pos to be in front of the shooter each time
                        local dir = vector.direction(shooter_pos, target_pos)
                        local offset = 1.0
                        shooter_pos = vector.add(shooter_pos, vector.multiply(dir, offset))
                        local lightning_entity = core.add_entity(shooter_pos,
                            "va_weapons:lightning_" .. lightning_variant)
                        if lightning_entity then
                            local d = vector.direction(shooter_pos, target_pos)
                            local entity_pitch = math.atan2(d.y, math.sqrt(d.x * d.x + d.z * d.z)) - math.pi /
                                2
                            -- get the length of the distance to target to set the visual size
                            local dist_to_target = vector.distance(shooter_pos, target_pos)
                            lightning_entity:set_properties({ visual_size = { x = (dist_to_target * 0.667) / 8, y = (dist_to_target * 0.667) / 16, z = 0.1 } })                            
                            local random_yaw = math.random() * math.pi * 2 -- random angle from 0 to 2π
                            lightning_entity:set_rotation({x = entity_pitch, y = random_yaw, z = -random_yaw})
                        end
                    end
                )
            end
        end)
        return true
    end
})
