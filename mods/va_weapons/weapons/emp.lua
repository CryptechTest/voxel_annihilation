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
        core.after(0, function()
            core.sound_play("va_weapons_explosion", {
                pos = shooter_pos,
                gain = 1.0,
                pitch = 1.2,
            })
        end)
        return true
    end
})