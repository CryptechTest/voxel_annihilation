va_commands.register_command("build_cancel", {
    description = "Build Cancel",
    range = 128,
    execute_primary = function(itemstack, user, pointed_thing)
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

        core.chat_send_player(player_name, "build abort command.")
        -- find command item in player inventory hotbar
        local build_item = ItemStack({
            name = "va_commands:build",
            count = 1
        })
        local inv = user:get_inventory()
        local inv_name = "main"
        local inv_list = inv:get_list(inv_name)
        local found_index = -1
        local found_stack = nil
        for i, stack in ipairs(inv_list) do
            if not stack:is_empty() then
                local g = core.get_item_group(stack:get_name(), "va_structure")
                if g > 0 then
                    found_stack = stack
                elseif stack:get_name() == "va_commands:build_cancel" then
                    found_index = i
                end
            end
        end
        if found_stack == nil then
            return itemstack
        end
        -- take item
        found_stack:take_item(1)
        user:hud_set_hotbar_itemcount(10)
        user:hud_set_hotbar_image("va_hud_hotbar_10.png")
        core.after(0, function()
            -- update build item
            inv:set_stack(inv_name, found_index, build_item)
        end)

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
        if found and ghost then
            if ghost.structure_ghost and ghost.structure_ghost.entity_obj then
                core.chat_send_player(player_name, "Queued structure cancelled.")
                ghost.structure_ghost.entity_obj:get_luaentity():on_rightclick(user)
            end
        elseif found then
            --va_structures.show_construction_menu(player_name, selected_unit_name, selected_unit_ids[1])
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

        if ghost then
            if ghost.structure_ghost and ghost.structure_ghost.entity_obj then
                core.chat_send_player(player_name, "Queued structure cancelled.")
                ghost.structure_ghost.entity_obj:get_luaentity():on_rightclick(user)
            end
        end

    end
})

