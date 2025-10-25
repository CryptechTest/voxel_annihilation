local function randFloat(min, max, precision)
    -- Generate a random floating point number between min and max
    local range = max - min
    local offset = range * math.random()
    local unrounded = min + offset

    -- Return unrounded number if precision isn't given
    if not precision then
        return unrounded
    end

    -- Round number to precision and return
    local powerOfTen = 10 ^ precision
    local n
    n = unrounded * powerOfTen
    n = n + 0.5
    n = math.floor(n)
    n = n / powerOfTen
    return n
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

    local t_name_b = "va_structures:" .. base_name .. "_with_metal"
    local t_name = "va_structures:" .. base_name .. "_near_metal"

    core.register_node(t_name_b, {
        description = ("Metal Ore" .. node_desc),
        tiles = {base_texture .. ".png^(" .. mass_texture .. ".png)"},
        groups = {
            cracky = 2,
            va_mass = 3
        },
        drop = "",

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

            va_structures.add_mass_deposit(pos, base_name)

            itemstack:take_item(1)

            return itemstack
        end
    })

    core.register_node(t_name .. "_1", {
        description = ("Metal Ore" .. node_desc),
        tiles = {base_texture .. ".png^((" .. mass_texture .. "_1.png^[opacity:240)^[transformFYR90])"},
        groups = {
            cracky = 2,
            va_mass = 2
        },
        drop = ""
    })
    core.register_node(t_name .. "_2", {
        description = ("Metal Ore" .. node_desc),
        tiles = {base_texture .. ".png^((" .. mass_texture .. "_1.png^[opacity:240)^[transformR90])"},
        groups = {
            cracky = 2,
            va_mass = 2
        },
        drop = ""
    })
    core.register_node(t_name .. "_3", {
        description = ("Metal Ore" .. node_desc),
        tiles = {base_texture .. ".png^((" .. mass_texture .. "_1.png^[opacity:240)^[transformFX])"},
        groups = {
            cracky = 2,
            va_mass = 2
        },
        drop = ""
    })
    core.register_node(t_name .. "_4", {
        description = ("Metal Ore" .. node_desc),
        tiles = {base_texture .. ".png^((" .. mass_texture .. "_1.png^[opacity:240)^[transformR180])"},
        groups = {
            cracky = 2,
            va_mass = 2
        },
        drop = ""
    })

    core.register_node(t_name .. "_5", {
        description = ("Metal Ore" .. node_desc),
        tiles = {base_texture .. ".png^((" .. mass_texture .. "_2.png^[opacity:240))"},
        groups = {
            cracky = 2,
            va_mass = 1
        },
        drop = ""
    })
    core.register_node(t_name .. "_6", {
        description = ("Metal Ore" .. node_desc),
        tiles = {base_texture .. ".png^((" .. mass_texture .. "_2.png^[opacity:240)^[transformR180])"},
        groups = {
            cracky = 2,
            va_mass = 1
        },
        drop = ""
    })
    core.register_node(t_name .. "_7", {
        description = ("Metal Ore" .. node_desc),
        tiles = {base_texture .. ".png^((" .. mass_texture .. "_2.png^[opacity:240)^[transformFY])"},
        groups = {
            cracky = 2,
            va_mass = 1
        },
        drop = ""
    })
    core.register_node(t_name .. "_8", {
        description = ("Metal Ore" .. node_desc),
        tiles = {base_texture .. ".png^((" .. mass_texture .. "_2.png^[opacity:240)^[transformR90])"},
        groups = {
            cracky = 2,
            va_mass = 1
        },
        drop = ""
    })
end

local deposit_overlaps = {{
    check = "default:dirt_with_grass",
    replace = "grass"
}, {
    check = "default:dry_dirt_with_dry_grass",
    replace = "dry_grass"
}, {
    check = "default:dirt",
    replace = "dirt"
}, {
    check = "default:dirt_with_snow",
    replace = "dirt_snow"
}, {
    check = "default:sand",
    replace = "sand"
}, {
    check = "default:desert_sand",
    replace = "desert_sand"
}, {
    check = "default:gravel",
    replace = "gravel"
}, {
    check = "default:stone",
    replace = "stone"
}, {
    check = "default:desert_stone",
    replace = "desert_stone"
}, {
    check = "default:desert_sandstone",
    replace = "desert_sandstone"
}, {
    check = "default:silver_sand",
    replace = "silver_sand"
}, {
    check = "default:permafrost",
    replace = "permafrost"
}, {
    check = "default:moss",
    replace = "moss"
}, {
    check = "default:dirt_with_coniferous_litter",
    replace = "coniferous_litter"
}, {
    check = "default:dirt_with_rainforest_litter",
    replace = "rainforest_litter"
}}

