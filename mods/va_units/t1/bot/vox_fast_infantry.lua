local animations = {
    -- Standard animations.
    stand     = {x = 1.08,   y = 1.08},
    walk      = {x = 0,  y = 1.0}
}

va_units.register_unit("vox_fast_infantry", {
    mesh = "va_units_vox_fast_infantry.gltf",
    texture ="va_units_vox_fast_infantry.png",
    visual_size = { x = 1, y = 1},
    collisionbox = {-0.6, 0.01, -0.45, 0.6, 1.7, 0.65},
    selectionbox = { -0.6, 0.0, -0.45, 0.6, 1.65, 0.65},
    driver_eye_offset = { x = 0, y = 10, z = -16 },
    stepheight = 1.0,
    hp_max = 37,
    nametag = "VFIB-1",
    animations = animations,
    animation_speed = 2.0,
    movement_speed = 1.6,
    backward_speed = 1.6,
    turn_speed = 1.0,
    spawn_item_description = "VFIB-1 Unit Spawn",
    item_inventory_image = "va_units_blueprint.png",
    mass_cost = 5.4,
    energy_cost = 90,
    build_time = 165,
    sight_range = 43,
    can_attack = true,
    weapons = {
        {
            name = "plasma",
            cooldown = 0.33,
            range = 18,
            base_damage = 1.25,
            offset = { x = 0.28, y = 0.6, z = 0.4 },
            attack_targets = { "ground"},
        },
        {
            name = "plasma",
            cooldown = 0.33,
            range = 18,
            base_damage = 1.25,
            offset = { x = -0.28, y = 0.6, z = 0.4 },
            attack_targets = { "ground"},
        }
    }
})