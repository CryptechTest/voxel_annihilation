local function register_structure_node(def)

    if not def then
        return false
    end

    local node_name = def.fqnn
    local node_desc = def.desc

    local groups = {
        cracky = 1,
        va_structure = 1
    }

    if def.node_groups ~= nil then
        for k, g in pairs(def.node_groups) do
            groups[k] = g
        end
    end

    local function remove_attached(pos)
        local objs = core.get_objects_inside_radius(pos, 0.15)
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
        --local meta = core.get_meta(pos)
        local objs = core.get_objects_inside_radius(pos, 0.15)
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

    local node_def = {
        description = node_desc,
        paramtype2 = "facedir",
        drop = "",
        groups = groups,
        tiles = {"water_thin.png"},
        use_texture_alpha = "blend",
        drawtype = "nodebox",
        paramtype = "light",
        node_box = {
            type = "fixed",
            fixed = {{-0.3125, -0.5, -0.3125, 0.3125, -0.4375, 0.3125}}
        },
        inventory_image = def.inventory_image or "base_structure_item.png",
        wield_image = def.wield_image or "base_structure_item.png",

        on_place = def.check_placement,
        after_place_node = function(pos, placer, itemstack, pointed_thing)
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
            if def.ui.formspec then
                inv:set_size("build_unit", 1)
                inv:set_size("build_queue", 7 * 10)
                meta:set_int("build_pause", 0)
                meta:set_int("build_repeat", 0)
                meta:set_int("build_page", 0)
                meta:set_int("queue_page", 0)
                meta:set_int("build_priority", 0)
            end
            if def.construction_type then
                meta:set_int("do_assist", 1)
                meta:set_int("do_repair", 1)
                meta:set_int("do_reclaim", 1)
                meta:set_int("build_focus", 1)
                meta:set_int("reclaim_focus", 3)
                meta:set_int("build_priority", 1)
                meta:set_int("reclaim_bar_mass", 800)
                meta:set_int("reclaim_bar_energy", 900)
            end
            meta:set_int("active", 1)
            meta:set_int("is_constructed", 0)
            meta:set_int("health", def.meta.max_health)
            meta:set_int("max_health", def.meta.max_health)
            meta:set_int("last_hit", 0)
        end,

        va_structure_run = def.vas_run,
        -- va_structure_run_stop = def.run_stop,

        on_timer = on_timer,

        allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
            local meta = core.get_meta(pos)
            if from_list == "build_unit" or to_list == "build_unit" then
                return 0
            end
            return count
        end,
        allow_metadata_inventory_put = function(pos, listname, index, stack, player)
            local meta = core.get_meta(pos)
            local stackname = stack:get_name()
            local is_unit = core.get_item_group(stackname, "va_unit") or 0
            if is_unit == 0 then
                return 0
            end
            if listname == "build_unit" then
                return 0
            end
            return stack:get_count()
        end,
        allow_metadata_inventory_take = function(pos, listname, index, stack, player)
            local meta = core.get_meta(pos)
            if listname == "build_unit" then
                return 0
            end
            local stackname = stack:get_name()
            local is_unit = core.get_item_group(stackname, "va_unit") or 0
            if is_unit > 0 then
                return 0
            end
            return stack:get_count()
        end
    }

    if def.under_water_type then
        node_def.drawtype = "liquid"
        node_def.waving = 3
        node_def.tiles = {{
            name = "default_water_source_animated.png",
            backface_culling = false,
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 2.0
            }
        }, {
            name = "water_thin.png",
            backface_culling = true
        }}
        node_def.use_texture_alpha = "blend"
        node_def.paramtype = "light"
        node_def.walkable = false
        node_def.pointable = false
        node_def.diggable = false
        node_def.buildable_to = true
        node_def.is_ground_content = false
        node_def.drop = ""
        node_def.drowning = 1
        node_def.post_effect_color = {
            a = 103,
            r = 30,
            g = 60,
            b = 90
        }
        node_def.groups['water'] = 3
        node_def.groups['liquid'] = 3
        node_def.groups['cools_lava'] = 1
    end

    -- regsiter node def
    core.register_node(node_name, node_def)

    if def.ui.formspec then
        -- register formspec control listener
        core.register_on_player_receive_fields(function(player, formname, fields)
            -- check if our form
            if formname ~= def.ui.form_name then
                return
            end

            local name = player:get_player_name()
            local pos = va_structures.get_selected_pos(name)
            if not name or not pos then
                core.chat_send_player(name, "Access Denied!")
                return
            end

            -- reset formspec until close button pressed
            if (fields.close_me or fields.quit) then
                va_structures.set_selected_pos(name, nil)
                return
            end

            local structure = va_structures.get_active_structure(pos)

            if def.ui.on_receive_fields then
                def.ui.on_receive_fields(structure, player, formname, fields)
            end

            core.show_formspec(name, formname, def.ui.formspec(structure))
        end)
    end

    return true

end

return register_structure_node
