local deepcopy = va_structures.util.deepcopy

local mass_deposits = {{
    check = "default:dirt_with_grass",
    base_name = "grass",
    node_desc = "Grass",
    base_texture = "default_grass.png",
    tiles = {"default_grass.png", "default_dirt.png", {
        name = "default_dirt.png^default_grass_side.png",
        tileable_vertical = false
    }}
}, {
    check = "default:dry_dirt_with_dry_grass",
    base_name = "dry_dirt_with_grass",
    node_desc = "Dry Dirt with Grass",
    base_texture = "default_dry_grass.png",
    tiles = {"default_dry_grass.png", "default_dry_dirt.png", {
        name = "default_dry_dirt.png^default_dry_grass_side.png",
        tileable_vertical = false
    }}
}, {
    check = "default:dirt_with_dry_grass",
    base_name = "dry_grass",
    node_desc = "Dry Dirt with Grass",
    base_texture = "default_dry_grass.png",
    tiles = {"default_dry_grass.png", "default_dry_dirt.png", {
        name = "default_dry_dirt.png^default_dry_grass_side.png",
        tileable_vertical = false
    }}
}, {
    check = "default:dirt_with_dry_grass",
    base_name = "dirt_with_dry_grass",
    node_desc = "Dry Grass",
    base_texture = "default_dry_grass.png",
    tiles = {"default_dry_grass.png", "default_dirt.png", {
        name = "default_dirt.png^default_dry_grass_side.png",
        tileable_vertical = false
    }}
}, {
    check = "default:dirt_with_snow",
    base_name = "dirt_snow",
    node_desc = "Snow",
    base_texture = "default_snow.png",
    tiles = {"default_snow.png", "default_dirt.png", {
        name = "default_dirt.png^default_snow_side.png",
        tileable_vertical = false
    }}
}, {
    check = "default:dry_dirt",
    base_name = "dry_dirt",
    node_desc = "Dry Dirt",
    base_texture = "default_dry_dirt.png",
    tiles = {"default_dry_dirt.png", "default_dry_dirt.png"}
}, {
    check = "default:dirt",
    base_name = "dirt",
    node_desc = "Dirt",
    base_texture = "default_dirt.png",
    tiles = {"default_dirt.png", "default_dirt.png"}
}, {
    check = "default:gravel",
    base_name = "gravel",
    node_desc = "Gravel",
    base_texture = "default_gravel.png",
    tiles = {"default_gravel.png", "default_gravel.png"}
}, {
    check = "default:stone",
    base_name = "stone",
    node_desc = "Stone",
    base_texture = "default_stone.png",
    tiles = {"default_stone.png", "default_stone.png"}
}, {
    check = "default:desert_stone",
    base_name = "desert_stone",
    node_desc = "Desert Stone",
    base_texture = "default_desert_stone.png",
    tiles = {"default_desert_stone.png", "default_desert_stone.png"}
}, {
    check = "default:desert_sandstone",
    base_name = "desert_sandstone",
    node_desc = "Desert Sandstone",
    base_texture = "default_desert_sandstone.png",
    tiles = {"default_desert_sandstone.png", "default_desert_sandstone.png"}
}, {
    check = "default:sand",
    base_name = "sand",
    node_desc = "Sand",
    base_texture = "default_sand.png",
    tiles = {"default_sand.png", "default_sand.png"}
}, {
    check = "default:desert_sand",
    base_name = "desert_sand",
    node_desc = "Desert Sand",
    base_texture = "default_desert_sand.png",
    tiles = {"default_desert_sand.png", "default_desert_sand.png"}
}, {
    check = "default:silver_sand",
    base_name = "silver_sand",
    node_desc = "Silver Sand",
    base_texture = "default_silver_sand.png",
    tiles = {"default_silver_sand.png", "default_silver_sand.png"}
}, {
    check = "default:permafrost_with_stones",
    base_name = "permafrost",
    node_desc = "Permaforst",
    base_texture = "default_permafrost.png^default_stones.png",
    tiles = {"default_permafrost.png^default_stones.png", "default_permafrost.png",
             "default_permafrost.png^default_stones_side.png"}
}, {
    check = "default:permafrost_with_moss",
    base_name = "moss",
    node_desc = "Moss",
    base_texture = "default_moss.png",
    tiles = {"default_moss.png", "default_permafrost.png", {
        name = "default_permafrost.png^default_moss_side.png",
        tileable_vertical = false
    }}
}, {
    check = "default:dirt_with_coniferous_litter",
    base_name = "coniferous_litter",
    node_desc = "Coniferous Litter",
    base_texture = "default_coniferous_litter.png",
    tiles = {"default_coniferous_litter.png", "default_dirt.png", {
        name = "default_dirt.png^default_coniferous_litter_side.png",
        tileable_vertical = false
    }}
}, {
    check = "default:dirt_with_rainforest_litter",
    base_name = "rainforest_litter",
    node_desc = "Rainforest Litter",
    base_texture = "default_rainforest_litter.png",
    tiles = {"default_rainforest_litter.png", "default_dirt.png", {
        name = "default_dirt.png^default_rainforest_litter_side.png",
        tileable_vertical = false
    }}
}}

