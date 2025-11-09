local build_output_list = {
    ["va_units:vox_commander"] = {
        ['build'] = {
            ['va_structures:vox_bot_lab'] = {
                index = 1
            }
        },
        ['combat'] = {},
        ['economy'] = {
            ['va_structures:vox_energy_converter'] = {
                index = 1
            },
            ['va_structures:vox_energy_storage'] = {
                index = 2
            },
            ['va_structures:vox_mass_extractor'] = {
                index = 4
            },
            ['va_structures:vox_naval_mass_extractor'] = {
                index = 5
            },
            ['va_structures:vox_mass_storage'] = {
                index = 6
            },
            ['va_structures:vox_solar_collector'] = {
                index = 7
            },
            ['va_structures:vox_wind_turbine'] = {
                index = 8
            }
        },
        ['utility'] = {
            ['va_structures:vox_lamp_tower'] = {
                index = 3
            },
            ['va_structures:vox_perimeter_camera'] = {
                index = 4
            },
            ['va_structures:vox_radar_tower'] = {
                index = 5
            },
            ['va_structures:vox_wall'] = {
                index = 6
            }
        }
    },
    ["va_units:vox_constructor"] = {
        ['build'] = {
            ['va_structures:vox_bot_lab'] = {
                index = 1
            },
            ['va_structures:vox_build_turret'] = {
                index = 2
            }
        },
        ['combat'] = {},
        ['economy'] = {
            ['va_structures:vox_energy_converter'] = {
                index = 1
            },
            ['va_structures:vox_energy_storage'] = {
                index = 2
            },
            ['va_structures:vox_geothermal_plant'] = {
                index = 3
            },
            ['va_structures:vox_mass_extractor'] = {
                index = 4
            },
            ['va_structures:vox_naval_mass_extractor'] = {
                index = 5
            },
            ['va_structures:vox_mass_storage'] = {
                index = 6
            },
            ['va_structures:vox_solar_collector'] = {
                index = 7
            },
            ['va_structures:vox_wind_turbine'] = {
                index = 8
            }
        },
        ['utility'] = {
            ['va_structures:vox_anti_radar_missile'] = {
                index = 1
            },
            ['va_structures:vox_jammer_tower'] = {
                index = 2
            },
            ['va_structures:vox_lamp_tower'] = {
                index = 3
            },
            ['va_structures:vox_perimeter_camera'] = {
                index = 4
            },
            ['va_structures:vox_radar_tower'] = {
                index = 5
            },
            ['va_structures:vox_wall'] = {
                index = 6
            }
        }
    }
}

local function table_slice(tbl, first, last, step)
    local sliced = {}
    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced + 1] = tbl[i]
    end
    return sliced
end

