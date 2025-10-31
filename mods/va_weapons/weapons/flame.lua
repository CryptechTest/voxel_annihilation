va_weapons.register_weapon("flame", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local burn_duration = 3
        -- Fire the flame and deal damage over time
        return true
    end
})