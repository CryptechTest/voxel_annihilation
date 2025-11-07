local modname = core.get_current_modname()

local rocks_defs = {{
    name = "small_rocks",
    desc = "Small Rocks",
    levels = 9,
    mesh = "va_small_rocks",
    tiles = {{
        name = "va_small_rocks_2.png"
    }},
    place_on = {"default:dirt_with_grass", "default:dirt_with_snow", "default:dirt", "default:stone", "default:gravel", "dirt_with_coniferous_litter"}
}, {
    name = "small_rocks_red",
    desc = "Small Rocks Desert",
    levels = 9,
    mesh = "va_small_rocks",
    tiles = {{
        name = "va_small_rocks_3.png"
    }},
    place_on = {"default:desert_sand", "default:desert_stone", "badlands:red_sand", "bakedclay:red"}
}, {
    name = "small_rocks_sandstone",
    desc = "Small Rocks Sandstone",
    levels = 9,
    mesh = "va_small_rocks",
    tiles = {{
        name = "va_small_rocks_5.png"
    }},
    place_on = {"saltd:salt_sand", "default:sand", "default:desert_sandstone", "default:dry_dirt"}
}, {
    name = "small_rocks_sandstone_dry",
    desc = "Small Rocks Dry Sandstone",
    levels = 9,
    mesh = "va_small_rocks",
    tiles = {{
        name = "va_small_rocks_4.png"
    }},
    place_on = {"saltd:salt_sand", "default:dry_dirt", "default:dry_dirt_with_dry_grass", "bakedclay:orange"}
}, {
    name = "small_rocks_sandstone_silver",
    desc = "Small Rocks Silver Sandstone",
    levels = 9,
    mesh = "va_small_rocks",
    tiles = {{
        name = "va_small_rocks_6.png"
    }},
    place_on = {"saltd:salt_sand", "default:silver_sand", "default:dirt_with_snow", "bakedclay:natural"}
}, {
    name = "small_rocks_permafrost",
    desc = "Small Rocks Permafrost",
    levels = 9,
    mesh = "va_small_rocks",
    tiles = {{
        name = "va_small_rocks_7.png"
    }},
    place_on = {"default:permafrost_with_stones", "default:dirt_with_grass", "default:dirt", "default:stone", "dirt_with_coniferous_litter"}
}, {
    name = "small_rocks_moss",
    desc = "Small Rocks Mossy",
    levels = 9,
    mesh = "va_small_rocks",
    tiles = {{
        name = "va_small_rocks_8b.png"
    }},
    place_on = {"default:permafrost_with_stones", "default:permafrost_with_moss", "default:dirt_with_grass", "dirt_with_coniferous_litter" }
}}

local function register_rock(def, index)

    local node_name = modname .. ":" .. def.name .. "_" .. index
    core.register_node(node_name, {
        description = def.desc or "Rocks",
        tiles = def.tiles,
        drawtype = "mesh",
        mesh = def.mesh .. "_" .. index .. ".gltf",
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {
            cracky = 2,
            va_rocks = index or 1,
            va_mass_value = 21, -- base value for index 1
            va_energy_value = 2 -- base value for index 1
        },
        drop = "",
        sunlight_propagates = true,
        collision_box = {
            type = "fixed",
            fixed = {-8 / 16, -8 / 16, -8 / 16, 8 / 16, 0, 8 / 16}
        },
        selection_box = {
            type = "fixed",
            fixed = {-8 / 16, -8 / 16, -8 / 16, 8 / 16, 0, 8 / 16}
        },

        _degrade = function(pos)
            local node = core.get_node(pos)
            local g_node = core.get_item_group(node.name, "va_rocks")
            if g_node - 1 <= 0 then
                core.remove_node(pos)
                return true
            end
            local meta = core.get_meta(pos)
            meta:set_int("claimed", 0)
            local next_node_name = modname .. ":" .. def.name .. "_" .. (g_node - 1)
            core.swap_node(pos, {
                name = next_node_name,
                param2 = node.param2
            })
            return false
        end,

        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then
                return itemstack
            end

            local a_pos = pointed_thing.above
            local b_pos = pointed_thing.under
            local pos_below = b_pos and b_pos or vector.subtract(a_pos, {
                x = 0,
                y = 1,
                z = 0
            })

            local node = core.get_node(b_pos or pos_below)
            local g_node = core.get_item_group(node.name, "va_rocks")
            local g_item = core.get_item_group(itemstack:get_name(), "va_rocks")

            if g_node > 0 and g_item > 0 then

                if g_node + g_item <= def.levels then
                    local next_node_name = modname .. ":" .. def.name .. "_" .. (g_node + g_item)

                    core.swap_node(pos_below, {
                        name = next_node_name,
                        param2 = node.param2
                    })

                    itemstack:take_item(1)
                else

                    if g_node == def.levels then
                        return
                    end

                    local next_node_name = modname .. ":" .. def.name .. "_" .. 9

                    local new_item_lvl = (g_node + g_item) - def.levels
                    local new_item_name = modname .. ":" .. def.name .. "_" .. new_item_lvl

                    core.swap_node(pos_below, {
                        name = next_node_name,
                        param2 = node.param2
                    })

                    itemstack:take_item(1)

                    local inv = placer:get_inventory()
                    inv:add_item("main", new_item_name)

                end
            else
                local param2 = core.dir_to_facedir(placer:get_look_dir())
                local next_node_name = modname .. ":" .. def.name .. "_" .. g_item
                core.set_node(a_pos, {
                    name = next_node_name,
                    param2 = param2
                })
                itemstack:take_item(1)
            end

            local node_def = core.registered_nodes[node.name]
            if node_def and node_def.after_place_node then
                node_def.after_place_node(pointed_thing.above, placer, itemstack, pointed_thing)
            end
            return itemstack
        end,

        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)

            local g_node = core.get_item_group(node.name, "va_rocks")
            local g_item = core.get_item_group(itemstack:get_name(), "va_rocks")

            if g_node > 0 and g_item > 0 then

                if g_node + g_item <= def.levels then
                    local next_node_name = modname .. ":" .. def.name .. "_" .. (g_node + g_item)

                    core.swap_node(pos, {
                        name = next_node_name,
                        param2 = node.param2
                    })

                    itemstack:take_item(1)
                end
            end
        end,

        after_dig_node = function(pos, oldnode, oldmetadata, digger)

            local g = core.get_item_group(oldnode.name, "va_rocks")

            if g - 1 <= 0 then
                return
            end

            local prev_node_name = def.node_name .. "_" .. (g - 1)

            core.swap_node(pos, {
                name = prev_node_name,
                param2 = oldnode.param2
            })

        end

    })

end

local function register_deco(def, level)

    core.register_decoration({
        name = def.name .. "_deco" .. "_" .. tonumber(level),
        deco_type = "simple",
        place_on = def.place_on or {},
        biomes = def.biomes or nil,
        sidelen = 8,
        noise_params = {
            offset = def.offset or 0.00008173,
            scale = def.scale or 0.000002,
            spread = {
                x = 100,
                y = 100,
                z = 100
            },
            seed = 441 + level,
            octaves = def.octaves or 4,
            persist = def.persist or 0.28
        },
        y_max = 128,
        y_min = 1,
        decoration = "va_resources:" .. def.name .. "_" .. tostring(level),
        flags = "force_placement",
        rotation = "random",
        --param2 = 0,
        --param2_max = 4,
    })

end

local function register_rocks()
    for _, v in pairs(rocks_defs) do
        for i = 1, v.levels, 1 do
            register_rock(v, i)
            register_deco(v, i)
        end
    end

end

register_rocks()
