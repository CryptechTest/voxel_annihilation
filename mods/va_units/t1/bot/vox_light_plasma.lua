local animations = {
    -- Standard animations.
    stand     = {x = 1.08,   y = 1.08},
    walk      = {x = 0,  y = 1}
}

va_units.register_unit("vox_light_plasma", {
    mesh = "va_units_vox_light_plasma.gltf",
    texture ="va_units_vox_light_plasma.png",
    visual_size = { x = 1, y = 1},
    collisionbox = {-0.45, 0.01, -0.5, 0.5, 1.6, 0.5},
    selectionbox = { -0.45, 0.0, -0.5, 0.5, 1.6, 0.5 },
    driver_eye_offset = { x = 0, y = 10, z = -16 },
    stepheight = 0.6,
    hp_max = 100,
    nametag = "VLPB-1",
    animations = animations,
    animation_speed = 0.9,
    movement_speed = 0.7,
    backward_speed = 0.65,
    turn_speed = 0.4,
    spawn_item_description = "VLPB-1 Unit Spawn",
    item_inventory_image = "va_units_blueprint.png",
    mass_cost = 13,
    energy_cost = 130,
    build_time = 220,
    sight_range = 38,
    can_attack = true,
    weapons = {
        {
            name = "plasma",
            cooldown = 3,
            range = 18,
            base_damage = 12,
            offset = { x = 0.23, y = 1.05, z = 0.49 },
            attack_targets = { "ground"},
        },
        {
            name = "plasma",
            cooldown = 3,
            range = 18,
            base_damage = 12,
            offset = { x = -0.23, y = 1.05, z = 0.49 },
            attack_targets = { "ground"},
        }
    }
})