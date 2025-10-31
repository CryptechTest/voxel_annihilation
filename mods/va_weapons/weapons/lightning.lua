va_weapons.register_weapon("lightning", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local jump_distance = 2
        -- Fire the lightning and deal damage
        return true
    end
})