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
        on_step = function(self, dtime)
            local lifetime = self._lifetime or 0
            lifetime = lifetime + dtime
            if lifetime >= 0.3 then
                self.object:remove()
                return
            end
            self._lifetime = lifetime
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
        range = math.min(range, 4)
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
            for i = 1, 10 do
                local lightning_variant = math.random(1, 3)
                core.after(i * 0.1,
                    function()
                        -- redefine the shooter_pos to be in front of the shooter each time
                        local dir = vector.direction(shooter_pos, target_pos)
                        local offset = 1.0
                        shooter_pos = vector.add(shooter_pos, vector.multiply(dir, offset))
                        local lightning_entity = core.add_entity(shooter_pos,
                            "va_weapons:lightning_" .. lightning_variant)
                        if lightning_entity then
                            local dir = vector.direction(shooter_pos, target_pos)
                            local yaw = core.dir_to_yaw(dir)
                            local entity_pitch = math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z)) - math.pi /
                                2
                            -- get the length of the distance to target to set the visual size
                            local dist_to_target = vector.distance(shooter_pos, target_pos)
                            lightning_entity:set_properties({ visual_size = { x = (dist_to_target * 0.667) / 8, y = (dist_to_target * 0.667) / 16, z = 0.1 } })
                            local roll_index = math.random(0, 3)
                            local roll_angle = roll_index * (math.pi / 2)
                            -- Swap x and z for correct visual orientation
                            -- Debug: Try all axis combinations for rotation
                            local combos = {
                                { x = entity_pitch, y = yaw, z = roll_angle },
                                { x = roll_angle,   y = yaw, z = entity_pitch },
                            }
                            -- Pick one to test per spawn, or cycle through them
                            local combo_index = i     -- i from 1 to 3 in the loop
                            local rot = combos[combo_index] or combos[1]
                            lightning_entity:set_rotation(rot)
                        end
                    end
                )
            end
        end)
        return true
    end
})
