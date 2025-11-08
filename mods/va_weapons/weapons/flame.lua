local handles = {}
va_weapons.register_weapon("flame", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local burn_duration = 3
        -- Fire the flame and deal damage over time
        local gain = 1.0
        local pitch = 1.0
        local player_name = shooter:get_player_name() or ""
        if handles[player_name] then
            core.sound_fade(handles[player_name], 1, 0)
            handles[player_name] = nil
        end
        core.after(0, function()
            core.sound_play("va_weapons_flame", {
                pos = shooter_pos,
                gain = gain,
                pitch = pitch,
            })
        end)
        return true
    end
})