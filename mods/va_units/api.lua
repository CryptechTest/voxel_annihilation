va_units = {}

function va_units.spawn_unit(name, pos, yaw)
    local unit = core.add_entity(pos, name)
    if unit then
        unit:setyaw(yaw)
    end
    return unit
end