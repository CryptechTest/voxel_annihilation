
local function fire_light_laser(shooter, shooter_pos, target_pos, range, base_damage)
    local distance = vector.distance(shooter_pos, target_pos)
    if distance > range then
        return false
    end
    local damage = base_damage * (1 - (distance / range))
    -- Fire the laser and deal damage
    local gain = 1.0
    local pitch = 1.15
    core.after(0, function()
        core.sound_play("va_weapons_laser", {
            pos = shooter_pos,
            gain = gain,
            pitch = pitch,
        })
    end)
    return true
end

local function fire_heavy_laser(shooter, shooter_pos, target_pos, range, base_damage)
    local distance = vector.distance(shooter_pos, target_pos)
    if distance > range then
        return false
    end
    local damage = base_damage -- no falloff
    -- Fire the laser and deal damage
    local gain = 1.0
    local pitch = 0.65
    core.after(0, function()
        core.sound_play("va_weapons_laser", {
            pos = shooter_pos,
            gain = gain,
            pitch = pitch,
        })
    end)
    return true
end

va_weapons.register_weapon("light_laser", {
    fire = fire_light_laser
})

va_weapons.register_weapon("heavy_laser", {
    fire = fire_heavy_laser
})