if core.get_modpath("badlands") then
    table.insert(mass_deposits, {
        check = "badlands:red_sand",
        base_name = "red_sand",
        node_desc = "Red Sand",
        base_texture = "default_sand.png^[colorize:sienna:175^[colorize:red:40",
        tiles = {"default_sand.png^[colorize:sienna:175^[colorize:red:40",
                 "default_sand.png^[colorize:sienna:175^[colorize:red:40"}
    })
    table.insert(mass_deposits, {
        check = "badlands:red_sandstone",
        base_name = "red_sandstone",
        node_desc = "Red Sandstone",
        base_texture = "default_sandstone.png^[colorize:sienna:175^[colorize:red:40",
        tiles = {"default_sandstone.png^[colorize:sienna:175^[colorize:red:40",
                 "default_sandstone.png^[colorize:sienna:175^[colorize:red:40"}
    })
end

if core.get_modpath("bakedclay") then
    table.insert(mass_deposits, {
        check = "bakedclay:orange",
        base_name = "clay_orange",
        node_desc = "Orange Clay",
        base_texture = "baked_clay_orange.png",
        tiles = {"baked_clay_orange.png", "baked_clay_orange.png"}
    })
end

if core.get_modpath("saltd") then
    table.insert(mass_deposits, {
        check = "saltd:salt_sand",
        base_name = "salt_sand",
        node_desc = "Salt Sand",
        use_hd_texture = true,
        base_texture = "saltd_salt_sand.png",
        tiles = {"saltd_salt_sand.png", "saltd_salt_sand.png"}
    })
    table.insert(mass_deposits, {
        check = "saltd:humid_salt_sand",
        base_name = "humid_salt_sand",
        node_desc = "Humid Salt Sand",
        use_hd_texture = true,
        base_texture = "saltd_humid_salt_sand.png",
        tiles = {"saltd_humid_salt_sand.png", "saltd_humid_salt_sand.png"}
    })
    table.insert(mass_deposits, {
        check = "saltd:barren",
        base_name = "barren",
        node_desc = "Barren Land",
        use_hd_texture = true,
        base_texture = "saltd_barren.png",
        tiles = {"saltd_barren.png", "saltd_barren.png"}
    })
end

local dirs = {{ -- along x beside
    x = 1,
    y = 0,
    z = 0
}, {
    x = -1,
    y = 0,
    z = 0
}, { -- along z beside
    x = 0,
    y = 0,
    z = 1
}, {
    x = 0,
    y = 0,
    z = -1
}, { -- nodes on x corner
    x = 1,
    y = 0,
    z = 1
}, {
    x = -1,
    y = 0,
    z = 1
}, { -- nodes on z corner
    x = -1,
    y = 0,
    z = -1
}, {
    x = 1,
    y = 0,
    z = -1
}}

