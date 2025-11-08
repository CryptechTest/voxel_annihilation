-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Solar Collector
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

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
        local light_level = core.get_node_light(pos_above)

        local last_index = s_obj._out_index
        local is_panel_close = s_obj._out_index == -1
        local is_panel_closed = s_obj._out_index <= 0
        local is_panel_open = s_obj._out_index == 1
        local is_panel_opened = s_obj._out_index == 2

        local recent_hit = false
        if core.get_us_time() - s_obj.last_hit < 13 * 1000 * 1000 then
            recent_hit = true
        end

        if light_level > 13 and not recent_hit then
            local gen = s_obj:get_data():get_energy_generate()
            local energy = net.energy
            if energy + gen <= net.energy_storage + 1 then
                net.energy = energy + gen
            else
                net.energy = net.energy_storage
            end
            net.energy_supply = net.energy_supply + gen
            if is_panel_closed then
                s_obj._out_index = 1 -- open
                is_panel_close = false
                is_panel_open = true
            end
        else
            if is_panel_opened then
                s_obj._out_index = -1 -- close
                is_panel_close = true
                is_panel_open = false
            end
        end

        if recent_hit then
            if is_panel_opened then
                s_obj._out_index = -1 -- close
                is_panel_close = true
                is_panel_open = false
            end
        end

        local is_panel_changed = s_obj._out_index ~= last_index

        if s_obj.entity_obj then
            local ent = s_obj.entity_obj:get_luaentity()
            if ent then
                if is_panel_changed then
                    if is_panel_open then
                        ent:_apply_animation("opening", "open", 1.425)
                        s_obj._out_index = 2 -- opened
                    elseif is_panel_close then
                        ent:_apply_animation("closing", "idle", 1.925)
                        s_obj._out_index = 0 -- closed
                    end
                end
            end
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_vox_solar_collector_2.gltf",
    textures = {"va_vox_solar_collector_2.png"},
    collisionbox = {-1.25, -0.5, -1.25, 1.25, 0.65, 1.25},
    max_health = 25,
    energy_generate = 2,
    energy_storage = 5,
    mass_cost = 15.5,
    energy_cost = 0,
    build_time = 260,
    vas_run = vas_run,
    entity_animations = {
        idle = {
            x = 0,
            y = 0
        },
        open = {
            x = 2.5,
            y = 2.5
        },
        opening = {
            x = 1,
            y = 2.5
        },
        closing = {
            x = 2.5,
            y = 4.5
        }
    }
}

-- Setup structure definition
def.name = "solar_collector"
def.desc = "Solar Collector"
def.size = {
    x = 1,
    y = 0,
    z = 1
}
def.category = "economy"
def.tier = 1
def.faction = "vox"

def.generator_type = true

-- Register a new Solar Collector
Structure.register(def)

