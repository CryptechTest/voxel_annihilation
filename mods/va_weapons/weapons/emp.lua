va_weapons.register_weapon("emp", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = 0 -- EMP does not deal direct damage
        local emp_radius = 5
        local emp_duration = 5 * base_damage
        -- Fire the EMP and disable electronics in the area
        return true
    end
})