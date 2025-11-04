local registrations = {{
    place_on = "default:sand",
    deco = "va_resources:sand_with_metal",
    replace = "sand"
}, {
    place_on = "default:desert_sand",
    deco = "va_resources:desert_sand_with_metal",
    replace = "desert_sand"
}, {
    place_on = "default:dirt",
    deco = "va_resources:dirt_with_metal",
    replace = "dirt"
}, {
    place_on = "default:dry_dirt",
    deco = "va_resources:dry_dirt_with_metal",
    replace = "dry_dirt"
}, {
    place_on = "default:gravel",
    deco = "va_resources:gravel_with_metal",
    replace = "gravel"
}, {
    place_on = "default:stone",
    deco = "va_resources:stone_with_metal",
    replace = "stone"
}, {
    place_on = "default:permafrost_with_stones",
    deco = "va_resources:moss_with_metal",
    replace = "moss",
    offset = 0.0000125
}, {
    place_on = "default:dirt_with_grass",
    deco = "va_resources:grass_with_metal",
    replace = "grass"
}, {
    place_on = "default:dirt_with_snow",
    deco = "va_resources:dirt_snow_with_metal",
    replace = "dirt_snow"
}, {
    place_on = "default:permafrost_with_stones",
    deco = "va_resources:permafrost_with_metal",
    replace = "permafrost"
}, {
    place_on = "default:dirt_with_coniferous_litter",
    deco = "va_resources:coniferous_litter_with_metal",
    replace = "coniferous_litter"
}, {
    place_on = "default:dirt_with_rainforest_litter",
    deco = "va_resources:rainforest_litter_with_metal",
    replace = "rainforest_litter"
}, {
    place_on = "default:dry_dirt_with_dry_grass",
    deco = "va_resources:dry_dirt_with_grass_with_metal",
    replace = "dry_dirt_with_grass"
}, {
    place_on = "default:desert_sandstone",
    deco = "va_resources:desert_sandstone_with_metal",
    replace = "desert_sandstone"
}, {
    place_on = "default:desert_stone",
    deco = "va_resources:desert_stone_with_metal",
    replace = "desert_stone"
}, {
    place_on = "default:silver_sand",
    deco = "va_resources:silver_sand_with_metal",
    replace = "silver_sand"
}}

if core.get_modpath("badlands") then
    table.insert(registrations, {
        place_on = "badlands:red_sand",
        deco = "va_resources:red_sand_with_metal",
        replace = "red_sand"
    })
    table.insert(registrations, {
        place_on = "badlands:red_sandstone",
        deco = "va_resources:red_sandstone_with_metal",
        replace = "red_sandstone"
    })
end

if core.get_modpath("bakedclay") then
    -- list of clay colours
    local clay = {{"natural", "Natural"}, {"white", "White"}, {"grey", "Grey"}, {"black", "Black"}, {"red", "Red"},
                  {"yellow", "Yellow"}, {"green", "Green"}, {"cyan", "Cyan"}, {"blue", "Blue"}, {"magenta", "Magenta"},
                  {"orange", "Orange"}, {"violet", "Violet"}, {"brown", "Brown"}, {"pink", "Pink"},
                  {"dark_grey", "Dark Grey"}, {"dark_green", "Dark Green"}}
    -- iterate over clay colours
    for _, c in pairs(clay) do
        table.insert(registrations, {
            place_on = "bakedclay:" .. c[1],
            deco = "va_resources:clay_" .. c[1] .. "_with_metal",
            replace = "clay_" .. c[1]
        })
    end
end

if core.get_modpath("saltd") then
    table.insert(registrations, {
        place_on = "saltd:salt_sand",
        deco = "va_resources:salt_sand_with_metal",
        replace = "salt_sand"
    })
    table.insert(registrations, {
        place_on = "saltd:humid_salt_sand",
        deco = "va_resources:humid_salt_sand_with_metal",
        replace = "humid_salt_sand"
    })
    table.insert(registrations, {
        place_on = "saltd:salt_sand",
        deco = "va_resources:barren_with_metal",
        replace = "barren",
        scale = 0.0001
    })