local function get_formspec(list_name, player_name, unit_id)

    local unit_obj = va_units.get_player_unit(player_name, unit_id)
    if not unit_obj then
        return
    end
    local unit = unit_obj
    local desc = unit._desc
    local build_page = unit._build_page or 0
    local build_tab = unit._build_tab or 1

    local tab_name = ""
    if build_tab == 1 then
        tab_name = "economy"
    elseif build_tab == 2 then
        tab_name = "build"
    elseif build_tab == 3 then
        tab_name = "combat"
    elseif build_tab == 4 then
        tab_name = "utility"
    end
    local output_list = build_output_list[list_name][tab_name]

    local function get_item(items, index)
        for n, item in pairs(items) do
            if item.index == index then
                return {
                    name = n,
                    item = item
                }
            end
        end
        return nil
    end

    local function build_grid(items)
        local lines = ""
        local x_min = 0.25
        local y_min = 0.75
        local x_max = 1.5
        local y_max = 1.5
        local grid_cols = 5
        local grid_rows = 2
        local max_size = grid_cols * grid_rows
        local max_index = 0

        for _, item in pairs(items) do
            if item.index > max_index then
                max_index = item.index
            end
        end

        local _items = {}
        for i = 1, max_index do
            local menu_item = get_item(items, i)
            if menu_item then
                local s_def = core.registered_nodes[menu_item.name]
                if s_def then
                    local entry = {
                        index = menu_item.item.index,
                        desc = s_def.description,
                        image = s_def.inventory_image
                    }
                    table.insert(_items, entry)
                else
                    --core.log("[va_commands] registered node not found for structure " .. menu_item.name)
                end
            else
                local blank = {
                    index = i,
                    desc = "Unknown",
                    image = "base_structure_item.png"
                }
                table.insert(_items, blank)
            end
        end

        table.sort(_items, function(a, b)
            return a.index < b.index
        end)

        local build_index = math.floor(build_page % max_size)
        if build_page >= max_size then
            build_index = math.floor(build_page)
        end
        local startIndex = 1 + (build_index * max_size)
        local endIndex = (max_size * math.max(1, build_index + 1))
        local sliced_items = table_slice(_items, startIndex, endIndex)
        local at_end = startIndex > max_index - max_size

        local i = 1
        local x = x_min
        local y = y_min
        for _, item in pairs(sliced_items) do
            if item.desc and item.index > 0 then
                lines = lines .. "tooltip[build_queue_" .. item.index .. ";" .. item.desc .. ";#000000ff;#d1d1d1f1]"
                lines = lines .. "image_button[" .. x .. "," .. y .. ";1.5,1.5;base_structure_item.png;build_queue_" ..
                            item.index .. ";]"
            end
            x = x + x_max
            if i % grid_cols == 0 then
                x = x_min
                y = y_min + y_max
            end
            i = i + 1
        end
        return lines, at_end, math.ceil(max_index / max_size)
    end

    local formspec = "size[8,8]" .. "no_prepend[]" .. "formspec_version[10]" -- .. "allow_close[false]"

    -- formspec = formspec .. "field[6,0;2,1;unit_id;Unit Id;"..unit_id.."]"
    formspec = formspec .. "label[0.025,6.95;" .. core.colorize("#a1a1a1af", "Unit GUID - Internal Reference") .. "]"

    formspec = formspec .. "dropdown[0.0,7.35;5;unit_id;" .. unit_id .. ";1;false]"

    formspec = formspec .. "box[0.0,0.5;7.8,5.35;" .. "#272623" .. "]"

    formspec = formspec .. "style_type[label;font_size=22;font=bold]"
    formspec = formspec .. "label[0.0,-0.1;" .. desc .. " - Build Select]" .. "bgcolor[#101010;]"
    formspec = formspec .. "style_type[label;font_size=16;font=bold]"

    local built_grid, at_end_page, build_page_max = build_grid(output_list)
    formspec = formspec .. built_grid

    local lbl_text1 = core.colorize("#a1a1a1af", "Page: " .. (build_page + 1) .. "/" .. build_page_max .. "")
    formspec = formspec .. "label[3.4,4.05;" .. lbl_text1 .. "]"

    if build_page > 0 then
        formspec = formspec .. "tooltip[sel_prev_page;Previous Build Page;#000000ff;#d1d1d1f1]"
        formspec = formspec .. "image_button[0.25,3.75;1.5,0.8;va_hud_previous.png;sel_prev_page;]"
    end
    if not at_end_page then
        formspec = formspec .. "tooltip[sel_next_page;Next Build Page;#000000ff;#d1d1d1f1]"
        formspec = formspec .. "image_button[6.25,3.75;1.5,0.8;va_hud_next.png;sel_next_page;]"
    end

    local queue_y = 4.6
    formspec = formspec .. "box[0.25," .. (queue_y) .. ";7.3,0.04;" .. "#f1f1f1" .. "]"

    queue_y = queue_y + 0.2

    local menu_economy_color = build_tab == 1 and "#35F8FF" or "#5A6773"
    local menu_build_color = build_tab == 2 and "#FFF235" or "#73715A"
    local menu_combat_color = build_tab == 3 and "#FF3535" or "#735C5A"
    local menu_utility_color = build_tab == 4 and "#D735FF" or "#6C5579"

    local btn_x_siz = 1.8325
    local btn_x = 0.25

    local tab_x = btn_x + (btn_x_siz * (build_tab - 1))
    local menu_tab_box = "box[" .. tab_x .. "," .. (queue_y - 0.075) .. ";" .. (btn_x_siz - 0.0425) .. ",0.075;" ..
                             "#5fff5f" .. "]"

    formspec = formspec .. "style[menu_economy;bgcolor=" .. menu_economy_color .. "]"
    formspec = formspec .. "button[" .. btn_x .. "," .. queue_y .. ";2,1;menu_economy;Economy]"

    btn_x = btn_x + btn_x_siz
    formspec = formspec .. "style[menu_build;bgcolor=" .. menu_build_color .. "]"
    formspec = formspec .. "button[" .. btn_x .. "," .. queue_y .. ";2,1;menu_build;Build]"

    btn_x = btn_x + btn_x_siz
    formspec = formspec .. "style[menu_combat;bgcolor=" .. menu_combat_color .. "]"
    formspec = formspec .. "button[" .. btn_x .. "," .. queue_y .. ";2,1;menu_combat;Combat]"

    btn_x = btn_x + btn_x_siz
    formspec = formspec .. "style[menu_utility;bgcolor=" .. menu_utility_color .. "]"
    formspec = formspec .. "button[" .. btn_x .. "," .. queue_y .. ";2,1;menu_utility;Utility]"
    formspec = formspec .. menu_tab_box

    queue_y = queue_y + 0.4

    formspec = formspec .. "style[quit;bgcolor=" .. "#ff0000ff" .. "]"
    formspec = formspec .. "button_exit[6.5,7.3;1.5,1;quit;Exit]"

    return formspec
