
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
            target = user:get_pos()
        elseif pointed_thing.type == "node" then
            target = pointed_thing.above
        elseif pointed_thing.type == "object" then
           local entity = pointed_thing.ref
           if entity then
               target = entity:get_pos()
           end
        end
        if target == nil then
            core.chat_send_player(player_name, "Error: No target selected.")
            return
        end
        for _, unit in pairs(va_commands.get_player_selected_units(player_name)) do
            if unit._owner_name == player_name then
                va_units.set_target(unit, target)
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



