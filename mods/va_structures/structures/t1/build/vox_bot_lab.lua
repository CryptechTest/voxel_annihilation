-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Bot Lab
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local function table_slice(tbl, first, last, step)
    local sliced = {}
    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced + 1] = tbl[i]
    end
    return sliced
end

local function get_formspec(structure)
    if not structure then
        return
    end

    local pos = structure.pos
    local meta = core.get_meta(pos)
    local desc = structure.desc
    local output_list = structure:get_data():get_build_output_list()

    local build_page = meta:get_int("build_page") or 0
    local queue_page = meta:get_int("queue_page") or 0

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
        local i = 1
        local x_min = 0.25
        local y_min = 0.5
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
        for i = 1, max_index + 1 do
            local item = get_item(items, i)
            if item then
                table.insert(_items, item.item)
            else
                local blank = {
                    index = i,
                    desc = nil,
                    image = nil
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

        local x = x_min
        local y = y_min
        for _, item in pairs(sliced_items) do
            if item.desc and item.index > 0 then
                lines = lines .. "tooltip[build_queue_" .. item.index .. ";" .. item.desc .. ";#000000ff;#d1d1d1f1]"
                lines = lines .. "image_button[" .. x .. "," .. y .. ";1.5,1.5;va_units_blueprint.png;build_queue_" ..
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

    local function get_queue_page_max()
        local inv = meta:get_inventory()
        local inv_name = "build_queue"
        local inv_list = inv:get_list(inv_name)
        local index = 1
        for i, stack in pairs(inv_list) do
            if not stack:is_empty() then
                index = i + 1
            end
        end
        return math.min(math.ceil(index / 7), #inv_list / 7)
    end

    local formspec = "size[8,8]" .. "no_prepend[]" .. "formspec_version[10]" -- .. "allow_close[false]"

    formspec = formspec .. "style_type[label;font_size=22;font=bold]"
    formspec = formspec .. "label[0.0,-0.1;" .. desc .. " - Build Select]" .. "bgcolor[#101010;]"
    formspec = formspec .. "style_type[label;font_size=16;font=bold]"

    local built_grid, at_end_page, build_page_max = build_grid(output_list)
    formspec = formspec .. built_grid

    local lbl_text1 = core.colorize("#a1a1a1af", "Page: " .. (build_page + 1) .. "/" .. build_page_max .. "")
    formspec = formspec .. "label[3.4,3.8;" .. lbl_text1 .. "]"

    if build_page > 0 then
        formspec = formspec .. "tooltip[sel_prev_page;Previous Build Page;#000000ff;#d1d1d1f1]"
        formspec = formspec .. "image_button[0.25,3.5;1.5,0.8;va_hud_previous.png;sel_prev_page;]"
    end
    if not at_end_page then
        formspec = formspec .. "tooltip[sel_next_page;Next Build Page;#000000ff;#d1d1d1f1]"
        formspec = formspec .. "image_button[6.25,3.5;1.5,0.8;va_hud_next.png;sel_next_page;]"
    end

    local queue_y = 4.3
    formspec = formspec .. "box[0.25," .. (queue_y) .. ";7.3,0.04;#f1f1f1]"

    queue_y = queue_y + 0.2

    local queue_page_start = math.floor(queue_page * 7)
    local queue_page_max = get_queue_page_max()
    local lbl_text2 = core.colorize("#a1a1a1af", "Page: " .. (queue_page + 1) .. "/" .. queue_page_max .. "")
    formspec = formspec .. "label[3.4," .. (queue_y) .. ";" .. lbl_text2 .. "]"
    formspec = formspec .. "style_type[label;font_size=16;font=bold]"

    formspec = formspec .. "label[0.5," .. queue_y .. ";Queue]"
    formspec = formspec .. "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";build_queue;0.5," ..
                   (queue_y + 0.4) .. ";7,1;" .. queue_page_start .. "]"
    formspec = formspec .. "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";build_queue]"

    queue_y = queue_y + 0.4

    if queue_page > 0 then
        formspec = formspec .. "tooltip[queue_prev_page;Previous Queue Page;#000000ff;#d1d1d1f1]"
        formspec = formspec .. "image_button[-0.14," .. (queue_y - 0.025) ..
                       ";0.75,1.1;va_hud_left.png;queue_prev_page;]"
    end
    if queue_page < queue_page_max - 1 and queue_page_max > 1 then
        formspec = formspec .. "tooltip[queue_next_page;Next Queue Page;#000000ff;#d1d1d1f1]"
        formspec = formspec .. "image_button[7.425," .. (queue_y - 0.025) ..
                       ";0.75,1.1;va_hud_right.png;queue_next_page;]"
    end

    queue_y = queue_y + 1.0
    formspec = formspec .. "label[0.5," .. (queue_y) .. ";Current]"
    formspec = formspec .. "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";build_unit;0.5," ..
                   (queue_y + 0.4) .. ";1,1;]"
    formspec = formspec .. "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";build_unit]"

    local is_paused = meta:get_int("build_pause") == 1
    local is_repeat = meta:get_int("build_repeat") == 1
    local b_priority = meta:get_int("build_priority")

    formspec = formspec .. "style[build_cancel;bgcolor=" .. "#ffee00ff" .. "]"
    formspec = formspec .. "button[2.0,6.3;1.5,1;build_cancel;Cancel]"
    formspec = formspec .. "style[build_pause;bgcolor=" .. (is_paused and "#ff0000ff" or "#00ff00ff") .. "]"
    formspec = formspec .. "button[3.5,6.3;1.5,1;build_pause;" .. (is_paused and "Paused" or "Pause") .. "]"
    formspec = formspec .. "style[build_repeat;bgcolor=" .. (is_repeat and "#00ff00ff" or "#ff0000ff") .. "]"
    formspec = formspec .. "button[5.0,6.3;1.5,1;build_repeat;" .. (is_repeat and "Repeating" or "Repeat") .. "]"
    formspec = formspec .. "style[build_clear;bgcolor=" .. "#ff3300ff" .. "]"
    formspec = formspec .. "button[6.5,6.3;1.5,1;build_clear;Clear]"

    formspec = formspec .. "style[build_priority;bgcolor=" .. (b_priority == 0 and "#00ffaaff" or "#0066ffff") .. "]"
    formspec = formspec .. "button[2.0,7.3;2.25,1;build_priority;" ..
                   (b_priority == 0 and "High Priority" or "Low Priority") .. "]"

    formspec = formspec .. "style[quit;bgcolor=" .. "#ff0000ff" .. "]"
    formspec = formspec .. "button_exit[6.5,7.3;1.5,1;quit;Exit]"

    return formspec