end

local function on_receive_fields(unit_id, player, formname, fields)
    if not player then
        return false
    end
    -- lookup unit by unit id
    local unit_obj = va_units.get_unit_by_id(unit_id)
    if not unit_obj then
        core.log("unit_obj is nil")
        return false
    end
    local unit = unit_obj
    local unit_name = unit.object:get_luaentity().name
    -- get slot inventory index of build command item
    local build_command_slot = -1
    local inventory = player:get_inventory()
    if inventory then
        for i = 1, inventory:get_size("main") do
            local stack = inventory:get_stack("main", i)
            if not stack:is_empty() and stack:get_name() == "va_commands:build" then
                build_command_slot = i
            end
        end
    end
    -- build menu pagination handle
    if fields.sel_prev_page then
        local page = unit._build_page or 0
        unit._build_page = page - 1
    elseif fields.sel_next_page then
        local page = unit._build_page or 0
        unit._build_page = page + 1
    end
    -- build menu tab button handles
    if fields.menu_economy then
        unit._build_tab = 1
    elseif fields.menu_build then
        unit._build_tab = 2
    elseif fields.menu_combat then
        unit._build_tab = 3
    elseif fields.menu_utility then
        unit._build_tab = 4
    end
    -- button tab index to name
    local build_tab = unit._build_tab or 1
    local tab_name = ""
    if build_tab == 1 then
        tab_name = "economy"
    elseif build_tab == 2 then
        tab_name = "build"
    elseif build_tab == 3 then
        tab_name = "combat"
    elseif build_tab == 4 then
        tab_name = "utility"
    end
    -- get output list for tab
    local output_list = build_output_list[unit_name][tab_name]
    if not output_list then
        return false
    end
    -- build menu items grid handle
    for name, item in pairs(output_list) do
        if fields["build_queue_" .. item.index] then
            local stack = ItemStack({
                name = name,
                count = 1
            })
            local s_meta = stack:get_meta()
            s_meta:set_string("constructor_id", unit_id)
            s_meta:set_string("constructor_owner", player:get_player_name())
            -- swap the "build" item in player hotbar with this itemstack
            inventory:set_stack("main", build_command_slot, stack)
            -- close formspec
            core.close_formspec(player:get_player_name(), formname)
            return false
        end
    end
    return true
end

local menu_build_all_def = {
    formspec = get_formspec,
    on_receive_fields = on_receive_fields
}

va_structures.add_construction_menu("va_units:vox_constructor", menu_build_all_def)
