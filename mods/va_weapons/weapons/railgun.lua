va_weapons.register_weapon("railgun", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        -- Fire the railgun and deal damage
        local gain = 1.0
        local pitch = 0.8
        core.after(0, function()
            core.sound_play("va_weapons_railgun", {
                pos = shooter_pos,
                gain = gain,
                pitch = pitch,
            })
        end)
        return true
    end
})