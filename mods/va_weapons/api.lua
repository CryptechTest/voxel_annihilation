va_weapons = {}

function va_weapons.register_weapon(name, def)
    if not name or not def then
        return
    end
    va_weapons[name] = def
    core.register_craftitem("va_weapons:" .. name, {
        description = def.description or ("Weapon: " .. name),
        inventory_image = def.inventory_image or "va_weapons_default.png",
        range = def.range or 16,
        on_use = function(itemstack, user, pointed_thing)
            if def.fire then
                local shooter = user
                local dir = shooter:get_look_dir()
                -- put the shooter pos a bit in front of the shooter to avoid self-collision
                local shooter_pos = shooter:get_pos()
                if shooter_pos and dir and (dir.x ~= 0 or dir.y ~= 0 or dir.z ~= 0) then
                    -- If not aiming steeply down, add upward offset
                    if dir.y > -0.7 then
                        shooter_pos = vector.add(shooter_pos, {x=0, y=1.5, z=0})
                    end
                    shooter_pos = vector.add(shooter_pos, vector.multiply(dir, 1.1))
                end
                local range = def.range or 16
                local base_damage = def.base_damage or 20
                local d = shooter:get_look_dir()
                local target_pos = vector.add(shooter_pos, vector.multiply(d, range - 0.5))
                def.fire(shooter, shooter_pos, target_pos, range, base_damage)
            end
        end
    })
end

function va_weapons.get_weapon(name)
    return va_weapons[name]
end
