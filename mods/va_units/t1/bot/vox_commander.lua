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
    hp_max = 370,
    nametag = "VCOM",
    animations = animations,
    animation_speed = 0.6,
    movement_speed = 0.4,
    spawn_item_description = "VCOM Unit Spawn",
    item_inventory_image = "va_units_blueprint.png",
    mass_cost = 270,
    mass_storage = 50,
    mass_generate = 0.1,
    energy_cost = 2600,
    energy_storage = 50,
    energy_generate = 1,
    build_time = 7500,
    build_power = 30,
    can_build = true,
    can_reclaim = true,
    sight_range = 32,
    can_attack = true,
    is_commander = true,
    weapons = {
        {
            name = "light_laser",
            cooldown = 0.5,
            range = 16,
            base_damage = 4.5,
            offset = { x = 0.12, y = 1.8, z = 0.9 },
            attack_targets = { "ground"},
        },
        {
            name = "light_laser",
            cooldown = 0.5,
            range = 16,
            base_damage = 4.5,
            offset = { x = -0.12, y = 1.8, z = 0.9 },
            attack_targets = { "ground"},
        }
    }
})