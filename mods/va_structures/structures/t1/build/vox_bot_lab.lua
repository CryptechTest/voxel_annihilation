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

local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil then
        return
    end
    -- run 
    if run_stage == "main" then
        if s_obj.factory_type then
            s_obj:build_unit_enqueue()
            if #s_obj.process_queue > 0 then
                local build_power = s_obj:get_data():get_build_power()
                s_obj:build_unit_with_power(net, build_power)
            end
        end
    end
end

local function get_formspec(structure)

    local pos = structure.pos
    local desc = structure.desc
    local output_list = structure:get_data():get_build_output_list()

    local formspec = "size[8,8]" .. "no_prepend[]" .. "formspec_version[10]" -- .. "allow_close[false]"

    formspec = formspec .. "label[0.0,-0.1;" .. desc .. " - Build Select]"

    local function build_grid(items)
        local lines = ""
        local i = 1
        local x = 0.5
        local y = 1.0
        for _, item in pairs(items) do
            lines = lines .. "button[" .. x .. "," .. y .. ";1,1;build_queue_" .. i .. ";" .. item.desc .. "]"
            x = x + 1
            if i % 7 == 0 then
                x = 0.5
                y = y + 1.0
            end
            i = i + 1
        end
        return lines
    end

    formspec = formspec .. build_grid(output_list)

    formspec = formspec .. "label[0.5,4.05;Build Queue]"
    formspec = formspec .. "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";build_queue;0.5,4.5.0;7,1;]"
    formspec = formspec .. "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";build_queue]"

    formspec = formspec .. "label[0.5,5.55;Build Current]"
    formspec = formspec .. "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";build_unit;0.5,6.0.0;1,1;]"
    formspec = formspec .. "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";build_unit]"

    local prog = 0
    local q = structure.process_queue[1]
    if q then
        prog = math.floor((q.build_time / q.build_time_max) * 100)
    end
    -- formspec = formspec .. "image[1.5,6.2;7.3,0.5;construction_bar_0b.png^[lowpart:" .. prog ..":construction_bar_fullb.png^[transformR270]"

    formspec = formspec .. "style[quit;bgcolor=" .. "#ff0000" .. "]"
    formspec = formspec .. "button_exit[6.0,7.25;2,1;quit;Exit]"

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
    if index > 7 then
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
    local i = 1
    for name, item in pairs(output_list) do
        if fields["build_queue_" .. i] then
            local stack = ItemStack({
                name = name,
                count = 1
            })
            enqueue_unit(inv, stack)
        end
        i = i + 1
    end

end

-- Structure metadata definition setup
local def = {
    mesh = "va_vox_bot_lab_1.gltf",
    textures = {"va_vox_bot_lab_1.png"},
    collisionbox = {-1.5, -0.75, -1.5, 1.5, 1.05, 1.5},
    max_health = 30,
    mass_cost = 25.0,
    energy_cost = 100,
    build_time = 500,
    build_power = 10,
    factory_type = true,
    build_output_list = {
        ['va_units:vox_constructor'] = {
            desc = "Constructor",
            image = ""
        },
        ['va_units:vox_scout'] = {
            desc = "Scout",
            image = ""
        },
        ['va_units:vox_fast_infrantry'] = {
            desc = "Infrantry",
            image = ""
        },
        ['va_units:vox_light_plasma'] = {
            desc = "Light Plasma",
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