end

local function enqueue_unit(inv, stack)
    if not stack then
        return
    end
    local inv_name = "build_queue"
    local inv_list = inv:get_list(inv_name)
    local index = 1
    local found_index = -1
    local found_stack = nil
    for i, stack in ipairs(inv_list) do
        if stack:is_empty() then
            index = i
            break
        else
            found_index = i
            found_stack = stack
        end
    end
    if index > #inv_list then
        return
    end
    if found_stack and not found_stack:is_empty() then
        if found_stack:get_name() == stack:get_name() then
            found_stack:set_count(found_stack:get_count() + stack:get_count())
            inv_list[found_index] = found_stack
            inv:set_list(inv_name, inv_list)
            return
        end
    end
    inv:set_stack(inv_name, index, stack)
end

local function on_receive_fields(structure, player, formname, fields)
    if not structure then
        return
    end
    local pos = structure.pos
    local meta = core.get_meta(pos)
    local owner = meta:get_string("owner") or ""
    local inv = meta:get_inventory()

    local output_list = structure:get_data():get_build_output_list()
    for name, item in pairs(output_list) do
        if fields["build_queue_" .. item.index] then
            local stack = ItemStack({
                name = name,
                count = 1
            })
            enqueue_unit(inv, stack)
        end
    end

    if fields.sel_prev_page then
        local val = meta:get_int("build_page") or 0
        meta:set_int("build_page", val - 1)
    elseif fields.sel_next_page then
        local val = meta:get_int("build_page") or 0
        meta:set_int("build_page", val + 1)
    end

    if fields.queue_prev_page then
        local val = meta:get_int("queue_page") or 0
        meta:set_int("queue_page", val - 1)
    elseif fields.queue_next_page then
        local val = meta:get_int("queue_page") or 0
        meta:set_int("queue_page", val + 1)
    end

    if fields.build_cancel then
        structure:build_unit_cancel()
    elseif fields.build_pause then
        local val = meta:get_int("build_pause")
        meta:set_int("build_pause", val == 1 and 0 or 1)
    elseif fields.build_repeat then
        local val = meta:get_int("build_repeat")
        meta:set_int("build_repeat", val == 1 and 0 or 1)
    elseif fields.build_clear then
        structure:build_queue_clear()
    elseif fields.build_priority then
        local val = meta:get_int("build_priority")
        meta:set_int("build_priority", val == 1 and 0 or 1)
    end

end

local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then
        if s_obj.factory_type then
            local meta = core.get_meta(pos)
            s_obj:build_unit_enqueue()
            if #s_obj.process_queue > 0 and meta:get_int("build_pause") == 0 then
                local build_power = s_obj:get_data():get_build_power()
                s_obj:build_unit_with_power(net, nil, build_power)
            end
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_vox_bot_lab_1.gltf",
    textures = {"va_vox_bot_lab_1.png"},
    collisionbox = {-1.5, -0.75, -1.5, 1.5, 0.75, 1.5},
    selectionbox = {-1.45, -0.75, -1.45, 1.45, 0.75, 1.45},
    max_health = 30,
    mass_cost = 50.0,
    mass_storage = 10,
    energy_cost = 95,
    energy_storage = 10,
    build_time = 500,
    build_power = 15,
    factory_type = true,
    build_output_list = {
        ['va_units:vox_constructor'] = {
            index = 1,
            desc = "Constructor",
            image = ""
        },
        ['va_units:vox_scout'] = {
            index = 2,
            desc = "Scout",
            image = ""
        },
        ['va_units:vox_fast_infantry'] = {
            index = 3,
            desc = "Fast Infantry",
            image = ""
        },
        ['va_units:vox_light_plasma'] = {
            index = 4,
            desc = "Light Plasma",
            image = ""
        },
        ['va_units:vox_anti_swarm'] = {
            index = 10,
            desc = "Anti Swarm",
            image = ""
        },
        ['va_units:vox_rocket'] = {
            index = 5,
            desc = "Rocket Bot",
            image = ""
        },
        ['va_units:vox_repair'] = {
            index = 6,
            desc = "Repair Bot",
            image = ""
        }
    },
    formspec = get_formspec,
    on_receive_fields = on_receive_fields,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "bot_lab"
def.desc = "Bot Lab"
def.size = {
    x = 2,
    y = 1,
    z = 2
}
def.category = "build"
def.tier = 1
def.faction = "vox"

-- Register a new Solar Collector
Structure.register(def)

