core.register_entity("va_commands:selected_unit", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        visual = "sprite",
        pointable = false,
        textures = { "va_commands_selected_unit_idle.png" },
        glow = 14,
        size = { x = 0, y = 0, z = 0 },
    },
    _marked_for_removal = false,
    on_step = function(self, dtime)
        local parent = self.object:get_attach()
        if not parent then
            self.object:remove()
        end
        if self._marked_for_removal then
            self.object:remove()
        end
    end,
})

core.register_entity("va_commands:selected_structure", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        visual = "cube",
        pointable = false,
        textures = { "va_commands_selected_structure_idle.png", "va_commands_selected_structure_idle.png",
            "va_commands_selected_structure_idle.png", "va_commands_selected_structure_idle.png",
            "va_commands_selected_structure_idle.png", "va_commands_selected_structure_idle.png" },
        glow = 14,
        size = { x = 0, y = 0, z = 0 },
    },
    _marked_for_removal = false,
    on_step = function(self, dtime)
        local parent = self.object:get_attach()
        if not parent then
            self.object:remove()
        end
        if self._marked_for_removal then
            self.object:remove()
        end
    end,
})

core.register_entity("va_commands:pos1", {
    initial_properties = {
        visual = "cube",
        visual_size = { x = 1.1, y = 1.1 },
        textures = { "schemlib_pos1.png", "schemlib_pos1.png",
            "schemlib_pos1.png", "schemlib_pos1.png",
            "schemlib_pos1.png", "schemlib_pos1.png" },
        collisionbox = { -0.55, -0.55, -0.55, 0.55, 0.55, 0.55 },
        physical = false,
        static_save = true,
        glow = 14,
    },
    _marked_for_removal = false,
    on_step = function(self, dtime)
        if self._marked_for_removal then
            self.object:remove()
        end
    end,
})

core.register_entity("va_commands:pos2", {
    initial_properties = {
        visual = "cube",
        visual_size = { x = 1.1, y = 1.1 },
        textures = { "schemlib_pos2.png", "schemlib_pos2.png",
            "schemlib_pos2.png", "schemlib_pos2.png",
            "schemlib_pos2.png", "schemlib_pos2.png" },
        collisionbox = { -0.55, -0.55, -0.55, 0.55, 0.55, 0.55 },
        physical = false,
        static_save = true,
        glow = 14,
    },
    _marked_for_removal = false,
    on_step = function(self, dtime)
        if self._marked_for_removal then
            self.object:remove()
        end
    end,
})


local function remove_selection(entity)
    local children = entity.object:get_children()
    if children then
        for _, child in ipairs(children) do
            local luaentity = child:get_luaentity()
            if luaentity then
                local entity_name = luaentity and luaentity.name
                if entity_name == "va_commands:selected_unit"  or entity_name == "va_commands:selected_structure" then
                    core.chat_send_player(entity._owner_name, "Unit deselected.")
                    child:remove()
                    local currently_selected = va_commands.get_player_selected_units(entity._owner_name)
                    if currently_selected then
                        for i, selected_entity in ipairs(currently_selected) do
                            if selected_entity == entity then
                                table.remove(currently_selected, i)
                                va_commands.set_player_selected_units(entity._owner_name, currently_selected)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end

