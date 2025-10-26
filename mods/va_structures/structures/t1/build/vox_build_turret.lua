-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Build Turret
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local find_build_target = function(pos, s)
    local dist = s:get_data().construction_distance
    local objs = minetest.get_objects_inside_radius(pos, dist + 0.55)
    for _, obj in pairs(objs) do
        local o_pos = obj:get_pos()
        if obj:get_luaentity() then
            local ent = obj:get_luaentity()
            local structure = va_structures.get_active_structure(o_pos)
            if structure and not s:equals(structure) then
                if structure.is_constructed == false then
                    s._build_target = structure
                    core.log("found work for build_turret")
                    break;
                end
            end
        end
    end
end

local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then
        local pos_above = vector.add(pos, {
            x = 0,
            y = 1,
            z = 0
        })

        if s_obj._build_target == nil then
            -- find build target
            find_build_target(pos, s_obj)
        end

        if s_obj._build_target then
            -- do build...
            local b_power = s_obj:get_data():get_build_power()
            s_obj._build_target:construct_with_power(net, b_power, s_obj)
            if s_obj._build_target.is_constructed then
                s_obj._build_target = nil
            end
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_build_turret_1.gltf",
    textures = {"va_vox_build_turret_1.png"},
    collisionbox = {-0.75, -0.75, -0.75, 0.75, 0.75, 0.75},
    max_health = 17,
    energy_generate = 0,
    energy_storage = 0, 
    mass_cost = 20,
    energy_cost = 200,
    build_time = 300,
    build_power = 8,
    construction_distance = 16,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "build_turret"
def.desc = "Build Turret"
def.size = {
    x = 1,
    y = 0,
    z = 1
}
def.category = "build"
def.tier = 1
def.faction = "vox"

-- Create a new Build Turret
local build_turret = Structure.register(def)
