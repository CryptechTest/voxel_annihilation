local animations = {
    -- Standard animations.
    stand     = {x = 1.08,   y = 1.08},
    walk      = {x = 0,  y = 1}
}

va_units.register_unit("vox_anti_swarm", {
    mesh = "va_units_vox_anti_swarm.gltf",
    texture ="va_units_vox_anti_swarm.png",
    visual_size = { x = 1, y = 1},
    collisionbox = {-0.7, 0.01, -0.85, 0.7, 2.1, 0.85},
    selectionbox = { -0.7, 0.0, -0.85, 0.7, 1.95, 0.85 },
    driver_eye_offset = { x = 0, y = 10, z = -16 },
    stepheight = 1.0,
    hp_max = 10,
    nametag = "VASB-1",
    animations = animations,
    animation_speed = 1.0,
    movement_speed = 0.8,
    spawn_item_description = "VASB-1 Unit Spawn",
    item_inventory_image = "va_units_blueprint.png",
})