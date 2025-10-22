va_commands = {}

local commands = {}

function va_commands.register_command(name, def)
    -- register the command item that will be used to execute the command
    commands[name] = def
    local item_name = "va_commands:" .. name
    core.register_craftitem(item_name, {
        description = def.description,
        inventory_image = "va_commands_" .. name .. ".png",
        on_use = function(itemstack, user, pointed_thing)
            core.chat_send_player(user:get_player_name(), name .. " command executed.")
            if def.execute then
                def.execute(user)
            end
        end
    })
end


function va_commands.get_command(name)
    return commands[name]
end
