for i = 1, 14 do
    core.register_node("va_weapons:dummy_light_" .. i, {
        description = "Dummy Light Node",
        drawtype = "airlike",
        paramtype = "light",
        sunlight_propagates = true,
        tiles = {""},
        light_source = i,
        groups = {not_in_creative_inventory=1, dig_immediate=3},
        walkable = false,
        pointable = false,
        diggable = false,
        buildable_to = false,
        drop = "",
        on_construct = function(pos)
            core.get_node_timer(pos):start(1) -- Remove after 1 second
        end,
        on_timer = function(pos)
            core.remove_node(pos)
        end,
    })
    
end