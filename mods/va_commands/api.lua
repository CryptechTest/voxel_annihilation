va_commands = {}

local commands = {}
local selection_entities = {}
local player_selected_units = {}
local player_selection_extent = {}

function va_commands.register_command(name, def)
    -- register the command item that will be used to execute the command
    commands[name] = def
    local item_name = "va_commands:" .. name
    core.register_craftitem(item_name, {
        description = def.description,
        range = def.range or 32,
        inventory_image = "va_commands_" .. name .. ".png",
        on_use = function(itemstack, user, pointed_thing)
            if def.execute_primary then
                def.execute_primary(itemstack, user, pointed_thing)
            end
        end,
        on_place = function(itemstack, placer, pointed_thing)
            if def.execute_secondary then
                def.execute_secondary(itemstack, placer, pointed_thing)
            end
        end,
        on_secondary_use = function(itemstack, user, pointed_thing)
            if def.execute_secondary then
                def.execute_secondary(itemstack, user, pointed_thing)
            end
        end
    })
end

function va_commands.get_command(name)
    return commands[name]
end

function va_commands.set_selection_entities(player_name, entities)
    selection_entities[player_name] = entities
end

function va_commands.get_selection_entities(player_name)
    return selection_entities[player_name] or {}
end
function va_commands.set_player_selected_units(player_name, units)
    player_selected_units[player_name] = units
end

function va_commands.get_player_selected_units(player_name)
    return player_selected_units[player_name] or {}
end

function va_commands.set_player_selection_extent(player_name, extent)
    player_selection_extent[player_name] = extent
end

function va_commands.get_player_selection_extent(player_name)
    return player_selection_extent[player_name] or nil
end

function va_commands.clear_construction_selection_item(player_name)
    local player = core.get_player_by_name(player_name)
    if not player then
        return
    end
    -- find command item in player inventory hotbar
    local build_item = ItemStack({
        name = "va_commands:build",
        count = 1
    })
    local inv = player:get_inventory()
    local inv_name = "main"
    local inv_list = inv:get_list(inv_name)
    local found_index = -1
    local found_stack = nil
    for i, stack in ipairs(inv_list) do
        if not stack:is_empty() then
            local g = core.get_item_group(stack:get_name(), "va_structure")
            if g > 0 then
                found_index = i
                found_stack = stack
            end
        end
    end
    if found_stack == nil then
        return
    end
    found_stack:take_item(1)
    core.after(0, function()
        -- update build item
        inv:set_stack(inv_name, found_index, build_item)
    end)
end