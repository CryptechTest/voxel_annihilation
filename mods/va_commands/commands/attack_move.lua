
va_commands.register_command("attack_move", {
    description = "Attack Move",
    range = 128,
    execute_primary = function(itemstack, user, pointed_thing)
        if user == nil then
            core.chat_send_player(user:get_player_name(), "Error: User is nil.")
            return
        end
        local player_name = user:get_player_name()
        if pointed_thing.type == "nothing" then
        elseif pointed_thing.type == "node" then            
        elseif pointed_thing.type == "object" then
        end
        core.chat_send_player(player_name, "Immediate attack move command.")
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
        core.chat_send_player(player_name, "Queued attack move command.")
    end,
})



