local modname = core.get_current_modname()

local rocks_defs = {{
    name = "small_rocks",
    desc = "Small Rocks",
    levels = 9,
    mesh = "va_small_rocks",
    tiles = {{
        name = "va_small_rocks_2.png"
    }}
}}

local function register_rock(def, index)

    local node_name = modname .. ":" .. def.name .. "_" .. index
    core.register_node(node_name, {
        description = def.desc or "Rocks",
        tiles = def.tiles,
        drawtype = "mesh",
        mesh = def.mesh .. "_" .. index .. ".gltf",
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {
            cracky = 2,
            va_rocks = index or 1,
            va_mass_value = 20, -- scaled by 0.1
            va_energy_value = 5 -- scaled by 0.1
        },
        drop = "",
        sunlight_propagates = true,
        collision_box = {
            type = "fixed",
            fixed = {-8 / 16, -8 / 16, -8 / 16, 8 / 16, 0, 8 / 16}
        },
        selection_box = {
            type = "fixed",
            fixed = {-8 / 16, -8 / 16, -8 / 16, 8 / 16, 0, 8 / 16}
        },

        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then
                return itemstack
            end

            local a_pos = pointed_thing.above
            local b_pos = pointed_thing.under
            local pos_below = b_pos and b_pos or vector.subtract(a_pos, {
                x = 0,
                y = 1,
                z = 0
            })

            local node = core.get_node(b_pos or pos_below)
            local g_node = core.get_item_group(node.name, "va_rocks")
            local g_item = core.get_item_group(itemstack:get_name(), "va_rocks")
            
            if g_node > 0 and g_item > 0 then

                if g_node + g_item <= def.levels then
                    local next_node_name = modname .. ":" .. def.name .. "_" .. (g_node + g_item)

                    core.swap_node(pos_below, {
                        name = next_node_name,
                        param2 = node.param2
                    })

                    itemstack:take_item(1)
                else 

                    if g_node == def.levels then
                        return
                    end

                    local next_node_name = modname .. ":" .. def.name .. "_" .. 9
                    
                    local new_item_lvl = (g_node + g_item) - def.levels
                    local new_item_name = modname .. ":" .. def.name .. "_" .. new_item_lvl

                    core.swap_node(pos_below, {
                        name = next_node_name,
                        param2 = node.param2
                    })

                    itemstack:take_item(1)
                    
                    local inv = placer:get_inventory()
                    inv:add_item("main", new_item_name)

                end
            else
                local param2 = core.dir_to_facedir(placer:get_look_dir()) 
                local next_node_name = modname .. ":" .. def.name .. "_" .. g_item
                core.set_node(a_pos, {
                    name = next_node_name,
                    param2 = param2
                })
                itemstack:take_item(1)
            end

            return core.rotate_node(itemstack, placer, pointed_thing)
        end,

        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            
            local g_node = core.get_item_group(node.name, "va_rocks")
            local g_item = core.get_item_group(itemstack:get_name(), "va_rocks")

            if g_node > 0 and g_item > 0 then

                if g_node + g_item <= def.levels then
                    local next_node_name = modname .. ":" .. def.name .. "_" .. (g_node + g_item)

                    core.swap_node(pos, {
                        name = next_node_name,
                        param2 = node.param2
                    })

                    itemstack:take_item(1)
                end
            end
        end,

        after_dig_node = function(pos, oldnode, oldmetadata, digger)

            local g = core.get_item_group(oldnode.name, "va_rocks")

            if g - 1 <= 0 then
                return
            end

            local prev_node_name = def.node_name .. "_" .. (g - 1)

            core.swap_node(pos, {
                name = prev_node_name,
                param2 = oldnode.param2
            })

        end

    })

end

local function register_rocks()
    for _, v in pairs(rocks_defs) do
        for i = 1, v.levels, 1 do
            register_rock(v, i)
        end
    end
end

register_rocks()
