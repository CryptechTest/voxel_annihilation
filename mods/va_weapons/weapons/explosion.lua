va_weapons.register_weapon("explosion", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if shooter_pos.x ~= target_pos.x or shooter_pos.y ~= target_pos.y or shooter_pos.z ~= target_pos.z then
            return false
        end
        local damage = base_damage
        local splash_radius = range
        local splash_damage = base_damage * 0.5
        -- Create the explosion and deal damage
        return true
    end
})