local function add_selection(entity)
    local pos = entity.object:get_pos()
    local player_name = entity._owner_name
    if not va_commands.get_selection_entities(player_name) then
        va_commands.set_selection_entities(player_name, {})
    end

    local selected_units = va_commands.get_player_selected_units(player_name)
    local current_selections = va_commands.get_selection_entities(player_name)
    local found = false
    for _, selected_entity in ipairs(selected_units) do
        if selected_entity == entity then
            found = true
            break
        end
    end
    if found then
        return remove_selection(entity)
    end
    local cbox = entity.object:get_properties().collisionbox
    local size = 1 -- fallback default
    if cbox then
        local xsize = math.abs(cbox[4] - cbox[1])
        local ysize = math.abs(cbox[5] - cbox[2])
        local zsize = math.abs(cbox[6] - cbox[3])
        size = math.max(xsize, ysize, zsize)
    end
    local selection_entity = nil
    if entity._is_va_structure == true then
        selection_entity = core.add_entity(pos, "va_commands:selected_structure")
        selection_entity:set_observers({ [player_name] = true })
        selection_entity:set_properties({ visual_size = { x = (size / 1.5) + 0.3, y = (size / 1.5) + 0.3 } })
        selection_entity:set_attach(entity.object, "", { x = 0, y = ((size / 2) / 1.5) + 0.6, z = 0 }, { x = 0, y = 0, z = 0 })
    elseif entity._is_va_unit == true then
        selection_entity = core.add_entity(pos, "va_commands:selected_unit")
        selection_entity:set_observers({ [player_name] = true })
        selection_entity:set_properties({ visual_size = { x = size + 0.3, y = size + 0.3 } })
        selection_entity:set_attach(entity.object, "", { x = 0, y = size * 5.6, z = 0 }, { x = 0, y = 0, z = 0 })        
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
    core.chat_send_player(player_name, "Unit selected.")
end

local function select_area(user, pos1, pos2)
    local minp = {
        x = math.min(pos1.x, pos2.x),
        y = math.min(pos1.y, pos2.y),
        z = math.min(pos1.z, pos2.z),
    }
    local maxp = {
        x = math.max(pos1.x, pos2.x),
        y = math.max(pos1.y, pos2.y),
        z = math.max(pos1.z, pos2.z),
    }
    maxp.y = math.min(pos1.y, pos2.y) + 128
    local player_name = user:get_player_name()
    local count = 0
    for _, unit in pairs(va_units.get_all_units()) do
        local upos = unit.object:get_pos()
        if unit._owner_name == player_name and
            upos.x >= minp.x and upos.x <= maxp.x and
            upos.y >= minp.y and upos.y <= maxp.y and
            upos.z >= minp.z and upos.z <= maxp.z then
            add_selection(unit)
            count = count + 1
        end
    end
    for _, structure in pairs(va_structures.get_all_structures()) do
        local spos = structure.object:get_pos()
        if structure._owner_name == player_name and
            spos.x >= minp.x and spos.x <= maxp.x and
            spos.y >= minp.y and spos.y <= maxp.y and
            spos.z >= minp.z and spos.z <= maxp.z then
            add_selection(structure)
            count = count + 1
        end
    end
    core.chat_send_player(player_name, "Selected " .. count .. " units in area.")
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
    local current_extent = va_commands.get_player_selection_extent(player_name)
    if current_extent then
        if current_extent.pos1_entity then
            local luaentity = current_extent.pos1_entity:get_luaentity()
            if luaentity then
                luaentity._marked_for_removal = true
            end
        end
        if current_extent.pos2_entity then
            local luaentity = current_extent.pos2_entity:get_luaentity()
            if luaentity then
                luaentity._marked_for_removal = true
            end
        end
    end
    va_commands.set_player_selection_extent(player_name, nil)
end


