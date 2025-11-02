local registrations = {{
    place_on = "default:sand",
    deco = "va_resources:sand_with_geo",
    replace = "sand"
}, {
    place_on = "default:desert_sand",
    deco = "va_resources:desert_sand_with_geo",
    replace = "desert_sand"
}, {
    place_on = "default:dirt",
    deco = "va_resources:dirt_with_geo",
    replace = "dirt"
}, {
    place_on = "default:dry_dirt",
    deco = "va_resources:dry_dirt_with_geo",
    replace = "dry_dirt"
}, {
    place_on = "default:gravel",
    deco = "va_resources:gravel_with_geo",
    replace = "gravel"
}, {
    place_on = "default:stone",
    deco = "va_resources:stone_with_geo",
    replace = "stone"
}, {
    place_on = "default:permafrost_with_moss",
    deco = "va_resources:moss_with_geo",
    replace = "moss"
}, {
    place_on = "default:dirt_with_grass",
    deco = "va_resources:grass_with_geo",
    replace = "grass"
}, {
    place_on = "default:dirt_with_snow",
    deco = "va_resources:dirt_snow_with_geo",
    replace = "dirt_snow"
}, {
    place_on = "default:permafrost_with_stones",
    deco = "va_resources:permafrost_with_geo",
    replace = "permafrost"
}, {
    place_on = "default:dirt_with_coniferous_litter",
    deco = "va_resources:coniferous_litter_with_geo",
    replace = "coniferous_litter"
}, {
    place_on = "default:dirt_with_rainforest_litter",
    deco = "va_resources:rainforest_litter_with_geo",
    replace = "rainforest_litter"
}, {
    place_on = "default:dry_dirt_with_dry_grass",
    deco = "va_resources:dry_dirt_with_grass_with_geo",
    replace = "dry_dirt_with_grass"
}, {
    place_on = "default:desert_sandstone",
    deco = "va_resources:desert_sandstone_with_geo",
    replace = "desert_sandstone"
}, {
    place_on = "default:desert_stone",
    deco = "va_resources:desert_stone_with_geo",
    replace = "desert_stone"
}, {
    place_on = "default:silver_sand",
    deco = "va_resources:silver_sand_with_geo",
    replace = "silver_sand"
}}

if minetest.get_modpath("badlands") then
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

if minetest.get_modpath("bakedclay") then
    table.insert(registrations, {
        place_on = "bakedclay:orange",
        deco = "va_resources:clay_orange_with_metal",
        replace = "clay_orange"
    })
end

if minetest.get_modpath("saltd") then
    table.insert(registrations, {
        place_on = "saltd:salt_sand",
        deco = "va_resources:salt_sand_with_metal",
        replace = "saltd_salt_sand"
    })
    table.insert(registrations, {
        place_on = "saltd:humid_salt_sand",
        deco = "va_resources:humid_salt_sand_with_metal",
        replace = "humid_salt_sand"
    })
    table.insert(registrations, {
        place_on = "saltd:barren",
        deco = "va_resources:barren_with_metal",
        replace = "barren"
    })
end

local function register_geo(def)

    core.register_decoration({
        name = def.deco,
        deco_type = "simple",
        place_on = {def.place_on},
        sidelen = 16,
        noise_params = {
			offset = 0.0000173,
			scale = 0.000001,
			spread = {x = 300, y = 200, z = 300},
			seed = 73,
			octaves = 2,
			persist = 0.28
        },
        y_max = 256,
        y_min = 1,
        decoration = def.deco,
        place_offset_y = -1,
        flags = "force_placement"
    })
end

local metals = {}

for _, def in pairs(registrations) do
    register_geo(def)
    local id = core.get_decoration_id(def.deco)
    metals[id] = def.replace
end

function split(s, delimiter)
    local result = {}
    -- Use gmatch to find all substrings that are not the delimiter
    for match in string.gmatch(s, "([^" .. delimiter .. "]+)") do
        table.insert(result, match)
    end
    return result
end

local geo_ids = {}
for id, m in pairs(metals) do
    table.insert(geo_ids, id)
end

core.set_gen_notify({
    decoration = true
}, geo_ids)

-- start nodetimers
core.register_on_generated(function(minp, maxp, blockseed)
    if maxp.y > 16 * 72 + 1 or minp.y < -(16 * 72 + 2) then
        return
    end
    if maxp.x > 4095 or minp.x < -4096 then
        return  
    end
    if maxp.z > 4095 or minp.z < -4096 then
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
                va_resources.add_geo_vent(p.pos, p.replace)
            end
        end
    end
end)
