local registrations = {{
    place_on = "default:sand",
    deco = "va_structures:sand_with_metal",
    replace = "sand"
}, {
    place_on = "default:desert_sand",
    deco = "va_structures:desert_sand_with_metal",
    replace = "desert_sand"
}, {
    place_on = "default:dirt",
    deco = "va_structures:dirt_with_metal",
    replace = "dirt"
}, {
    place_on = "default:gravel",
    deco = "va_structures:gravel_with_metal",
    replace = "gravel"
}, {
    place_on = "default:stone",
    deco = "va_structures:stone_with_metal",
    replace = "stone"
}, {
    place_on = "default:permafrost_with_moss",
    deco = "va_structures:moss_with_metal",
    replace = "moss"
}, {
    place_on = "default:dirt_with_grass",
    deco = "va_structures:grass_with_metal",
    replace = "grass"
}, {
    place_on = "default:dirt_with_snow",
    deco = "va_structures:dirt_snow_with_metal",
    replace = "dirt_snow"
}, {
    place_on = "default:permafrost_with_stones",
    deco = "va_structures:permafrost_with_metal",
    replace = "permafrost"
}, {
    place_on = "default:dirt_with_coniferous_litter",
    deco = "va_structures:coniferous_litter_with_metal",
    replace = "coniferous_litter"
}, {
    place_on = "default:dirt_with_rainforest_litter",
    deco = "va_structures:rainforest_litter_with_metal",
    replace = "rainforest_litter"
}, {
    place_on = "default:dry_dirt_with_dry_grass",
    deco = "va_structures:dry_dirt_with_grass_with_metal",
    replace = "dry_dirt_with_grass"
}, {
    place_on = "default:desert_sandstone",
    deco = "va_structures:desert_sandstone_with_metal",
    replace = "desert_sandstone"
}, {
    place_on = "default:desert_sstone",
    deco = "va_structures:desert_stone_with_metal",
    replace = "desert_stone"
}, {
    place_on = "default:silver_sand",
    deco = "va_structures:silver_sand_with_metal",
    replace = "silver_sand"
}}

local function register_mass(def)

    core.register_decoration({
        name = def.deco,
        deco_type = "simple",
        place_on = {def.place_on},
        sidelen = 16,
        noise_params = {
			offset = 0.0012,
			scale = 0.0007,
			spread = {x = 250, y = 250, z = 250},
			seed = 21,
			octaves = 3,
			persist = 0.64
        },
        y_max = 128,
        y_min = -32,
        decoration = def.deco,
        place_offset_y = -1,
        flags = "force_placement"
        -- param2 = 4,
    })
end

local metals = {}

for _, def in pairs(registrations) do
    register_mass(def)
    local id = minetest.get_decoration_id(def.deco)
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

local metal_ids = {}
for id, m in pairs(metals) do
    table.insert(metal_ids, id)
end

minetest.set_gen_notify({
    decoration = true
}, metal_ids)

-- start nodetimers
minetest.register_on_generated(function(minp, maxp, blockseed)
    local gennotify = minetest.get_mapgen_object("gennotify")

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
                va_structures.add_mass_deposit(p.pos, p.replace)
            end
        end
    end
end)