local function register_mass_deposit(def)

    local base_name = def.base_name or "grass"
    local node_desc = " on " .. (def.node_desc or "Grass")
    local base_texture = def.base_texture or "default_grass"
    local mass_texture = def.mass_texture or "va_mineral"

    local t_m = def.mass_type or "a"
    local tt_name = def.mass_type and "_" .. t_m or ""

    local t_name_b = "va_resources:" .. base_name .. "_with_metal" .. tt_name
    local t_name = "va_resources:" .. base_name .. "_near_metal" .. tt_name

    local hd = ""
    if def.use_hd_texture then
        hd = "_hd"
    end

    local item_image = base_texture .. "^" .. mass_texture .. "_" .. t_m .. "_1" .. hd .. ".png"
    local tiles = def.tiles or {}

    local tiles_0 = deepcopy(tiles)
    tiles_0[1] = base_texture .. "^(" .. mass_texture .. "_" .. t_m .. "_1" .. hd .. ".png)"

    local tiles_1 = deepcopy(tiles)
    tiles_1[1] = base_texture .. "^((" .. mass_texture .. "_" .. t_m .. "_2" .. hd .. ".png)^[transformFYR90])"

    local tiles_2 = deepcopy(tiles)
    tiles_2[1] = base_texture .. "^((" .. mass_texture .. "_" .. t_m .. "_2" .. hd .. ".png)^[transformR90])"

    local tiles_3 = deepcopy(tiles)
    tiles_3[1] = base_texture .. "^((" .. mass_texture .. "_" .. t_m .. "_2" .. hd .. ".png)^[transformFX])"

    local tiles_4 = deepcopy(tiles)
    tiles_4[1] = base_texture .. "^((" .. mass_texture .. "_" .. t_m .. "_2" .. hd .. ".png)^[transformR180])"

    local tiles_5 = deepcopy(tiles)
    tiles_5[1] = base_texture .. "^((" .. mass_texture .. "_" .. t_m .. "_3" .. hd .. ".png))"

    local tiles_6 = deepcopy(tiles)
    tiles_6[1] = base_texture .. "^((" .. mass_texture .. "_" .. t_m .. "_3" .. hd .. ".png)^[transformR180])"

    local tiles_7 = deepcopy(tiles)
    tiles_7[1] = base_texture .. "^((" .. mass_texture .. "_" .. t_m .. "_4" .. hd .. ".png)^[transformFY])"

    local tiles_8 = deepcopy(tiles)
    tiles_8[1] = base_texture .. "^((" .. mass_texture .. "_" .. t_m .. "_4" .. hd .. ".png)^[transformR90])"

    -- center node
    core.register_node(t_name_b, {
        description = ("Metal Ore" .. node_desc),
        tiles = tiles_0,
        groups = {
            cracky = 2,
            va_mass = 3
        },
        drop = "",
        paramtype = "light",
        light_source = 1,

        inventory_image = def.inventory_image or item_image,
        wield_image = def.wield_image or item_image,

        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then
                return itemstack
            end

            local a_pos = pointed_thing.above
            local pos = vector.subtract(a_pos, {
                x = 0,
                y = 1,
                z = 0
            })

            if def.mass_type then
                if va_resources.add_mass_deposit(pos, base_name, nil, def.mass_type) then
                    itemstack:take_item(1)
                end
            else
                if va_resources.add_mass_deposit(pos, base_name) then
                    itemstack:take_item(1)
                end
            end

            return itemstack
        end
    })

    -- edge/side nodes
    core.register_node(t_name .. "_1", {
        description = ("Metal Ore" .. node_desc),
        tiles = tiles_1,
        groups = {
            cracky = 2,
            va_mass = 2
        },
        drop = ""
    })
    core.register_node(t_name .. "_2", {
        description = ("Metal Ore" .. node_desc),
        tiles = tiles_2,
        groups = {
            cracky = 2,
            va_mass = 2
        },
        drop = ""
    })
    core.register_node(t_name .. "_3", {
        description = ("Metal Ore" .. node_desc),
        tiles = tiles_3,
        groups = {
            cracky = 2,
            va_mass = 2
        },
        drop = ""
    })
    core.register_node(t_name .. "_4", {
        description = ("Metal Ore" .. node_desc),
        tiles = tiles_4,
        groups = {
            cracky = 2,
            va_mass = 2
        },
        drop = ""
    })

    core.register_node(t_name .. "_5", {
        description = ("Metal Ore" .. node_desc),
        tiles = tiles_5,
        groups = {
            cracky = 2,
            va_mass = 1
        },
        drop = ""
    })
    core.register_node(t_name .. "_6", {
        description = ("Metal Ore" .. node_desc),
        tiles = tiles_6,
        groups = {
            cracky = 2,
            va_mass = 1
        },
        drop = ""
    })
    core.register_node(t_name .. "_7", {
        description = ("Metal Ore" .. node_desc),
        tiles = tiles_7,
        groups = {
            cracky = 2,
            va_mass = 1
        },
        drop = ""
    })
    core.register_node(t_name .. "_8", {
        description = ("Metal Ore" .. node_desc),
        tiles = tiles_8,
        groups = {
            cracky = 2,
            va_mass = 1
        },
        drop = ""
    })
