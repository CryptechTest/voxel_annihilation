-- marker particle effect
local function spawn_particle(pos, dir_x, dir_y, dir_z, acl_x, acl_y, acl_z, size, time, amount, color)
    local texture = {
        name = "va_game_marker_1.png^[colorize:"..color..":alpha]",
        blend = "alpha",
        scale = 1,
        alpha = 1.0,
        alpha_tween = {1, 0.1},
        scale_tween = {{
            x = 1.5,
            y = 1.5
        }, {
            x = 0.1,
            y = 0.25
        }}
    }
    local prt = {
        texture = texture,
        vel = 1,
        time = (time or 6),
        size = (size or 1),
        glow = math.random(6, 10),
        cols = false
    }
    local rx = dir_x * prt.vel * math.random(0.3 * 100, 0.7 * 100) / 100
    local ry = dir_y * prt.vel * math.random(0.3 * 100, 0.7 * 100) / 100
    local rz = dir_z * prt.vel * math.random(0.3 * 100, 0.7 * 100) / 100
    core.add_particlespawner({
        amount = amount,
        -- pos = pos,
        minpos = {
            x = pos.x + -0.35,
            y = pos.y + -0.35,
            z = pos.z + -0.35
        },
        maxpos = {
            x = pos.x + 0.35,
            y = pos.y + 0.35,
            z = pos.z + 0.35
        },
        minvel = {
            x = -rx,
            y = ry * 0.8,
            z = -rz
        },
        maxvel = {
            x = rx,
            y = ry,
            z = rz
        },
        minacc = {
            x = acl_x,
            y = acl_y,
            z = acl_z
        },
        maxacc = {
            x = acl_x,
            y = acl_y,
            z = acl_z
        },
        time = prt.time + 2,
        minexptime = prt.time - math.random(1, 3),
        maxexptime = prt.time,
        minsize = ((math.random(0.57 * 100, 0.63 * 100) / 100) * 2 + 1.6) * prt.size,
        maxsize = ((math.random(0.77 * 100, 0.93 * 100) / 100) * 2 + 1.6) * prt.size,
        collisiondetection = prt.cols,
        vertical = false,
        texture = texture,
        glow = prt.glow
    })
end

-- check for valid floor pos
local function has_floor(pos)
    local rad = 1
    local f_pos = vector.new(pos)
    f_pos.y = f_pos.y - 1
    local size = vector.new(rad, 0, rad)
    local pos1 = vector.add(f_pos, size)
    local pos2 = vector.subtract(f_pos, size)
    local nodes = core.find_nodes_in_area(pos1, pos2,
        {"group:cracky", "group:crumbly", "group:choppy", "group:soil", "group:sand"})
    local vol = ((rad * 2) + 1) * ((rad * 2) + 1) - 1
    return #nodes >= vol
end

-- marker for placement of commander...
core.register_node("va_game:command_marker", {
    drawtype = "glasslike",
    tiles = {"default_glass.png"},
    paramtype = "light",
    light_source = 14,
    walkable = false,
    pointable = true,
    diggable = true,
    buildable_to = false,
    is_ground_content = false,
    groups = {
        oddly_breakable_by_hand = 1,
        va_commander_marker = 1
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    },
    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    },
    inventory_image = "va_commands_select_commander.png",
    wield_image = "va_commands_select_commander.png",

    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return itemstack
        end
        local _pos = pointed_thing.above
        local _name = placer:get_player_name()
        if not has_floor(_pos) then
            core.chat_send_player(_name, "Commander start location invalid.")
            return itemstack -- Return the item stack without placing it
        end
        return core.item_place(itemstack, placer, pointed_thing)
    end,
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local meta = core.get_meta(pos)
        if placer:is_player() then
            local p_owner = placer:get_player_name()
            meta:set_string("owner", p_owner)
            local game = va_game.get_game_from_player(p_owner)
            if game then
                game:get_player(p_owner).placed = true
                meta:set_int("game_id", game:get_id())
            end
        end
        core.get_node_timer(pos):start(1)
        itemstack:take_item(1)
        return itemstack
    end,

    can_dig = function(pos, digger)
        local meta = core.get_meta(pos)
        local owner = meta:get_string("owner")
        if owner == digger:get_player_name() then
            return true -- Allow digging if the player is the owner
        else
            return false
        end
    end,
    -- on_dig = function(pos, node, digger) end,
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        if digger:is_player() then
            local owner = oldmetadata:get_string("owner")
            if digger:get_player_name() == owner then
                local game = va_game.get_game_from_player(owner)
                if game then
                    game:get_player(owner).placed = false
                end
            end
        end
    end,

    on_timer = function(pos, elapsed)
        local meta = core.get_meta(pos)
        local owner = meta:get_string("owner")
        local game_id = meta:get_int("game_id")
        local do_remove = false
        if not owner then
            do_remove = true
        elseif game_id then
            local game = va_game.get_game(game_id)
            if not game then
                do_remove = true
                core.log("game not found...")
            elseif game:is_started() then
                do_remove = true
                local s_pos = vector.add(pos, vector.new(0, 0.5, 0))
                local commander = va_units.spawn_unit("va_units:vox_commander", owner, s_pos)
                if commander then
                    commander:get_luaentity()._is_constructed = true
                end
                local color = "#ffffff"
                if owner then
                    local actor = va_game.get_player_actor(owner)
                    color = actor.team_color
                end
                spawn_particle(s_pos, 0.5, 1.25, 0.5, 0, -0.5, 0, 0.4, 3, 60, color)
            end
        end
        if do_remove then
            core.remove_node(pos)
        else
            core.get_node_timer(pos):start(1)
        end
    end
})

core.register_abm({
    label = "va commander spawn marker",
    nodenames = {"group:va_commander_marker"},
    interval = 2,
    chance = 1,
    min_y = -10000,
    max_y = 10000,
    action = function(pos, node, active_object_count, active_object_count_wider)
        local meta = core.get_meta(pos)
        local owner = meta:get_string("owner")
        local color = "#ffffff"
        if owner then
            local actor = va_game.get_player_actor(owner)
            color = actor.team_color
        end
        spawn_particle(pos, 0, 1.5, 0, 0, -0.25, 0, 0.45, 4, 20, color)
        --core.remove_node(pos)
    end
})