end

local function register_mass(def)

    core.register_decoration({
        name = def.deco .. "_low",
        deco_type = "simple",
        place_on = {def.place_on} or {},
        biomes = def.biomes or nil,
        -- spawn_by = def.spawn_by or {},
        -- num_spawn_by = def.num_spawn_by or 1,
        sidelen = 16,
        noise_params = {
            offset = def.offset or 0.000146,
            scale = def.scale or 0.0001,
            spread = {
                x = 200,
                y = 200,
                z = 200
            },
            seed = 88,
            octaves = def.octaves or 2,
            persist = def.persist or 0.37
        },
        y_max = 32,
        y_min = -15,
        decoration = def.deco,
        place_offset_y = -1,
        flags = "force_placement"
    })

    core.register_decoration({
        name = def.deco .. "_mid",
        deco_type = "simple",
        place_on = {def.place_on} or {},
        biomes = def.biomes or nil,
        sidelen = 16,
        noise_params = {
            offset = def.offset or 0.001057,
            scale = def.scale or 0.005,
            spread = {
                x = 200,
                y = 100,
                z = 200
            },
            seed = 88,
            octaves = def.octaves or 3,
            persist = def.persist or 0.64
        },
        y_max = 64,
        y_min = 33,
        decoration = def.deco,
        place_offset_y = -1,
        flags = "force_placement"
    })

    core.register_decoration({
        name = def.deco .. "_high",
        deco_type = "simple",
        place_on = {def.place_on} or {},
        biomes = def.biomes or nil,
        sidelen = 16,
        noise_params = {
            offset = def.offset or 0.004510,
            scale = def.scale or 0.025,
            spread = {
                x = 200,
                y = 50,
                z = 200
            },
            seed = 88,
            octaves = def.octaves or 3,
            persist = def.persist or 0.72
        },
        y_max = 128,
        y_min = 65,
        decoration = def.deco,
        place_offset_y = -1,
        flags = "force_placement"
    })
end

local metals = {}

for _, def in pairs(registrations) do
    register_mass(def)
    local id_1 = core.get_decoration_id(def.deco .. "_low")
    metals[id_1] = def.replace
    local id_2 = core.get_decoration_id(def.deco .. "_mid")
    metals[id_2] = def.replace
    local id_3 = core.get_decoration_id(def.deco .. "_high")
    metals[id_3] = def.replace
end

local metal_ids = {}
for id, m in pairs(metals) do
    table.insert(metal_ids, id)
end

core.set_gen_notify({
    decoration = true
}, metal_ids)

-- start nodetimers
core.register_on_generated(function(minp, maxp, blockseed)
    if maxp.y > 16 * 72 + 1 or minp.y < -(16 * 72 + 2) then
        return
    end
    if maxp.x > 4095 + 16 or minp.x < -(4096) then
        return
    end
    if maxp.z > 4095 + 16 or minp.z < -(4096) then
        return
    end

    local gennotify = core.get_mapgen_object("gennotify")

    math.randomseed(blockseed)

    for id, replace in pairs(metals) do
        local poslist = {}
        for _, pos in ipairs(gennotify["decoration#" .. id] or {}) do
            local deco_pos = {
                x = pos.x,
                y = pos.y,
                z = pos.z
            }
            table.insert(poslist, {
                pos = deco_pos,
                replace = replace
            })
        end

        if #poslist ~= 0 then
            for i = 1, #poslist do
                local p = poslist[i]
                local t_m = nil

                local r = math.random(0, 31)
                if r <= 2 then
                    va_resources.add_mass_deposit(p.pos, p.replace, nil, 'c')
                elseif r <= 5 then
                    va_resources.add_mass_deposit(p.pos, p.replace, nil, 's')
                else
                    if math.random(0, 47) <= 1 then
                        t_m = "gold"
                    end
                    va_resources.add_mass_deposit(p.pos, p.replace, nil, t_m)
                end
            end
        end
    end
end)
