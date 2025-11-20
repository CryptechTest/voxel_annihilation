va_commands.register_command("build", {
    description = "Build",
    range = 128,
    execute_primary = function(itemstack, user, pointed_thing)
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

        local selected_unit_ids = {}
        local selected_unit_name = ""
        local selected_units = va_commands.get_player_selected_units(player_name)
        local found = false
        for _, selected_entity in ipairs(selected_units) do
            if selected_entity._can_build then
                found = true
                table.insert(selected_unit_ids, selected_entity._id)
                selected_unit_name = selected_entity.name
                break
            end
        end
        if found then
            if structure and #selected_unit_ids > 0 then
                core.chat_send_player(player_name, "Immediate build command.")
                for _, unit_id in pairs(selected_unit_ids) do
                    local unit = va_units.get_unit_by_id(unit_id)
                    if unit then
                        if unit._command_queue_abort then
                            unit:_command_queue_abort()
                        end
                        if unit._command_queue_add then
                            unit:_command_queue_add(structure)
                        end
                    end
                end
            else
                va_structures.show_construction_menu(player_name, selected_unit_name, selected_unit_ids[1])
            end
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
        local ghost = nil
        if pointed_thing.type == "nothing" then
        elseif pointed_thing.type == "node" then
            structure = va_structures.get_active_structure(pointed_thing.above)
            if not structure then
                structure = va_structures.get_active_structure(pointed_thing.under)
            end
            ghost = va_structures.get_unit_command_queue_from_pos(pointed_thing.above)
            if not ghost then
                ghost = va_structures.get_unit_command_queue_from_pos(pointed_thing.under)
            end
        elseif pointed_thing.type == "object" then
            local entity = pointed_thing.ref
            if entity then
                structure = va_structures.get_active_structure(entity:get_pos())
            end
            if not structure and entity then
                ghost = va_structures.get_unit_command_queue_from_pos(entity:get_pos())
            end
        end

        local selected_unit_id = {}
        local selected_unit_name = ""
        local selected_units = va_commands.get_player_selected_units(player_name)
        local found = false
        for _, selected_entity in ipairs(selected_units) do
            if selected_entity._can_build then
                found = true
                selected_unit_id = selected_entity._id
                selected_unit_name = selected_entity.name
                break
            end
        end
        if found and ghost then
            if ghost.structure_ghost and ghost.structure_ghost.entity_obj then
                core.chat_send_player(player_name, "Queued structure cancelled.")
                ghost.structure_ghost.entity_obj:get_luaentity():on_rightclick(user)
            end
        elseif found then
            --core.chat_send_player(player_name, "Queued build command.")
            va_structures.show_construction_menu(player_name, selected_unit_name, selected_unit_id)
        else
            core.chat_send_player(player_name, "No constructor selected.")
        end
    end
})