va_commands.register_command("select", {
    description = "Select",
    range = 128,
    execute_primary = function(itemstack, user, pointed_thing)
        if user == nil then
            core.chat_send_player(user:get_player_name(), "Error: User is nil.")
            return
        end
        local player_name = user:get_player_name()
        if pointed_thing.type == "nothing" then
            local extent = va_commands.get_player_selection_extent(player_name)
            if extent then
                if extent.pos1 and extent.pos2 then
                    clear_selection(user)
                    core.chat_send_player(player_name, "Selection extent cleared. Please select first position.")
                elseif extent.pos1 then
                    extent.pos2 = user:get_pos()
                    va_commands.set_player_selection_extent(player_name, extent)
                    core.chat_send_player(player_name, "Second position set.")
                    local pos2_entity = core.add_entity(
                        extent.pos2, "va_commands:pos2")
                    pos2_entity:set_observers({ [player_name] = true })
                    extent.pos2_entity = pos2_entity
                    clear_selection(user)
                    select_area(user, extent.pos1, extent.pos2)
                else
                    extent.pos1 = user:get_pos()
                    local pos1_entity = core.add_entity(
                        extent.pos1, "va_commands:pos1")
                    pos1_entity:set_observers({ [player_name] = true })
                    extent.pos1_entity = pos1_entity
                    va_commands.set_player_selection_extent(player_name, extent)
                    core.chat_send_player(player_name, "First position set.")
                end
            end
        elseif pointed_thing.type == "node" then
            local extent = va_commands.get_player_selection_extent(player_name) or {}
            if extent then
                if extent.pos1 and extent.pos2 then
                    clear_selection(user)
                    core.chat_send_player(player_name, "Selection extent cleared.")
                elseif extent.pos1 then
                    extent.pos2 = pointed_thing.under
                    va_commands.set_player_selection_extent(player_name, extent)
                    core.chat_send_player(player_name, "Second position set.")
                    local pos2_entity = core.add_entity(
                        extent.pos2, "va_commands:pos2")
                    pos2_entity:set_observers({ [player_name] = true })
                    extent.pos2_entity = pos2_entity
                    clear_selection(user)
                    select_area(user, extent.pos1, extent.pos2)
                else
                    extent.pos1 = pointed_thing.under
                    va_commands.set_player_selection_extent(player_name, extent)
                    local pos1_entity = core.add_entity(
                        extent.pos1, "va_commands:pos1")
                    pos1_entity:set_observers({ [player_name] = true })
                    extent.pos1_entity = pos1_entity
                    core.chat_send_player(player_name, "First position set.")
                end
            end
        elseif pointed_thing.type == "object" then
            local entity = pointed_thing.ref:get_luaentity()
            if entity == nil then
                core.chat_send_player(player_name, "Selection is not a valid unit.")
                return
            end
            if entity._is_va_unit ~= true and entity._is_va_structure ~= true then
                core.chat_send_player(player_name, "Selection is not a valid unit.")
                return
            end
            local owner_name = entity._owner_name
            if owner_name ~= player_name then
                core.chat_send_player(player_name, "You do not own this unit.")
                return
            end
            local current_extent = va_commands.get_player_selection_extent(player_name)
            if current_extent then
                if current_extent.pos1_entity then
                    current_extent.pos1_entity:get_luaentity()._marked_for_removal = true
                end
                if current_extent.pos2_entity then
                    current_extent.pos2_entity:get_luaentity()._marked_for_removal = true
                end
            end
            va_commands.set_player_selection_extent(player_name, nil)
            add_selection(entity)
        end
    end,
    execute_secondary = function(itemstack, user, pointed_thing)
        if user == nil then
            core.chat_send_player(user:get_player_name(), "Error: User is nil.")
            return
        end
        if pointed_thing.type == "object" then
            local entity = pointed_thing.ref:get_luaentity()
            if entity._is_va_unit == true then
                local player_name = user:get_player_name()
                if entity._owner_name == player_name then
                    if entity._driver == nil then
                        va_units.attach(user, entity)
                    else
                        va_units.detach(user)
                    end
                    return
                end
            end
        elseif pointed_thing.type == "node" then
            local attached = user:get_attach()
            if attached then
                va_units.detach(user)
                return
            end
            local pos = pointed_thing.under
            for i = 1, 16 do
                local above_pos = { x = pos.x, y = pos.y + (17 - i), z = pos.z }
                local node = core.get_node(above_pos)
                if node.name == "air" then
                    user:set_pos(above_pos)
                    break
                end
            end
        else
            local attached = user:get_attach()
            if attached then
                va_units.detach(user)
                return
            end
        end
    end,
})


core.register_on_leaveplayer(function(player)
    clear_selection(player)
end)
