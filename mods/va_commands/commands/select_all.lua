local function add_selection(entity)
    local pos = entity.object:get_pos()
    local player_name = entity._owner_name
    if not va_commands.get_selection_entities(player_name) then
        va_commands.set_selection_entities(player_name, {})
    end

    local selected_units = va_commands.get_player_selected_units(player_name)
    local current_selections = va_commands.get_selection_entities(player_name)
    local cbox = entity.object:get_properties().collisionbox
    local size = 1 -- fallback default
    if cbox then
        local xsize = math.abs(cbox[4] - cbox[1])
        local ysize = math.abs(cbox[5] - cbox[2])
        local zsize = math.abs(cbox[6] - cbox[3])
        size = math.max(xsize, ysize, zsize)
    end
    local selection_entity = core.add_entity(pos, "va_commands:selected_unit")
    selection_entity:set_observers({ [player_name] = true })
    selection_entity:set_properties({ visual_size = { x = size + 0.3, y = size + 0.3 } })
    selection_entity:set_attach(entity.object, "", { x = 0, y = size * 5.6, z = 0 }, { x = 0, y = 0, z = 0 })
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
    execute_primary = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        va_commands.set_player_selection_extent(player_name, nil)
        clear_selection(user)
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
        core.chat_send_player(user:get_player_name(), "Selection cleared.")
    end,
})