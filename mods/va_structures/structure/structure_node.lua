local function register_structure_node(def)

    if not def then
        return false
    end

    local node_name = def.fqnn
    local node_desc = def.desc

    local groups = {
        cracky = 1
    }

    local function remove_attached(pos)
        local objs = minetest.get_objects_inside_radius(pos, 0.05)
        for _, obj in pairs(objs) do
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent.name == def.entity_name then
                    obj:remove()
                end
            end
        end
    end

    local function on_timer(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local objs = minetest.get_objects_inside_radius(pos, 0.05)
        for _, obj in pairs(objs) do
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                if ent.name == def.entity_name then
                    obj:set_properties({
                        is_visible = true
                    })
                    break
                end
            end
        end
    end

    core.register_node(node_name .. "", {
        description = node_desc,
        paramtype2 = "facedir",
        drop = "",
        groups = groups,
        tiles = {"va_structure_base.png"},
        drawtype = "nodebox",
        paramtype = "light",
        node_box = {
            type = "fixed",
            fixed = {{-0.25, -0.5, -0.25, 0.25, -0.375, 0.25}}
        },

        -- sounds = default.node_sound_metal_defaults(),
        after_place_node = function(pos, placer, itemstack, pointed_thing)
            -- core.add_entity(pos, def.entity_name)
            local meta = core.get_meta(pos)
            if placer:is_player() then
                meta:set_string("owner", placer:get_player_name())
            end
            return def.after_place_node(pos, placer, itemstack, pointed_thing)
        end,
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            remove_attached(pos)
            return def.after_dig_node(pos, oldnode, oldmetadata, digger)
        end,
        on_construct = function(pos)
            local node = core.get_node(pos)
            local meta = core.get_meta(pos)
            meta:set_string("infotext", node_desc)
            local inv = meta:get_inventory()
            -- inv:set_size("src", 1)
            meta:set_int("active", 1)
            meta:set_int("is_constructed", 0)
            meta:set_int("health", def.meta.max_health)
            meta:set_int("max_health", def.meta.max_health)
            meta:set_string("last_tick", "0")
            meta:set_int("last_hit", 0)
            meta:set_int("e_demand", 0)
            meta:set_int("m_demand", 0)
            meta:set_int("e_generate", 0)
            meta:set_int("m_extract", 0)
        end,

        va_structure_run = def.vas_run,
        -- va_structure_run_stop = def.run_stop,

        on_timer = on_timer
    })

    return true

end

return register_structure_node
