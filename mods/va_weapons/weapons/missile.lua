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
        return true
    end
})

