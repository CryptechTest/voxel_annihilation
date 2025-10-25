
va_commands.register_command("move", {
    description = "Move",
    range = 128,
    execute_primary = function(itemstack, user, pointed_thing)
        if user == nil then
            core.chat_send_player(user:get_player_name(), "Error: User is nil.")
            return
        end
        local player_name = user:get_player_name()
        local target = nil
        if pointed_thing.type == "nothing" then
            --get the ground under the player
            local player_pos = user:get_pos()
            for i = 0, 128 do
                local node = core.get_node({x = player_pos.x, y = player_pos.y - i, z = player_pos.z})
                local def = node and core.registered_nodes[node.name]
                if def and def.walkable then
                    target = {x = player_pos.x, y = player_pos.y - i + 1, z = player_pos.z}
                    break
                end
            end
        elseif pointed_thing.type == "node" then
            local node = core.get_node(pointed_thing.under)
            if node and core.registered_nodes[node.name].walkable then
                target = pointed_thing.above
            else
                target = pointed_thing.under
            end
        elseif pointed_thing.type == "object" then
           local entity = pointed_thing.ref
           if entity then
               local epos = entity:get_pos()        
               local found = false
               local search_pos = {x = epos.x, y = epos.y, z = epos.z}
               for i = 0, 10 do
                   local node = core.get_node({x = search_pos.x, y = search_pos.y - i, z = search_pos.z})
                   local def = node and core.registered_nodes[node.name]
                   if def and def.walkable then
                       target = {x = search_pos.x, y = search_pos.y - i + 1, z = search_pos.z}
                       found = true
                       break
                   end
               end
               if not found then
                   target = epos -- fallback to entity position
               end
            else
               core.chat_send_player(player_name, "Error: Target entity is nil.")
           end
        end
        if target == nil then
            core.chat_send_player(player_name, "Error: No target selected.")
            return                
        end
        
        for _, unit in pairs(va_commands.get_player_selected_units(player_name)) do
            if unit._owner_name == player_name and unit.object and target then
                local upos = unit.object:get_pos()
                if upos and upos.x and upos.y and upos.z then
                    local distance = vector.distance(upos, target)
                    if distance > 1024 then
                        core.chat_send_player(player_name, "Error: Target is too far away.")
                    else
                        va_units.set_target(unit, target)
                        core.chat_send_player(player_name, "Targeting position: " .. core.pos_to_string(target))
                    end
                else
                    core.chat_send_player(player_name, "Error: Unit position is invalid.")
                end
            end
        end
    end,
    execute_secondary = function(itemstack, user, pointed_thing)
        if user == nil then
            core.chat_send_player(user:get_player_name(), "Error: User is nil.")
            return
        end
        local player_name = user:get_player_name()
        if pointed_thing.type == "nothing" then
        elseif pointed_thing.type == "node" then
        elseif pointed_thing.type == "object" then
        end
        core.chat_send_player(player_name, "Queued move command.")
    end,
})



