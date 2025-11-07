core.register_decoration({
    name = "va_resources:cactus_1",
    deco_type = "simple",
    place_on = {"badlands:red_sand", "default:desert_sand", "default:dry_dirt"},
    sidelen = 8,
    noise_params = {
        offset = 0.00007,
        scale = 0.00121,
        spread = {
            x = 250,
            y = 200,
            z = 250
        },
        seed = 388,
        octaves = 5,
        persist = 0.88
    },
    -- biomes = { "badlands_plains" },
    y_max = 128,
    y_min = 2,
    decoration = "default:cactus",
    height = 2,
    height_max = 4
})

core.register_decoration({
    name = "va_resources:burnt_grass_1",
    deco_type = "simple",
    place_on = {"badlands:red_sand", "default:silver_sand"},
    sidelen = 8,
    noise_params = {
        offset = 0.00152,
        scale = 0.003124,
        spread = {
            x = 350,
            y = 200,
            z = 350
        },
        seed = 471,
        octaves = 5,
        persist = 0.88
    },
    -- biomes = { "badlands_plains" },
    y_max = 96,
    y_min = 9,
    decoration = "saltd:burnt_grass"
})

core.register_decoration({
    name = "va_resources:thorny_bush_1",
    deco_type = "simple",
    place_on = {"badlands:red_sand"},
    sidelen = 8,
    noise_params = {
        offset = 0.00021,
        scale = 0.0006254,
        spread = {
            x = 350,
            y = 200,
            z = 350
        },
        seed = 479,
        octaves = 5,
        persist = 0.88
    },
    -- biomes = { "badlands_plains" },
    y_max = 96,
    y_min = 7,
    decoration = "saltd:thorny_bush"
})

core.register_decoration({
    name = "va_resources:salt_gem_1",
    deco_type = "simple",
    place_on = {"default:silver_sand"},
    sidelen = 16,
    noise_params = {
        offset = 0.0000011,
        scale = 0.00082,
        spread = {
            x = 250,
            y = 100,
            z = 250
        },
        seed = 3468,
        octaves = 3,
        persist = 0.41
    },
    -- biomes = { "badlands_plains" },
    y_max = 10,
    y_min = 3,
    decoration = "saltd:salt_gem"
})

core.register_node("va_resources:gem_1", {
    description = ("Gem Blue"),
    drawtype = "plantlike",
    tiles = {"va_resources_gem_1.png"},
    inventory_image = "va_resources_gem_1.png",
    wield_image = "va_resources_gem_1.png",
    paramtype = "light",
    light_source = 2,
    paramtype2 = "meshoptions",
    use_texture_alpha = "blend",
    walkable = true,
    collision_box = {
        type = "fixed",
        fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, 3 / 16, 3 / 16}
    },
    selection_box = {
        type = "fixed",
        fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, 3 / 16, 3 / 16}
    },
    groups = {
        cracky = 1,
        va_gems = 1
    },
    --sounds = default.node_sound_glass_defaults()
})

core.register_node("va_resources:gem_2", {
    description = ("Gem Red"),
    drawtype = "plantlike",
    tiles = {"va_resources_gem_2.png"},
    inventory_image = "va_resources_gem_2.png",
    wield_image = "va_resources_gem_2.png",
    paramtype = "light",
    light_source = 3,
    paramtype2 = "meshoptions",
    use_texture_alpha = "blend",
    walkable = true,
    collision_box = {
        type = "fixed",
        fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, 3 / 16, 3 / 16}
    },
    selection_box = {
        type = "fixed",
        fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, 3 / 16, 3 / 16}
    },
    groups = {
        cracky = 1,
        va_gems = 2
    },
    --sounds = default.node_sound_glass_defaults()
})

core.register_node("va_resources:gem_3", {
    description = ("Gem Purple"),
    drawtype = "plantlike",
    tiles = {"va_resources_gem_3.png"},
    inventory_image = "va_resources_gem_3.png",
    wield_image = "va_resources_gem_3.png",
    paramtype = "light",
    light_source = 3,
    paramtype2 = "meshoptions",
    use_texture_alpha = "blend",
    walkable = true,
    collision_box = {
        type = "fixed",
        fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, 3 / 16, 3 / 16}
    },
    selection_box = {
        type = "fixed",
        fixed = {-3 / 16, -0.5, -3 / 16, 3 / 16, 3 / 16, 3 / 16}
    },
    groups = {
        cracky = 1,
        va_gems = 3
    },
    --sounds = default.node_sound_glass_defaults()
})


core.register_decoration({
    name = "va_resources:gem_1",
    deco_type = "simple",
    place_on = {"default:silver_sand", "saltd:salt_sand"},
    sidelen = 8,
    noise_params = {
        offset = 0.00000218,
        scale = 0.001023,
        spread = {
            x = 150,
            y = 100,
            z = 150
        },
        seed = 25342,
        octaves = 3,
        persist = 0.41
    },
    -- biomes = { "badlands_plains" },
    y_max = 27,
    y_min = 1,
    decoration = "va_resources:gem_1"
})

core.register_decoration({
    name = "va_resources:gem_3",
    deco_type = "simple",
    place_on = {"default:silver_sand"},
    sidelen = 32,
    noise_params = {
        offset = 0.00000148,
        scale = 0.0003192,
        spread = {
            x = 150,
            y = 100,
            z = 150
        },
        seed = 38928,
        octaves = 2,
        persist = 0.41
    },
    -- biomes = { "badlands_plains" },
    y_max = 37,
    y_min = 12,
    decoration = "va_resources:gem_3"
})

core.register_decoration({
    name = "va_resources:gem_2",
    deco_type = "simple",
    place_on = {"badlands:red_sand"},
    sidelen = 16,
    noise_params = {
        offset = 0.000002102,
        scale = 0.00014,
        spread = {
            x = 150,
            y = 100,
            z = 150
        },
        seed = 35290,
        octaves = 3,
        persist = 0.41
    },
    -- biomes = { "badlands_plains" },
    y_max = 56,
    y_min = 13,
    decoration = "va_resources:gem_2"
})