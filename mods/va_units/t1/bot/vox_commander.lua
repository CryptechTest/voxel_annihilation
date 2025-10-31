local animations = {
    -- Standard animations.
    stand     = {x = 1.08,   y = 1.08},
    walk      = {x = 0,  y = 1}
}

va_units.register_unit("vox_commander", {
    mesh = "va_units_vox_commander.gltf",
    texture ="va_units_vox_commander.png",
    visual_size = { x = 1, y = 1},
    collisionbox = {-0.5, 0.01, -0.45, 0.5, 2.2, 0.45},
    selectionbox = { -0.5, 0.0, -0.45, 0.5, 2.2, 0.45 },
    stepheight =  1.0,
    hp_max = 10,
    nametag = "VCOM",
    animations = animations,
    animation_speed = 0.6,
    movement_speed = 0.4,
    spawn_item_description = "VCOM Unit Spawn",
    item_inventory_image = "va_units_blueprint.png",
    mass_cost = 270,
    energy_cost = 2600,
    build_time = 7500,
    build_power = 30
})