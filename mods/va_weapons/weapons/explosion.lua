va_weapons.register_weapon("explosion", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local splash_radius = range
        local splash_damage = base_damage * 0.5
        -- Create the explosion and deal damage
        local gain =  1.0
        local pitch = 1.0
        core.after(0, function()
            core.sound_play("va_weapons_explosion", {
                pos = shooter_pos,
                gain = gain,
                pitch = pitch,
            })
        end)
        return true
    end
})