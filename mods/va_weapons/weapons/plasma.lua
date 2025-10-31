va_weapons.register_weapon("plasma", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local splash_radius = 3
        local splash_damage = base_damage * 0.3
        -- Fire the plasma cannon and deal damage
        return true
    end
})