end

local function match_deposit_overlap(name)
    for _, o in pairs(mass_deposits) do
        if o.check == name then
            return o.base_name
        end
    end
    return nil
end

local function match_deposit_check(name)
    for _, o in pairs(mass_deposits) do
        if o.base_name == name then
            return o.check
        end
    end
    return nil
end

local groups = {"cracky", "crumbly", "choppy", "soil", "sand"}

function va_resources.add_mass_deposit(pos, b_name, value, mass_type)
    if b_name == nil then
        b_name = "grass"
    end
    if value == nil and mass_type == nil then
        value = va_structures.util.randFloat(0.10, 0.30)
    elseif value == nil and mass_type == "s" then
        value = va_structures.util.randFloat(0.07, 0.08)
    elseif value == nil and mass_type == "c" then
        value = va_structures.util.randFloat(0.31, 0.56)
    elseif value == nil and mass_type == "gold" then
        value = va_structures.util.randFloat(0.57, 0.80)
    end
    if mass_type == nil and value <= 0.18 then
        mass_type = "s"
    end
    if mass_type == nil then
        mass_type = ""
    else
        mass_type = "_" .. mass_type
    end

    local found = false
    local near_air = false
    local nodes_above = 0
    -- check if can place at location
    for _, dir in pairs(dirs) do
        local d_pos = vector.add(pos, dir)
        local node = core.get_node_or_nil(d_pos)
        if not node then
            core.load_area(d_pos, d_pos)
            node = core.get_node_or_nil(d_pos)
        end
        local n_name = node.name
        local g_mass = core.get_item_group(n_name, 'va_mass')
        if g_mass > 0 and g_mass <= 3 then
            found = true
        end
        local g_geo = core.get_item_group(n_name, 'va_geo_vent')
        if g_geo > 0 and g_geo <= 3 then
            found = true
        end

        if n_name == "air" then
            near_air = true
        end

        for _, group in pairs(groups) do
            local g = core.get_item_group(n_name, group)
            if not g then
                near_air = true
            end
        end
    end
    -- check if area above is clear
    for _, dir in pairs(dirs) do
        local d_pos = vector.add(pos, dir)
        d_pos = vector.add(d_pos, {
            x = 0,
            y = 1,
            z = 0
        })
        local node = core.get_node_or_nil(d_pos)
        if not node then
            core.load_area(d_pos, d_pos)
            node = core.get_node_or_nil(d_pos)
        end
        local n_name = node.name
        for _, group in pairs(groups) do
            local g = core.get_item_group(n_name, group)
            if g > 0 then
                nodes_above = nodes_above + 1
                break
            end
        end
    end
    -- if not valid, don't place
    if found or near_air or nodes_above > 1 then
        local n = nil
        local c = {}
        for x = -1, 1 do
            for z = -1, 1 do
                if x == 0 and z == 0 then
                    break;
                end
                local p = vector.add(pos, {
                    x = x,
                    y = 0,
                    z = z
                })
                local node = core.get_node(p)
                if node and node.name ~= "air" and node.name ~= "ignore" then
                    n = node.name
                    if not c[n] then
                        c[n] = 0
                    end
                    if c[n] > 1 then
                        break
                    end
                    c[n] = c[n] + 1
                end
            end
        end
        if n then
            core.set_node(pos, {
                name = n
            })
        else
            core.set_node(pos, {
                name = "air"
            })
        end
        return false
    end

    local node = core.get_node_or_nil(pos)
    if not node then
        core.load_area(pos, pos)
        node = core.get_node_or_nil(pos)
    end
    local bn_name = node.name
    local match = match_deposit_overlap(bn_name)
    if match then
        b_name = match
    end

    core.add_node(pos, {
        name = "va_resources:" .. b_name .. "_with_metal" .. mass_type
    })
    local meta = core.get_meta(pos)
    meta:set_int("va_mass_amount", value * 100)

    for _, dir in pairs(dirs) do
        local d_pos = vector.add(pos, dir)
        local side = ""
        if dir.x == 1 and dir.z == 0 then
            side = "_1"
        elseif dir.x == -1 and dir.z == 0 then
            side = "_2"
        elseif dir.x == 0 and dir.z == 1 then
            side = "_3"
        elseif dir.x == 0 and dir.z == -1 then
            side = "_4"
        elseif dir.x == 1 and dir.z == 1 then
            side = "_5"
        elseif dir.x == -1 and dir.z == -1 then
            side = "_6"
        elseif dir.x == 1 and dir.z == -1 then
            side = "_7"
        elseif dir.x == -1 and dir.z == 1 then
            side = "_8"
        end

        if side then
            local n = core.get_node_or_nil(d_pos)
            if n then
                local n_name = n.name
                local _match = match_deposit_overlap(n_name)
                if _match then
                    b_name = _match
                end
                core.add_node(d_pos, {
                    name = "va_resources:" .. b_name .. "_near_metal" .. mass_type .. side
                })
                local _meta = core.get_meta(d_pos)
                _meta:set_int("va_mass_amount", value * 100)
            end
        end
    end
    return true
