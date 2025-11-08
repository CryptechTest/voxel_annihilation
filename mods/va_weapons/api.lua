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
                local shooter_pos = vector.add(shooter:get_pos(), vector.new(0, 0.8, 0))
                local target_pos = nil
                local range = def.range or 16
                local base_damage = def.base_damage or 10
                if pointed_thing.type == "object" then
                    local entity = pointed_thing.ref
                    if entity then
                        target_pos = entity:get_pos()
                    end
                elseif pointed_thing.type == "node" then
                    target_pos = pointed_thing.under
                else
                    local dir = shooter:get_look_dir()
                    target_pos = vector.add(shooter_pos, vector.multiply(dir, range))
                end
                def.fire(shooter, shooter_pos, target_pos, range, base_damage)
            end
        end
    })
end

function va_weapons.get_weapon(name)
    return va_weapons[name]
end
