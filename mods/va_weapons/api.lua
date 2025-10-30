va_weapons = {}

function va_weapons.register_weapon(name, def)
    if not name or not def then
        return
    end
    va_weapons[name] = def
end

function va_weapons.get_weapon(name)
    return va_weapons[name]
end
