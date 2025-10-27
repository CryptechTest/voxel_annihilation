local animations = {
    -- Standard animations.
    stand     = {x = 1.08,   y = 1.08},
    walk      = {x = 0,  y = 1}
}

va_units.register_unit("vox_scout", {
    mesh = "va_units_vox_scout.gltf",
    texture ="va_units_vox_scout.png",
    visual_size = { x = 1, y = 1},
    collisionbox = {-0.45, 0.01, -0.4, 0.45, 0.7, 0.5},
    selectionbox = { -0.45, 0.0, -0.4, 0.45, 0.55, 0.5 },
    driver_eye_offset = { x = 0, y = 2, z = -16 },
    stepheight = 1.0,
    hp_max = 10,
    nametag = "VFSB-1",
    animations = animations,
    animation_speed = 3.5,
    movement_speed = 3.0,
    spawn_item_description = "VFSB-1 Unit Spawn",
    item_inventory_image = "va_units_blueprint.png",
})