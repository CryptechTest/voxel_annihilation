-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Lamp
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local lamp_dirs_1 = {{ -- along x beside
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
}, { -- node on top
    x = 0,
    y = 0.5,
    z = 0
}}

local lamp_dirs_2 = {{ -- along x beside
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
}}

local function place_lighting(b_pos, is_on)

    local  function place_lights(dirs, offset)
        for _, d in pairs(dirs) do
            local node_name = "va_structures:dummy_light_source_1"
            if offset >= 4 then
                node_name = "va_structures:dummy_light_source_2"
            end
            local dir = vector.multiply(d, offset)
            local pos = vector.add(b_pos, dir)
            pos = vector.add(pos, {
                x = 0,
                y = 2,
                z = 0
            })
            if is_on then
                if core.get_node(pos).name == "air" then
                    core.set_node(pos, {
                        name = node_name
                    })
                end
                if core.get_node(pos).name == node_name then
                    local meta = core.get_meta(pos)
                    meta:set_string("last_update", tostring(core.get_us_time()))
                end
            else
                if core.get_node(pos).name == node_name then
                    core.remove_node(pos)
                end
            end
        end
    end

    local offsets = {2,4}
    for _, offset in pairs(offsets) do
        place_lights(lamp_dirs_1, offset)
    end
    place_lights(lamp_dirs_2, 5)
end

local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then
        local cost = s_obj:get_data():get_energy_consume()
        local energy = net.energy
        if energy - cost >= 0 then
            net.energy = energy - cost
            place_lighting(pos, true)
        else
            place_lighting(pos, false)
        end
        net.energy_demand = net.energy_demand + cost
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_vox_lamp_tower_1.gltf",
    textures = {"va_vox_lamp_tower_1.png"},
    collisionbox = {-0.65, -0.75, -0.65, 0.65, 1.7, 0.65},
    max_health = 10,
    mass_cost = 1.2,
    energy_cost = 7,
    build_time = 100,
    energy_consume = 0.1,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "lamp_tower"
def.desc = "Lamp Tower"
def.size = {
    x = 1,
    y = 2,
    z = 1
}
def.category = "utility"
def.tier = 1
def.faction = "vox"

-- Register a new lamp
Structure.register(def)

