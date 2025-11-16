local animations = {
    -- Standard animations.
    stand     = {x = 1.08,   y = 1.08},
    walk      = {x = 0,  y = 1}
}

va_units.register_unit("vox_scout", {
    mesh = "va_units_vox_scout.gltf",
    texture ="va_units_vox_scout.png",
    visual_size = { x = 1, y = 1},
    collisionbox = {-0.1, 0.01, -0.2, 0.1, 0.3, 0.05},
    selectionbox = { -0.1, 0.0, -0.2, 0.1, 0.3, 0.05 },
    driver_eye_offset = { x = 0, y = 2, z = -16 },
    stepheight = 1.0,
    hp_max = 6,
    nametag = "VFSB-1",
    animations = animations,
    animation_speed = 3.5,
    movement_speed = 3.0,
    spawn_item_description = "VFSB-1 Unit Spawn",
    item_inventory_image = "va_units_blueprint.png",
    mass_cost = 2.1,
    energy_cost = 30,
    build_time = 80,
    sight_range = 20,
    can_attack = true,
    weapons = {
        {
            name = "plasma",
            cooldown = 0.25,
            range = 14,
            base_damage = 1,
            offset = { x = 0, y = 0.32, z = 0.05 },
            -- launch at 45 degree angle up
            launch_vector = { x = 0, y = 2, z = 2 },
            attack_targets = { "ground"},
        }
    }
})