end

local function show_indicator(pos)
    local node = core.get_node(pos)
    local g = core.get_item_group(node.name, "va_mass")
    if g ~= 3 then
        return
    end
    local i_pos = vector.add(pos, {
        x = 0,
        y = 0.505,
        z = 0
    })
    local found = false
    local objs = core.get_objects_inside_radius(i_pos, 0.1)
    for _, obj in pairs(objs) do
        if obj:get_luaentity() then
            local ent = obj:get_luaentity()
            if ent.name == "va_resources:resource_mass_indicator" then
                found = true
            end
        end
    end
    if not found then
        va_resources.add_mass_indicator(i_pos)
    end
end

core.register_abm({
    label = "va mass indicator abm",
    nodenames = {"group:va_mass"},
    interval = 3,
    chance = 1,
    min_y = -1000,
    max_y = 1000,
    action = function(pos, node, active_object_count, active_object_count_wider)
        show_indicator(pos)
    end
})

local function register_resource_mass()

    local mass_deposits_a = deepcopy(mass_deposits)
    for _, d in pairs(mass_deposits_a) do
        -- d.mass_type = "a"
        register_mass_deposit(d)
    end

    local mass_deposits_s = deepcopy(mass_deposits)
    for _, d in pairs(mass_deposits_s) do
        d.mass_type = "s"
        register_mass_deposit(d)
    end

    local mass_deposits_c = deepcopy(mass_deposits)
    for _, d in pairs(mass_deposits_c) do
        d.mass_type = "c"
        register_mass_deposit(d)
    end

    local mass_deposits_gold = deepcopy(mass_deposits)
    for _, d in pairs(mass_deposits_gold) do
        d.mass_type = "gold"
        register_mass_deposit(d)
    end

end

register_resource_mass()
