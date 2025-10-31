local function fire_light_laser(shooter, shooter_pos, target_pos, range, base_damage)
    local distance = vector.distance(shooter_pos, target_pos)
    if distance > range then
        return false
    end
    local damage = base_damage * (1 - (distance / range))
    -- Fire the laser and deal damage
    return true
end

local function fire_heavy_laser(shooter, shooter_pos, target_pos, base_damage)
    local distance = vector.distance(shooter_pos, target_pos)
    local damage = base_damage
    -- Fire the laser and deal damage
    return true
end

va_weapons.register_weapon("light_laser", {
   fire = fire_light_laser
})

va_weapons.register_weapon("heavy_laser", {
    fire = fire_heavy_laser
})