va_weapons.register_weapon("beam", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage -- no falloff for beam weapons
        -- Fire the beam and deal damage
        return true
    end
})

va_weapons.register_weapon("emp_beam", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = 0 -- EMP does not deal direct damage
        local emp_duration = 3 / base_damage
        -- Fire the EMP beam and deal damage
        return true
    end
})