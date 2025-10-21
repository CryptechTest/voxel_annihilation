physics_api = {}


local base_gravity = -9.81

function physics_api.update_physics(object)
    local gravity = base_gravity
    local current_acceleration = object:get_acceleration()
    local new_acceleration = { x = current_acceleration.x, y = gravity, z = current_acceleration.z }
    object:set_acceleration(new_acceleration)
end

function physics_api.set_speed(player, speed)
    player:set_physics_override({
        speed = speed,
    })
end