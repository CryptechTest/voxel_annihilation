local function add_selection(entity)
    local pos = entity.object:get_pos()
    local player_name = entity._owner_name
    if not va_commands.get_selection_entities(player_name) then
        va_commands.set_selection_entities(player_name, {})
    end

    local selected_units = va_commands.get_player_selected_units(player_name)
    local current_selections = va_commands.get_selection_entities(player_name)
    local cbox = entity.object:get_properties().collisionbox
    local size = 1
    local xsize, ysize, zsize = 1, 1, 1
    if cbox then
        xsize = math.abs(cbox[4] - cbox[1])
        ysize = math.abs(cbox[5] - cbox[2])
        zsize = math.abs(cbox[6] - cbox[3])
        size = math.max(xsize, zsize)
    end
    local selection_entity = nil
    if entity._is_va_structure == true then
        selection_entity = core.add_entity(pos, "va_commands:selected_structure", player_name)
        selection_entity:set_observers({ [player_name] = true })
        selection_entity:set_properties({ visual_size = { x = size + 0.1, y = ysize + 0.1 } })
        selection_entity:set_attach(entity.object, "", { x = 0, y = ((ysize - 0.85) / 2) * 10, z = 0 }, { x = 0, y = 0, z = 0 })
    elseif entity._is_va_unit == true then
        selection_entity = core.add_entity(pos, "va_commands:selected_unit", player_name)
        selection_entity:set_observers({ [player_name] = true })
        selection_entity:set_properties({ visual_size = { x = size + 0.5, y = ysize + 0.5 } })
        selection_entity:set_attach(entity.object, "", { x = 0, y = (ysize / 2) * 10, z = 0 }, { x = 0, y = 0, z = 0 })
    else
        return
    end
    if not selection_entity then
        return
    end
    table.insert(selected_units, entity)
    table.insert(current_selections, selection_entity)
    va_commands.set_player_selected_units(player_name, selected_units)
    va_commands.set_selection_entities(player_name, current_selections)
end

local function clear_selection(user)
    local player_name = user:get_player_name()
    local current_selections = va_commands.get_selection_entities(player_name)
    if current_selections then
        for _, entity in ipairs(current_selections) do
            local luaentity = entity:get_luaentity()
            if luaentity then
                luaentity._marked_for_removal = true
            end
        end
        va_commands.set_selection_entities(player_name, {})
    end
    if va_commands.get_player_selected_units(player_name) then
        va_commands.set_player_selected_units(player_name, {})
    end
    va_commands.set_player_selection_extent(player_name, nil)
end


va_commands.register_command("select_all", {
    description = "Select All",
    range = 8,
    execute_primary = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        va_commands.set_player_selection_extent(player_name, nil)
        clear_selection(user)
        va_commands.clear_construction_selection_item(player_name)
        local count = 0
        for _, unit in pairs(va_units.get_all_units()) do
            if unit._owner_name == player_name then
                add_selection(unit)
                count = count + 1
            end
        end
        for _, structure in pairs(va_structures.get_all_structures()) do
            if structure._owner_name == player_name then
                add_selection(structure)
                count = count + 1
            end
        end
        core.chat_send_player(player_name, "Selected " .. count .. " units.")
    end,
    execute_secondary = function(itemstack, user, pointed_thing)
        clear_selection(user)
        va_commands.clear_construction_selection_item(user:get_player_name())
        core.chat_send_player(user:get_player_name(), "Selection cleared.")
    end,
})