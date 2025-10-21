local animations = {
    -- Standard animations.
    stand     = {x = 0,   y = 0},
    walk      = {x = 0,  y = 0.5}
}

va_units.register_unit("vox_fast_infantry", {
    mesh = "va_units_vox_fast_infantry.gltf",
    texture ="va_units_vox_fast_infantry.png",
    visual_size = { x = 1, y = 1},
    collisionbox = {-0.65, 0, -0.55, 0.65, 1.95, 0.7},
    selectionbox = { -0.65, 0.0, -0.55, 0.65, 1.8, 0.7 },
    stepheight = 0.6,
    hp_max = 10,
    nametag = "VFIB-1",
    animations = animations,
    spawn_item_description = "VFIB-1 Unit Spawn",
    item_inventory_image = "va_units_blueprint.png",
})