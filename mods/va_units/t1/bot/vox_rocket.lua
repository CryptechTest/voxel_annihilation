local animations = {
    -- Standard animations.
    stand     = {x = 1.08,   y = 1.08},
    walk      = {x = 0,  y = 1}
}

va_units.register_unit("vox_rocket", {
    mesh = "va_units_vox_rocket.gltf",
    texture ="va_units_vox_rocket.png",
    visual_size = { x = 1, y = 1},
    collisionbox = {-0.5, 0.01, -0.65, 0.5, 1.95, 0.75},
    selectionbox = { -0.5, 0.0, -0.65, 0.5, 1.8, 0.75 },
    driver_eye_offset = { x = 0, y = 10, z = -16 },
    stepheight = 1.0,
    hp_max = 72,
    nametag = "VRB-1",
    animations = animations,
    animation_speed = 1.5,
    movement_speed = 1.0,
    spawn_item_description = "VRB-1 Unit Spawn",
    item_inventory_image = "va_units_blueprint.png",
    mass_cost = 12,
    energy_cost = 100,
    build_time = 201
})