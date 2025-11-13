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

core.register_on_mods_loaded(function()
    core.after(2, function()
        for i = 1, 14 do
            local name = "va_weapons:dummy_light_" .. i
            -- Scan all loaded mapblocks for this node
            for _, player in ipairs(core.get_connected_players()) do
                local pos = vector.round(player:get_pos())
                -- Scan a 32x32x32 area around each player (adjust as needed)
                for x = -16, 16 do
                    for y = -16, 16 do
                        for z = -16, 16 do
                            local p = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
                            local node = core.get_node_or_nil(p)
                            if node and node.name == name then
                                core.get_node_timer(p):start(1)
                            end
                        end
                    end
                end
            end
        end
    end)
end)