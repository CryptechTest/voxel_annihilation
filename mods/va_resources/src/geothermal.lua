local deepcopy = va_structures.util.deepcopy

local geo_vents = {{
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

if minetest.get_modpath("badlands") then
    table.insert(geo_vents, {
        check = "badlands:red_sand",
        base_name = "red_sand",
        node_desc = "Red Sand",
        base_texture = "default_sand.png^[colorize:sienna:175^[colorize:red:40",
        tiles = {"default_sand.png^[colorize:sienna:175^[colorize:red:40",
                 "default_sand.png^[colorize:sienna:175^[colorize:red:40"}
    })
    table.insert(geo_vents, {
        check = "badlands:red_sandstone",
        base_name = "red_sandstone",
        node_desc = "Red Sandstone",
        base_texture = "default_sandstone.png^[colorize:sienna:175^[colorize:red:40",
        tiles = {"default_sandstone.png^[colorize:sienna:175^[colorize:red:40",
                 "default_sandstone.png^[colorize:sienna:175^[colorize:red:40"}
    })
end

if minetest.get_modpath("bakedclay") then
    table.insert(geo_vents, {
        check = "bakedclay:natural",
        base_name = "clay_natural",
        node_desc = "Natural Clay",
        base_texture = "baked_clay_natural.png",
        tiles = {"baked_clay_natural.png", "baked_clay_natural.png"}
    })
end

if minetest.get_modpath("saltd") then
    table.insert(geo_vents, {
        check = "saltd:salt_sand",
        base_name = "salt_sand",
        node_desc = "Salt Sand",
        use_hd_texture = true,
        base_texture = "saltd_salt_sand.png",
        tiles = {"saltd_salt_sand.png", "saltd_salt_sand.png"}
    })
    table.insert(geo_vents, {
        check = "saltd:humid_salt_sand",
        base_name = "humid_salt_sand",
        node_desc = "Humid Salt Sand",
        use_hd_texture = true,
        base_texture = "saltd_humid_salt_sand.png",
        tiles = {"saltd_humid_salt_sand.png", "saltd_humid_salt_sand.png"}
    })
    table.insert(geo_vents, {
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

local is_player_near = function(pos)
    local objs = core.get_objects_inside_radius(pos, 64)
    for _, obj in pairs(objs) do
        if obj:is_player() then
            return true;
        end
    end
    return false;
end

local function spawn_particles(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, lvl, time, amount)
    if (not is_player_near(pos)) then
        return;
    end
    local animation = {
        type = "vertical_frames",
        aspect_w = 16,
        aspect_h = 16,
        length = (time or 6) + 1
    }
    local texture = {
        name = "va_vapor_anim.png",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.1},
        scale_tween = {{
            x = 0.5,
            y = 1.0
        }, {
            x = 8.8,
            y = 7.1
        }}
    }

    local prt = {
        texture = texture,
        vel = 0.28,
        time = (time or 6),
        size = 0.75 + (lvl or 1),
        glow = 3,
        cols = false
    }

    local v = vector.new()
    v.x = 0.0001
    v.y = 0.001
    v.z = 0.0001
    if math.random(0, 10) > 1 then
        local rx = dir_x * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        local ry = dir_y * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        local rz = dir_z * prt.vel * -math.random(0.3 * 100, 0.7 * 100) / 100
        minetest.add_particlespawner({
            amount = amount,
            pos = pos,
            minpos = {
                x = -0.1,
                y = 0.1,
                z = -0.1
            },
            maxpos = {
                x = 0.1,
                y = 0.25,
                z = 0.1
            },
            minvel = {
                x = rx * 0.8,
                y = (ry * 0.8) + 1.37,
                z = rz * 0.8
            },
            maxvel = {
                x = rx,
                y = ry + 1.25,
                z = rz
            },
            minacc = {
                x = acl_x * 0.7,
                y = acl_y * 0.8,
                z = acl_z * 0.7
            },
            maxacc = {
                x = acl_x,
                y = acl_y + math.random(-0.008, 0),
                z = acl_z
            },
            time = (prt.time + 3) * 0.75,
            minexptime = prt.time - math.random(0, 2),
            maxexptime = prt.time + math.random(0, 1),
            minsize = ((math.random(0.77, 0.93)) * 2 + 1.6) * prt.size,
            maxsize = ((math.random(0.77, 0.93)) * 2 + 1.6) * prt.size,
            collisiondetection = prt.cols,
            vertical = false,
            texture = texture,
            animation = animation,
            glow = prt.glow
        })
    end
end

local function register_geo_vent(def)

    local base_name = def.base_name or "grass"
    local node_desc = " on " .. (def.node_desc or "Grass")
    local base_texture = def.base_texture or "default_grass"
    local geo_texture = def.geo_texture or "va_geo_vent"

    local t_m = def.geo_type or "a"
    local tt_name = def.geo_type and "_" .. t_m or ""

    local t_name_b = "va_resources:" .. base_name .. "_with_geo" .. tt_name
    local t_name = "va_resources:" .. base_name .. "_near_geo" .. tt_name

    local hd = ""
    if def.use_hd_texture then
        hd = "_hd"
    end

    local tiles = def.tiles or {}

    local tiles_0 = deepcopy(tiles)
    tiles_0[1] = base_texture .. "^default_stones" .. hd .. ".png^(" .. geo_texture .. "_" .. t_m .. "_1" .. hd .. ".png)"

    local tiles_1 = deepcopy(tiles)
    tiles_1[1] =
        base_texture .. "^((default_stones_side" .. hd .. ".png^[transformFY])^(" .. geo_texture .. "_" .. t_m .. "_2" .. hd ..
            ".png)^[transformFYR90])"

    local tiles_2 = deepcopy(tiles)
    tiles_2[1] = base_texture .. "^((default_stones_side" .. hd .. ".png^[transformR180])^(" .. geo_texture .. "_" .. t_m ..
                     "_2" .. hd .. ".png)^[transformR90])"

    local tiles_3 = deepcopy(tiles)
    tiles_3[1] =
        base_texture .. "^((default_stones_side" .. hd .. ".png^[transformFY])^(" .. geo_texture .. "_" .. t_m .. "_2" .. hd ..
            ".png)^[transformFX])"

    local tiles_4 = deepcopy(tiles)
    tiles_4[1] = base_texture .. "^((default_stones_side" .. hd .. ".png^[transformR180])^(" .. geo_texture .. "_" .. t_m ..
                     "_2" .. hd .. ".png)^[transformR180])"

    local tiles_5 = deepcopy(tiles)
    tiles_5[1] = base_texture .. "^((" .. geo_texture .. "_" .. t_m .. "_3" .. hd .. ".png))"

    local tiles_6 = deepcopy(tiles)
    tiles_6[1] = base_texture .. "^((" .. geo_texture .. "_" .. t_m .. "_3" .. hd .. ".png)^[transformR180])"

    local tiles_7 = deepcopy(tiles)
    tiles_7[1] = base_texture .. "^((" .. geo_texture .. "_" .. t_m .. "_3" .. hd .. ".png)^[transformFY])"

    local tiles_8 = deepcopy(tiles)
    tiles_8[1] = base_texture .. "^((" .. geo_texture .. "_" .. t_m .. "_3" .. hd .. ".png)^[transformR90])"

    -- center node
    core.register_node(t_name_b, {
        description = ("Geothermal Vent" .. node_desc),
        tiles = tiles_0,
        groups = {
            cracky = 2,
            va_geo_vent = 3
        },
        drop = "",
        paramtype = "light",
        light_source = 3,

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

            if def.geo_type then
                if va_resources.add_geo_vent(pos, base_name, nil, def.geo_type) then
                    itemstack:take_item(1)
                end
            else
                if va_resources.add_geo_vent(pos, base_name) then
                    itemstack:take_item(1)
                end
            end

            return itemstack
        end
    })

    -- edge/side nodes
    core.register_node(t_name .. "_1", {
        description = ("Geothermal Vent" .. node_desc),
        tiles = tiles_1,
        groups = {
            cracky = 2,
            va_geo_vent = 2
        },
        drop = ""
    })
    core.register_node(t_name .. "_2", {
        description = ("Geothermal Vent" .. node_desc),
        tiles = tiles_2,
        groups = {
            cracky = 2,
            va_geo_vent = 2
        },
        drop = ""
    })
    core.register_node(t_name .. "_3", {
        description = ("Geothermal Vent" .. node_desc),
        tiles = tiles_3,
        groups = {
            cracky = 2,
            va_geo_vent = 2
        },
        drop = ""
    })
    core.register_node(t_name .. "_4", {
        description = ("Geothermal Vent" .. node_desc),
        tiles = tiles_4,
        groups = {
            cracky = 2,
            va_geo_vent = 2
        },
        drop = ""
    })

    core.register_node(t_name .. "_5", {
        description = ("Geothermal Vent" .. node_desc),
        tiles = tiles_5,
        groups = {
            cracky = 2,
            va_geo_vent = 1
        },
        drop = ""
    })
    core.register_node(t_name .. "_6", {
        description = ("Geothermal Vent" .. node_desc),
        tiles = tiles_6,
        groups = {
            cracky = 2,
            va_geo_vent = 1
        },
        drop = ""
    })
    core.register_node(t_name .. "_7", {
        description = ("Geothermal Vent" .. node_desc),
        tiles = tiles_7,
        groups = {
            cracky = 2,
            va_geo_vent = 1
        },
        drop = ""
    })
    core.register_node(t_name .. "_8", {
        description = ("Geothermal Vent" .. node_desc),
        tiles = tiles_8,
        groups = {
            cracky = 2,
            va_geo_vent = 1
        },
        drop = ""
    })
end

local function match_deposit_overlap(name)
    for _, o in pairs(geo_vents) do
        if o.check == name then
            return o.base_name
        end
    end
    return nil
end

local function match_deposit_check(name)
    for _, o in pairs(geo_vents) do
        if o.base_name == name then
            return o.check
        end
    end
    return nil
end

local groups = {"cracky", "crumbly", "choppy", "soil", "sand"}

function va_resources.add_geo_vent(pos, b_name, value, geo_type)
    if b_name == nil then
        b_name = "grass"
    end
    if value == nil then
        value = va_structures.util.randFloat(0.90, 1.10)
    end
    if geo_type == nil and value <= 0.14 then
        geo_type = "s"
    end
    if geo_type == nil then
        geo_type = ""
    else
        geo_type = "_" .. geo_type
    end

    local found = false
    local near_air = false
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
    if found or near_air then
        local n = nil
        local c = {}
        for x = -1, 1 do
            for z = -1, 1 do
                local p = vector.add(pos, {
                    x = x,
                    y = 0,
                    z = z
                })
                local node = core.get_node(p)
                if node.name ~= "air" and node.name ~= "ignore" then
                    n = node.name
                    if not c[n] then
                        c[n] = 0
                    end
                    if c[n] > 2 then
                        break
                    end
                    c[n] = c[n] + 1
                end
            end
        end
        core.set_node(pos, {
            name = n
        })
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
        name = "va_resources:" .. b_name .. "_with_geo" .. geo_type
    })
    local meta = core.get_meta(pos)
    meta:set_int("va_geo_vent_amount", value * 100)

    for _, dir in pairs(dirs) do
        local d_pos = vector.add(pos, dir)
        local side = "_1"
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

        local node = core.get_node_or_nil(d_pos)
        if node then
            local n_name = node.name
            local match = match_deposit_overlap(n_name)
            if match then
                b_name = match
            end

            core.add_node(d_pos, {
                name = "va_resources:" .. b_name .. "_near_geo" .. geo_type .. side
            })
            local meta = core.get_meta(d_pos)
            meta:set_int("va_geo_vent_amount", value * 100)
        end
    end
    return true
end

local function show_indicator(pos)
    local node = core.get_node(pos)
    local g = core.get_item_group(node.name, "va_geo_vent")
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
            if ent.name == "va_resources:resource_geo_indicator" then
                found = true
            end
        end
    end
    if not found then
        va_resources.add_geo_indicator(i_pos)
    end
end

core.register_abm({
    label = "va mass indicator abm",
    nodenames = {"group:va_geo_vent"},
    interval = 3,
    chance = 1,
    min_y = -1000,
    max_y = 1000,
    action = function(pos, node, active_object_count, active_object_count_wider)

        local node = core.get_node(pos)
        local g = core.get_item_group(node.name, "va_geo_vent")
        if g == 3 then
            show_indicator(pos)
            local p_pos = vector.add(pos, {
                x = 0,
                y = 0.55,
                z = 0
            })
            if core.get_node(p_pos).name == "air" then
                local vel = va_resources.get_env_wind_vel().velocity
                local dir = math.rad(va_resources.get_env_wind_vel().direction)
                local dir_x = math.sin(dir) * vel
                local dir_z = math.cos(dir) * vel
                spawn_particles(p_pos, dir_x, -1, dir_z, 0.88 * dir_x, -0.167, 0.88 * dir_z, 1, 6, 57)
            end
        end
    end
})

local function register_resource_geothermal()

    local mass_deposits_a = deepcopy(geo_vents)
    for _, d in pairs(mass_deposits_a) do
        register_geo_vent(d)
    end

end

register_resource_geothermal()
