core.register_node("va_structures:dummy_light_source_1", {
    description = "Dummy Light Source",
    drop = "",
    groups = {
        va_dummy_light_source = 1
    },
    paramtype = "light",
    is_ground_content = false,
    drawtype = "airlike",
    light_source = 13,
    sunlight_propagates = true,
    walkable = false,
    buildable_to = true,
    diggable = false,
    pointable = false,
    can_dig = function()
        return false
    end,
    on_dig = function()
    end,
    on_blast = function()
    end
})

core.register_node("va_structures:dummy_light_source_2", {
    description = "Dummy Light Source",
    drop = "",
    groups = {
        va_dummy_light_source = 1
    },
    paramtype = "light",
    is_ground_content = false,
    drawtype = "airlike",
    light_source = 11,
    sunlight_propagates = true,
    walkable = false,
    buildable_to = true,
    diggable = false,
    pointable = false,
    can_dig = function()
        return false
    end,
    on_dig = function()
    end,
    on_blast = function()
    end
})

core.register_abm({
    label = "va dummy light source cleanup",
    nodenames = {"group:va_dummy_light_source"},
    interval = 7,
    chance = 1,
    min_y = -10000,
    max_y = 10000,
    action = function(pos, node, active_object_count, active_object_count_wider)
        local meta = core.get_meta(pos)
        local last_update = tonumber(meta:get_string("last_update")) or 0
        if core.get_us_time() - last_update > 5 * 1000 * 1000 then
            core.remove_node(pos)
        end
    end
})
