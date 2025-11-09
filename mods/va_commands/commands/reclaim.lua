va_commands.register_command("reclaim", {
    description = "Reclaim",
    range = 128,
    execute_primary = function(itemstack, user, pointed_thing)
        if user == nil then
            core.chat_send_player(user:get_player_name(), "Error: User is nil.")
            return
        end
        local player_name = user:get_player_name()
        local target_pos = nil
        if pointed_thing.type == "nothing" then
        elseif pointed_thing.type == "node" then
            target_pos = pointed_thing.under
            if not target_pos then
                target_pos = pointed_thing.above
            end
        elseif pointed_thing.type == "object" then
            local entity = pointed_thing.ref
            if entity then
                target_pos = entity:get_pos()
            end
        end
        -- check target found
        if not target_pos then
            core.chat_send_player(player_name, "Invalid target.")
            return
        end
        -- check if target is reclaimable
        --target_pos = vector.subtract(target_pos, {x=0,y=1,z=0})
        if not va_resources.get_check_reclaim_val(target_pos) then
            core.log("not resource..." .. core.get_node(target_pos).name)
            return
        end

        core.chat_send_player(player_name, "Immediate reclaim command.")

        local selected_unit_id = {}
        --local selected_unit_name = ""
        --local selected_unit_pos = nil
        local selected_units = va_commands.get_player_selected_units(player_name)
        local found = false
        for _, selected_entity in ipairs(selected_units) do
            -- TODO: constructor/reclaim type on unit maybe???
            if selected_entity.name == "va_units:vox_constructor" then
                found = true
                selected_unit_id = selected_entity._id
                --selected_unit_name = selected_entity.name
                --selected_unit_pos = selected_entity.object:get_pos()
                break
            elseif selected_entity.name == "va_structures:vox_build_turret" then
                found = true
                selected_unit_id = selected_entity._id
                --selected_unit_name = selected_entity.name
                --selected_unit_pos = selected_entity.object:get_pos()
                break
            end
        end
        if found then
            local structure = va_structures.get_active_structure_by_id(selected_unit_id)
            local unit = va_units.get_unit_by_id(selected_unit_id)
            if structure then
                -- TODO: order reclaim with structure...
            elseif unit then
                core.log("queue command")
                unit:_command_queue_abort()
                local cmd = {
                    command_type = "node_reclaim",
                    pos = target_pos
                }
                unit:_command_queue_add(cmd)
            end
        else
            core.chat_send_player(player_name, "No constructor or reclaim unit selected.")
        end

    end,
    execute_secondary = function(itemstack, user, pointed_thing)
        if user == nil then
            core.chat_send_player(user:get_player_name(), "Error: User is nil.")
            return
        end
        local player_name = user:get_player_name()
        local target_pos = nil
        if pointed_thing.type == "nothing" then
        elseif pointed_thing.type == "node" then
            target_pos = pointed_thing.under
            if not target_pos then
                target_pos = pointed_thing.above
            end
        elseif pointed_thing.type == "object" then
            local entity = pointed_thing.ref
            if entity then
                target_pos = entity:get_pos()
            end
        end
        -- check target found
        if not target_pos then
            core.chat_send_player(player_name, "Invalid target.")
            return
        end
        -- check if target is reclaimable
        if not va_resources.get_check_reclaim_val(target_pos) then
            return
        end

        core.chat_send_player(player_name, "Queued reclaim command.")

        local selected_unit_id = {}
        local selected_units = va_commands.get_player_selected_units(player_name)
        local found = false
        for _, selected_entity in ipairs(selected_units) do
            -- TODO: constructor/reclaim type on unit maybe???
            if selected_entity.name == "va_units:vox_constructor" then
                found = true
                selected_unit_id = selected_entity._id
                break
            elseif selected_entity.name == "va_structures:vox_build_turret" then
                found = true
                selected_unit_id = selected_entity._id
                break
            end
        end
        if found then
            local structure = va_structures.get_active_structure_by_id(selected_unit_id)
            local unit = va_units.get_unit_by_id(selected_unit_id)
            if structure then
                -- TODO: order reclaim with structure...
            elseif unit then
                local cmd = {
                    command_type = "node_reclaim",
                    pos = target_pos
                }
                unit:_command_queue_add(cmd)
            end
        else
            core.chat_send_player(player_name, "No constructor or reclaim unit selected.")
        end

    end
})