local function match_deposit_overlap(name)
    for _, o in pairs(deposit_overlaps) do
        if o.check == name then
            return o.replace
        end
    end
    return nil
end

local function match_deposit_check(name)
    for _, o in pairs(deposit_overlaps) do
        if o.replace == name then
            return o.check
        end
    end
    return nil
end

local mass_deposits = {{
    base_name = "grass",
    node_desc = "Grass",
    base_texture = "default_grass"
}, {
    base_name = "dry_grass",
    node_desc = "Dry Grass",
    base_texture = "default_dry_grass"
}, {
    base_name = "dirt_snow",
    node_desc = "Snow",
    base_texture = "default_snow"
}, {
    base_name = "dirt",
    node_desc = "Dirt",
    base_texture = "default_dirt"
}, {
    base_name = "gravel",
    node_desc = "Gravel",
    base_texture = "default_gravel"
}, {
    base_name = "stone",
    node_desc = "Stone",
    base_texture = "default_stone"
}, {
    base_name = "desert_stone",
    node_desc = "Desert Stone",
    base_texture = "default_desert_stone"
}, {
    base_name = "desert_sandstone",
    node_desc = "Desert Sandstone",
    base_texture = "default_desert_sandstone"
}, {
    base_name = "sand",
    node_desc = "Sand",
    base_texture = "default_sand"
}, {
    base_name = "desert_sand",
    node_desc = "Desert Sand",
    base_texture = "default_desert_sand"
}, {
    base_name = "silver_sand",
    node_desc = "Silver Sand",
    base_texture = "default_silver_sand"
}, {
    base_name = "permafrost",
    node_desc = "Permaforst",
    base_texture = "default_permafrost"
}, {
    base_name = "moss",
    node_desc = "Moss",
    base_texture = "default_moss"
}, {
    base_name = "coniferous_litter",
    node_desc = "Coniferous Litter",
    base_texture = "default_coniferous_litter"
}, {
    base_name = "rainforest_litter",
    node_desc = "Rainforest Litter",
    base_texture = "default_rainforest_litter"
}}

local groups = {"cracky", "crumbly", "choppy", "soil", "sand"}

function va_structures.add_mass_deposit(pos, b_name, value)
    if b_name == nil then
        b_name = "grass"
    end
    if value == nil then
        value = randFloat(0.7, 3.2)
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
        local g = core.get_item_group(n_name, 'va_mass')
        if g > 0 and g < 3 then
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
        local nn = match_deposit_check(b_name)
        core.set_node(pos, {
            name = nn
        })
        return
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
        name = "va_structures:" .. b_name .. "_with_metal"
    })
    local meta = core.get_meta(pos)
    meta:set_int("va_mass_amount", value * 10)

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
                name = "va_structures:" .. b_name .. "_near_metal" .. side
            })
            local meta = core.get_meta(d_pos)
            meta:set_int("va_mass_amount", value * 10)
        end
    end
end

local function show_indicator(pos)
    local node = core.get_node(pos)
    local g = core.get_item_group(node.name, "va_mass")
    if g ~= 3 then
        return
    end
    local i_pos = vector.add(pos, {
        x = 0,
        y = 0.55,
        z = 0
    })
    local found = false
    local objs = minetest.get_objects_inside_radius(i_pos, 0.1)
    for _, obj in pairs(objs) do
        if obj:get_luaentity() then
            local ent = obj:get_luaentity()
            if ent.name == "va_structures:resource_mass_indicator" then
                found = true
            end
        end
    end
    if not found then
        va_structures.add_resource_indicator(i_pos)
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

    for _, d in pairs(mass_deposits) do
        register_mass_deposit(d)
    end

end

return register_resource_mass
