va_commands.register_command("build", {
    description = "Build",
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
        -- core.chat_send_player(player_name, "Immediate build command.")

        local selected_unit_id = {}
        local selected_unit_name = ""
        local selected_units = va_commands.get_player_selected_units(player_name)
        local found = false
        for _, selected_entity in ipairs(selected_units) do
            -- TODO: constructor type on unit maybe???
            if selected_entity.name == "va_units:vox_constructor" then
                found = true
                selected_unit_id = selected_entity._id
                selected_unit_name = selected_entity.name
                break
            end
        end
        if found then
            va_structures.show_construction_menu(player_name, selected_unit_name, selected_unit_id)
        else
            core.chat_send_player(player_name, "No constructor selected.")
        end

    end,
    execute_secondary = function(itemstack, user, pointed_thing)
        if user == nil then
            core.chat_send_player(user:get_player_name(), "Error: User is nil.")
            return
        end
        local player_name = user:get_player_name()
        local structure = nil
        if pointed_thing.type == "nothing" then
        elseif pointed_thing.type == "node" then
            structure = va_structures.get_active_structure(pointed_thing.above)
            if not structure then
                structure = va_structures.get_active_structure(pointed_thing.under)
            end
        elseif pointed_thing.type == "object" then
            local entity = pointed_thing.ref
            if entity then
                structure = va_structures.get_active_structure(entity:get_pos())
            end
        end
        -- core.chat_send_player(player_name, "Queued build command.")

        local selected_unit_id = {}
        local selected_unit_name = ""
        local selected_units = va_commands.get_player_selected_units(player_name)
        local found = false
        for _, selected_entity in ipairs(selected_units) do
            -- TODO: constructor type on unit maybe???
            if selected_entity.name == "va_units:vox_constructor" then
                found = true
                selected_unit_id = selected_entity._id
                selected_unit_name = selected_entity.name
                break
            end
        end
        if found then
            local unit = va_units.get_unit_by_id(selected_unit_id)
            if structure and unit then
                unit:_command_queue_abort()
                unit:_command_queue_add(structure)
            else
                va_structures.show_construction_menu(player_name, selected_unit_name, selected_unit_id)
            end
        else
            core.chat_send_player(player_name, "No constructor selected.")
        end
    end
})

