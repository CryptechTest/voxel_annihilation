---@diagnostic disable-next-line: lowercase-global
va_units = {}
va_units.registered_models = {}

local modpath = core.get_modpath("va_units")
local register_unit_gauge, attach_unit_gauge = dofile(modpath .. "/unit_entity_gauge.lua")

register_unit_gauge()

local units = {}
local player_units = {}
local active_units = {}
local loaded_mapblocks = {}

---@diagnostic disable-next-line: deprecated
local abs, atan2, cos, floor, max, min, sin, sqrt, pi = math.abs, math.atan2, math.cos, math.floor, math.max, math.min,
    math.sin, math.sqrt, math.pi

local function find_free_pos(pos)
    local check = {
        { x = 1,  y = 0, z = 0 },
        { x = 1,  y = 1, z = 0 },
        { x = -1, y = 0, z = 0 },
        { x = -1, y = 1, z = 0 },
        { x = 0,  y = 0, z = 1 },
        { x = 0,  y = 1, z = 1 },
        { x = 0,  y = 0, z = -1 },
        { x = 0,  y = 1, z = -1 }
    }

    for _, c in pairs(check) do
        local npos = { x = pos.x + c.x, y = pos.y + c.y, z = pos.z + c.z }
        local node = core.get_node_or_nil(npos)

        if node and node.name then
            local def = core.registered_nodes[node.name]
            if def and not def.walkable and
                def.liquidtype == "none" then
                return npos
            end
        end
    end

    return pos
end

local function find_path(unit, target_pos, ...)
    if not target_pos then
        core.log("[va_units] target_pos is nil on find_path()")
        return nil
    end
    local start = unit.object:get_pos()
    local path = core.find_path(start, target_pos, ...) or
        core.find_path(vector.add(start, vector.new(0, 1, 0)), target_pos, ...)
    return path
end




local function check_for_removal(unit)
    if not unit.object then
        return true
    end
    if unit._marked_for_removal then
        unit.object:remove()
        return true
    end
    return false
end

local function keep_loaded(unit)
   if not unit.object then return end
    local pos = unit.object:get_pos()
    local base = {
        x = math.floor(pos.x / 16),
        y = math.floor(pos.y / 16),
        z = math.floor(pos.z / 16),
    }

    -- Only update if mapblock changed
    if unit._current_mapblock and
       (unit._current_mapblock.x == base.x and
        unit._current_mapblock.y == base.y and
        unit._current_mapblock.z == base.z) then
        return -- Still in same mapblock, nothing to do
    end

    -- Free old blocks
    if unit._forceloaded_blocks then
        for _, block in ipairs(unit._forceloaded_blocks) do
            local block_x = math.floor(block.x / 16)
            local block_y = math.floor(block.y / 16)
            local block_z = math.floor(block.z / 16)
            local key = block_x .. "," .. block_y .. "," .. block_z
            if loaded_mapblocks[key] then
                loaded_mapblocks[key] = loaded_mapblocks[key] - 1
                if loaded_mapblocks[key] == 0 then
                    core.forceload_free_block(block, true)
                    loaded_mapblocks[key] = nil
                end
            end
        end
    end

    -- Forceload new 3x3x3 cube
    unit._forceloaded_blocks = {}
    for dx = -1, 1 do
        for dy = -1, 1 do
            for dz = -1, 1 do
                local block_x = base.x + dx
                local block_y = base.y + dy
                local block_z = base.z + dz
                local key = block_x .. "," .. block_y .. "," .. block_z
                local mb = { x = block_x * 16, y = block_y * 16, z = block_z * 16 }
                if not loaded_mapblocks[key] then
                    loaded_mapblocks[key] = 1
                    core.forceload_block(mb, true)
                    table.insert(unit._forceloaded_blocks, mb)
                else
                    loaded_mapblocks[key] = loaded_mapblocks[key] + 1
                end             
                
            end
        end
    end

    unit._current_mapblock = base
end

local function find_attack_targets(unit, weapon)
    local targets = {}
    if not unit._can_attack then
        return targets
    end
    local weapon_range = weapon.range or 8
    local unit_pos = unit.object:get_pos()
    for _, other_unit in pairs(active_units) do
        if other_unit._team_uuid ~= unit._team_uuid then
            if other_unit.object and other_unit.object:get_pos() then
                local other_pos = other_unit.object:get_pos()
                local distance = vector.distance(unit_pos, other_pos)
                if distance <= weapon_range then
                    table.insert(targets, other_unit)
                end
            end
        end
    end
    local structures = va_structures.get_active_structures()
    for _, other_structure in pairs(structures) do
        if not other_structure._disposed and other_structure.pos then
            if other_structure.team_uuid ~= unit._team_uuid then
                if vector.distance(unit_pos, other_structure.pos) <= weapon_range then
                    table.insert(targets, { object = other_structure.entity_obj })
                end
            end
        end
    end
    return targets
end

local function update_visibility(unit)
    local unit_owner = unit._owner_name
    local sight_range = unit._sight_range or 16
    for _, other_unit in pairs(active_units) do
        if other_unit._owner_name ~= unit_owner then
            if other_unit._current_mapblock and unit._current_mapblock
            then
                local distance = vector.distance(
                    {
                        x = unit._current_mapblock.x,
                        y = unit._current_mapblock.y,
                        z = unit._current_mapblock.z
                    },
                    {
                        x = other_unit._current_mapblock.x,
                        y = other_unit._current_mapblock.y,
                        z = other_unit._current_mapblock.z
                    }
                )
                if distance <= sight_range then
                    local observers = unit.object:get_observers() or { [unit_owner] = true }
                    local other_observers = other_unit.object:get_observers() or { [other_unit._owner_name] = true }
                    observers[other_unit._owner_name] = true
                    other_observers[unit_owner] = true
                    unit.object:set_observers(observers)
                    other_unit.object:set_observers(other_observers)
                else
                    local observers = unit.object:get_observers() or { [unit_owner] = true }
                    local other_observers = other_unit.object:get_observers() or { [other_unit._owner_name] = true }
                    observers[other_unit._owner_name] = nil
                    other_observers[unit_owner] = nil
                    unit.object:set_observers(observers)
                    other_unit.object:set_observers(other_observers)
                end
            end
        else
            local observers = unit.object:get_observers() or { [unit_owner] = true }
            local other_observers = other_unit.object:get_observers() or { [other_unit._owner_name] = true }
            local merged = {}
            for k, v in pairs(observers) do merged[k] = v end
            for k, v in pairs(other_observers) do merged[k] = v end
            unit.object:set_observers(merged)
        end
    end
end

local function update_physics(unit)
    local object = unit.object
    if not object then
        return
    end
    --check if unit is stuck inside a solid node
    local pos = object:get_pos()
    local collisionbox = object:get_properties().collisionbox or { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    local feet_y = pos.y + collisionbox[2] + 0.01 -- slightly below feet
    local node_pos = { x = floor(pos.x + 0.5), y = floor(feet_y + 0.5), z = floor(pos.z + 0.5) }
    local node = core.get_node_or_nil(node_pos)
    if node and node.name ~= "air" then
        local def = core.registered_nodes[node.name]
        if def and def.walkable then
            --set the velocity upwards to try to get out of the node
            local vel = object:get_velocity()
            object:set_velocity({ x = vel.x, y = 1, z = vel.z })
        end
    end
    if unit._movement_type == "ground" then
        physics_api.update_physics(object)
    end
end

local function force_detach(player)
    if not player then return end

    local attached_to = player:get_attach()

    if not attached_to then
        return
    end

    local entity = attached_to:get_luaentity()

    if entity and entity._driver
        and entity._driver == player then
        entity._driver = nil
    end

    player:set_detach()

    local name = player:get_player_name()


    player_api.player_attached[name] = false
    player_api.set_animation(player, "stand", 30)
    player_api.set_textures(player, { "player.png", "player_back.png" })
    player:set_eye_offset({ x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
end

local function find_free_ground(unit, target, search_radius)
    local attempt_max = search_radius
    local attempts = 0
    local start_pos = unit.object:get_pos()
    local found_pos = nil

    local function is_free_pos(pos)
        if pos == nil then
            return false
        end
        local check = {
            { x = 1,  y = 0, z = 1 },
            { x = 1,  y = 0, z = 0 },
            { x = 1,  y = 0, z = -1 },
            { x = 0,  y = 0, z = -1 },
            { x = -1, y = 0, z = -1 },
            { x = -1, y = 0, z = 0 },
            { x = -1, y = 0, z = 1 },
            { x = 0,  y = 0, z = 1 },
        }
        local free_pos = {}
        for _, c in pairs(check) do
            local npos = { x = pos.x + c.x, y = pos.y + c.y, z = pos.z + c.z }
            local node = core.get_node_or_nil(npos)

            if node and node.name then
                local def = core.registered_nodes[node.name]
                if def and not def.walkable and
                    def.liquidtype == "none" then
                    table.insert(free_pos, npos)
                end
            end
        end
        return #free_pos > 3
    end

    local function get_free_pos(pos)
        if pos == nil then
            return nil
        end
        local check = {
            { x = 1,  y = 0, z = 1 },
            { x = 1,  y = 0, z = 0 },
            { x = 1,  y = 0, z = -1 },
            { x = 0,  y = 0, z = -1 },
            { x = -1, y = 0, z = -1 },
            { x = -1, y = 0, z = 0 },
            { x = -1, y = 0, z = 1 },
            { x = 0,  y = 0, z = 1 },
        }
        for _, c in pairs(check) do
            local npos = { x = pos.x + c.x, y = pos.y + c.y, z = pos.z + c.z }
            local node = core.get_node_or_nil(npos)
            if node and node.name then
                local def = core.registered_nodes[node.name]
                if def and not def.walkable and
                    def.liquidtype == "none" then
                    return npos
                end
            end
        end
        return pos
    end

    local function check_find_path(target_pos)
        if not target_pos then
            return nil
        end
        target_pos = get_free_pos(target_pos)
        if is_free_pos(target_pos) then
            local stepheight = unit.object:get_properties().stepheight or 0.6
            unit._path = find_path(unit, target_pos, 128, stepheight + 0.7, stepheight + 0.7)
        end
        return target_pos
    end

    local function find_ground(pos)
        if not pos then
            return nil
        end
        for i = -1, search_radius + 1, 1 do
            local p = vector.subtract(pos, { x = 0, y = i, z = 0 })
            local node = core.get_node_or_nil(p)
            if node then
                local nodedef = core.registered_nodes[node.name]
                if nodedef.walkable then
                    local pos_above = vector.add(p, { x = 0, y = 1, z = 0 })
                    --core.log("found ground")
                    return pos_above
                end
            end
        end
        return nil
    end

    local function find_random_ground(pos, r)
        local x = math.random(-r, r)
        local z = math.random(-r, r)
        local y = 0
        local r_pos = vector.add(pos, vector.new(x, y, z))
        if is_free_pos(r_pos) then
            return r_pos
        end
    end

    if unit._target_pos == nil and target then
        local dist = vector.distance(start_pos, target)
        if dist <= search_radius then
            unit._target_pos = get_free_pos(find_ground(target))
            return target
        end
    elseif unit._target_pos ~= nil and target then
        return target
    end

    local last_pos = get_free_pos(find_ground(target))
    while found_pos == nil and attempts < attempt_max do
        attempts = attempts + 1
        local pos = find_random_ground(last_pos, attempts)
        if pos then
            pos = find_ground(pos)
            pos = check_find_path(pos)
            if pos then
                found_pos = pos
            end
        end
    end

    if found_pos then
        unit._target_pos = found_pos
    end

    return found_pos
end

local function process_queue(unit)
    if not unit._command_queue or #unit._command_queue == 0 then
        unit._state = 'idle'
        return
    end
    if not unit._is_constructed then
        unit._state = 'idle'
        return
    end
    -- check if recently processed
    if core.get_us_time() - unit._timer_run < 1 * 1000 * 1000 then
        return
    end
    unit._timer_run = core.get_us_time()
    -- Process next command in the queue
    local q_command = unit._command_queue[1]
    if not q_command then
        return
    end

    if q_command.command_type == "move_to_pos" and not q_command.process_complete then
        unit._state = 'move'
        q_command.process_started = true
        q_command.process_timeout = (q_command.process_timeout or 0) + 1
        local unit_dist = vector.distance(unit.object:get_pos(), q_command.pos)
        va_units.set_target(unit, q_command.pos)
        if unit_dist > 3 then
            if q_command.pos and unit._target_pos == nil then
                --core.log("[va_units] find_free_ground() ... ")
                -- TODO: this is noisey... do better
                if find_free_ground(unit, q_command.pos, 1) then
                    q_command.process_timeout = 0
                end
                --q_command.process_complete = true
            else
                q_command.process_timeout = 1
            end
        else
            q_command.process_complete = true
        end
        if q_command.process_timeout > 5 then
            q_command.process_complete = true
        end
    elseif q_command.command_type == "structure_queued" and not q_command.process_complete then
        unit._state = 'build'
        q_command.process_started = true
        q_command.process_timeout = (q_command.process_timeout or 0) + 1
        local unit_dist = vector.distance(unit.object:get_pos(), q_command.pos)
        -- TODO: unit build range distance
        if unit_dist > 8 then
            if unit._target_pos == nil and q_command.pos then
                local t_pos = vector.add(q_command.pos, { x = 0, y = 1, z = 0 })
                unit._target_pos = t_pos
            end
            if unit._target_pos ~= nil then
                q_command.process_timeout = 0
            end
        else
            unit._target_pos = nil
            local q_cmd = va_structures.get_unit_command_queue_from_pos(q_command.pos)
            if q_cmd then
                q_command.process_complete = true
                local structure = q_cmd.structure_ghost:dequeue_materialize_ghost()
                local construct_command = {
                    command_type = "structure_construct",
                    process_started = false,
                    process_complete = false,
                    pos = structure.pos,
                    owner_name = structure._owner_name,
                    --structure_name = structure.fqnn
                }
                table.insert(unit._command_queue, 2, construct_command)
                q_command.process_timeout = 0
            end
        end
        if q_command.process_timeout > 5 then
            q_command.process_complete = true
        end
    elseif q_command.command_type == "structure_construct" and not q_command.process_complete then
        unit._state = 'build'
        q_command.process_started = true
        q_command.process_timeout = (q_command.process_timeout or 0) + 1
        local unit_dist = vector.distance(unit.object:get_pos(), q_command.pos)
        -- TODO: unit build range distance
        if unit_dist > 8 then
            if q_command.pos then
                local t_pos = vector.add(q_command.pos, { x = 0, y = 1, z = 0 })
                unit._target_pos = t_pos
            end
            if unit._target_pos ~= nil then
                q_command.process_timeout = 0
            end
        else
            unit._target_pos = nil
            local structure = va_structures.get_active_structure(q_command.pos)
            if structure then
                if not structure.is_constructed then
                    local net = va_game.get_player_actor(unit._owner_name)
                    local constructor = {
                        pos = unit.object:get_pos(),
                        -- TODO: setup offset positions for particle emitters
                        entity_emitters_pos = { { x = 0, y = 1.25, z = 0 } }
                    }
                    local unit_def = units[unit.name]
                    local build_power = unit_def and unit_def.build_power or 0
                    if build_power > 0 then
                        structure:construct_with_power(net, build_power, constructor)
                    end
                    q_command.process_timeout = 0
                else
                    q_command.process_complete = true
                end
            end
        end
        if q_command.process_timeout > 3 then
            q_command.process_complete = true
        end
    elseif q_command.command_type == "node_reclaim" and not q_command.process_complete then
        unit._state = 'reclaim'
        q_command.process_started = true
        q_command.process_timeout = (q_command.process_timeout or 0) + 1
        local unit_dist = vector.distance(unit.object:get_pos(), q_command.pos)
        -- TODO: unit build range distance
        if unit_dist > 9 then
            if q_command.pos and unit._target_pos == nil then
                --core.log("[va_units] find_free_ground() ... ")
                -- TODO: this is noisey... do better
                if find_free_ground(unit, q_command.pos, 8) then
                    q_command.process_timeout = 0
                end
            else
                q_command.process_timeout = 1
            end
        else
            unit._target_pos = nil
            local unit_def = units[unit.name]
            local net = va_game.get_player_actor(unit._owner_name)
            if unit_def and net then
                local b_power = unit_def.build_power
                local pos = unit.object:get_pos()
                local b_pos = vector.add(pos, {
                    x = 0,
                    y = 0.4,
                    z = 0
                })
                -- core.log("do reclaim with power")
                local _reclaim_value = va_resources.get_check_reclaim_val(q_command.pos)
                if _reclaim_value == nil then
                    q_command.process_complete = true
                end
                if _reclaim_value then
                    q_command.process_timeout = 0
                    local meta = core.get_meta(q_command.pos)
                    local claimed = (meta:get_int("claimed") ~= nil and meta:get_int("claimed")) or 0
                    local t_reclaim = {
                        pos = q_command.pos,
                        value = _reclaim_value,
                        tick = claimed
                    }
                    if claimed < _reclaim_value.time then
                        va_structures.show_reclaim_beam_effect(t_reclaim.pos, b_pos, b_power * 0.5, net.team_color)
                        if not va_resources.do_reclaim_with_power(t_reclaim, b_power, net) then
                            va_structures.reclaim_effect_particles(t_reclaim.pos, b_power,
                                vector.direction(t_reclaim.pos, pos), net.team_color)
                            if not va_resources.get_check_reclaim_val(t_reclaim.pos) then
                                q_command.process_complete = true
                            end
                        end
                    else
                        q_command.process_complete = true
                    end
                end
            end
        end
        if q_command.process_timeout > 3 then
            q_command.process_complete = true
        end
    end
    -- remove completed command
    if q_command.process_complete then
        table.remove(unit._command_queue, 1)
    end
end

local function enqueue_command(unit, cmd_action)
    if not unit then
        return false
    elseif not cmd_action then
        return false
    end

    -- TODO: handle other types of commands instances...

    if cmd_action.isStructureInst and cmd_action:isStructureInst() then
        local structure = cmd_action
        if structure.pos then
            local construct_command = {
                command_type = "structure_construct",
                process_started = false,
                process_complete = false,
                pos = structure.pos,
                owner_name = structure._owner_name,
                --structure_name = structure.fqnn
            }
            table.insert(unit._command_queue, construct_command)
            return true
        end
    elseif type(cmd_action) == "table" then
        if cmd_action.pos then
            if cmd_action.command_type == "node_reclaim" then
                local reclaim_command = {
                    command_type = "node_reclaim",
                    process_started = false,
                    process_complete = false,
                    pos = cmd_action.pos,
                }
                table.insert(unit._command_queue, reclaim_command)
                return true
            elseif cmd_action.command_type == "move_to_pos" then
                local move_command = {
                    command_type = "move_to_pos",
                    process_started = false,
                    process_complete = false,
                    pos = cmd_action.pos,
                }
                table.insert(unit._command_queue, move_command)
                return true
            end
        end
    end
    -- show warning
    core.log("[va_units] unit ignored invalid command on enqueue: ")
    core.log(dump(cmd_action))
    return false
end

local function abort_queue(unit)
    for _, qc in pairs(unit._command_queue) do
        if qc.command_type == "structure_queued" then
            -- clear queued build command ghosts
            local pos = qc.pos
            local ghost = va_structures.get_unit_command_queue_from_pos(pos)
            if ghost and ghost.structure_ghost then
                ghost.structure_ghost:dispose()
            end
        elseif qc.command_type == "structure_construct" then
            -- ignore?
        end
    end
    va_structures.dispose_unit_command_queue(unit._id)
    unit._command_queue = {}
end

local function abort_queue_at(unit, pos)
    for i, qc in ipairs(unit._command_queue) do
        if qc.command_type == "structure_queued" then
            if qc.pos.y == pos.y and qc.pos.x == pos.x and qc.pos.z == pos.z then
                table.remove(unit._command_queue, i)
                break
            end
        elseif qc.command_type == "structure_construct" then
            -- ignore?
        end
    end
end

local function process_look(driver, unit, horizontal)
    local head_bone = "head"
    local head_override = unit.object:get_bone_override(head_bone) or {}
    head_override.position = head_override.position or
        { vec = { x = 0, y = 0, z = 0 }, absolute = false, interpolation = 2 }
    head_override.rotation = head_override.rotation or
        { vec = { x = 0, y = 0, z = 0 }, absolute = false, interpolation = 2 }
    head_override.rotation.vec = head_override.rotation.vec or { x = 0, y = 0, z = 0 }
    head_override.rotation.vec.x = head_override.rotation.vec.x or 0
    head_override.rotation.vec.y = head_override.rotation.vec.y or 0
    head_override.rotation.vec.z = head_override.rotation.vec.z or 0

    local gun_bone = "arms"
    local gun_override = unit.object:get_bone_override(gun_bone) or {}
    gun_override.position = gun_override.position or
        { vec = { x = 0, y = 0, z = 0 }, absolute = false, interpolation = 2 }
    gun_override.rotation = gun_override.rotation or
        { vec = { x = 0, y = 0, z = 0 }, absolute = false, interpolation = 2 }
    gun_override.rotation.vec = gun_override.rotation.vec or { x = 0, y = 0, z = 0 }
    gun_override.rotation.vec.x = gun_override.rotation.vec.x or 0
    gun_override.rotation.vec.y = gun_override.rotation.vec.y or 0
    gun_override.rotation.vec.z = gun_override.rotation.vec.z or 0

    local target_yaw = driver:get_look_horizontal()
    local target_pitch = driver:get_look_vertical() - pi / 12
    local speed = 0.2

    local function angle_diff(a, b)
        local diff = a - b
        while diff > pi do diff = diff - 2 * pi end
        while diff < -pi do diff = diff + 2 * pi end
        return diff
    end

    local relative_yaw = horizontal - target_yaw
    local max_delta = 0.02
    local desired_delta = angle_diff(relative_yaw, head_override.rotation.vec.y) * speed
    -- Clamp the delta to avoid sudden jumps
    if desired_delta > max_delta then desired_delta = max_delta end
    if desired_delta < -max_delta then desired_delta = -max_delta end
    head_override.rotation.vec.y = head_override.rotation.vec.y + desired_delta
    head_override.rotation.interpolation = 2
    -- Clamp and smoothly interpolate gun bone pitch
    local function clamp(val, minv, maxv)
        return max(minv, min(maxv, val))
    end
    local new_pitch = gun_override.rotation.vec.x + angle_diff(target_pitch, gun_override.rotation.vec.x) * speed
    gun_override.rotation.vec.x = clamp(new_pitch, -pi / 2, pi / 12)
    gun_override.rotation.interpolation = 2
    unit.object:set_bone_override(head_bone, head_override)
    unit.object:set_bone_override(gun_bone, gun_override)
end

local function drive(unit, movement_def, dtime)
    if not unit.object then
        return
    end
    if not movement_def.movement_speed then
        return
    end
    if not unit._driver then
        local vel = unit.object:get_velocity()
        unit.object:set_velocity({ x = 0, y = vel.y, z = 0 })
        if unit._animation ~= unit._animations.stand then
            unit._animation = unit._animations.stand
            unit.object:set_animation(unit._animation, unit._animation_speed or 30)
        end
        return
    end
    local yaw = unit.object:get_yaw() or 0


    local driver = unit._driver
    if not driver then
        return
    end
    local controls = driver:get_player_control()
    local animation = unit._animation
    local vel = unit.object:get_velocity()

    local horizontal = yaw

    if controls.left then
        horizontal = horizontal + (0.05 * (movement_def.turn_speed or 1))
        if animation ~= unit._animations.walk then
            unit._animation = unit._animations.walk
            unit.object:set_animation(unit._animation, unit._animation_speed * 0.66 or 15)
        end
    elseif controls.right then
        horizontal = horizontal - (0.05 * (movement_def.turn_speed or 1))
        if animation ~= unit._animations.walk then
            unit._animation = unit._animations.walk
            unit.object:set_animation(unit._animation, unit._animation_speed * 0.66 or 15)
        end
    end
    process_look(driver, unit, horizontal)
    unit.object:set_yaw(horizontal)

    if controls.up then
        local pos = unit.object:get_pos()
        local yaw = unit.object:get_yaw()
        local stepheight = unit.object:get_properties().stepheight or 0.6

        -- Precompute positions for step detection
        local front_pos = {
            x = pos.x + cos(yaw + pi / 2),
            y = pos.y,
            z = pos.z + sin(yaw + pi / 2),
        }
        local step_pos = { x = front_pos.x, y = front_pos.y + 1, z = front_pos.z }

        -- Detect nodes in front and above
        local node_in_front = core.get_node_or_nil(front_pos)
        local node_above = core.get_node_or_nil(step_pos)

        -- Validate step-up conditions
        local step_up_needed = false
        if node_in_front and node_in_front.name ~= "air" then
            local node_in_front_def = core.registered_nodes[node_in_front.name]
            if node_in_front_def and node_in_front_def.walkable then
                if node_above and node_above.name == "air" then
                    local height_diff = step_pos.y - pos.y
                    if height_diff <= stepheight then
                        step_up_needed = true
                    end
                end
            end
        end

        -- Apply velocity for smooth stepping
        if step_up_needed then
            -- Gradually adjust the y velocity for smoother stepping
            local new_y_velocity = min(vel.y + 0.2, 1.5) -- Lower max value for less aggressive stepping
            unit.object:set_velocity({
                x = movement_def.movement_speed * cos(yaw + pi / 2),
                y = new_y_velocity,
                z = movement_def.movement_speed * sin(yaw + pi / 2),
            })
        else
            -- Normal forward movement
            unit.object:set_velocity({
                x = movement_def.movement_speed * cos(yaw + pi / 2),
                y = vel.y,
                z = movement_def.movement_speed * sin(yaw + pi / 2),
            })
        end
        if animation ~= unit._animations.walk then
            unit._animation = unit._animations.walk
            unit.object:set_animation(unit._animation, unit._animation_speed or 30)
        end
    elseif controls.down and (movement_def.backward_speed or 0) > 0 then
        unit.object:set_velocity({
            x = -movement_def.backward_speed * cos(unit.object:get_yaw() + pi / 2),
            y = vel.y,
            z = -movement_def.backward_speed * sin(unit.object:get_yaw() + pi / 2),
        })
        if animation ~= unit._animations.walk then
            unit._animation = unit._animations.walk
            unit.object:set_animation(unit._animation, (unit._animation_speed * 0.66) or 30)
        end
    else
        -- stop horizontal movement
        unit.object:set_velocity({ x = 0, y = vel.y, z = 0 })
        if animation ~= unit._animations.stand and not (controls.left or controls.right or controls.up or controls.down) then
            unit._animation = unit._animations.stand
            unit.object:set_animation(unit._animation, unit._animation_speed or 30)
        end
    end


    unit._last_action_time = unit._last_action_time or 0

    if controls.LMB then
        -- handle left mouse button action
    end
end

local function get_pos_next(self)
    if not self.object then
        return nil
    elseif self._marked_for_removal then
        return nil
    end
    if self._pos_last then
        local pos = self.object:get_pos()
        local vec = vector.direction(pos, self._pos_last)
        local dist = vector.distance(pos, self._pos_last)
        local m_vec = vector.multiply(vec, dist^2)
        local pos_next = vector.add(pos, m_vec)
        return pos_next
    end
    return self.object:get_pos()
end

function va_units.register_unit(name, def)
    units["va_units:" .. name] = def
    core.register_entity("va_units:" .. name, {
        initial_properties = {
            mesh = def.mesh or name .. ".gltf",
            textures = {
                def.texture or name .. ".png",
            },
            visual = "mesh",
            visual_size = def.visual_size or { x = 1, y = 1 },
            collisionbox = def.collisionbox ~= nil and def.collisionbox or { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
            selectionbox = def.selectionbox ~= nil and def.selectionbox or { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
            stepheight = def.stepheight or 0.6,
            physical = def.physical ~= nil and def.physical or true,
            collide_with_objects = def.collide_with_objects ~= nil and def.collide_with_objects or true,
            makes_footstep_sound = def.makes_footstep_sound ~= nil and def.makes_footstep_sound or true,
            static_save = true,
            hp_max = def.hp_max or 1,
            nametag = "",
            glow = 6,
        },
        _is_va_unit = true,
        _can_build = def.can_build or false,
        _can_reclaim = def.can_reclaim or false,
        _can_repair = def.can_repair or false,
        _can_attack = def.can_attack or false,
        _is_commander = def.is_commander or false,
        _command_queue = {},
        _command_queue_abort = def.command_abort_queue or abort_queue,
        _command_queue_abort_at = def.command_abort_queue_at or abort_queue_at,
        _command_queue_add = def.command_queue_add or enqueue_command,
        _id = nil,
        _team_uuid = nil,
        _desc = def.nametag,
        _player_rotation = def.player_rotation or { x = 0, y = 0, z = 0 },
        _driver_attach_at = def.driver_attach_at or { x = 0, y = 0, z = 0 },
        _driver_eye_offset = def.driver_eye_offset or { x = 0, y = 0, z = 0 },
        _driver = nil,
        _get_pos_next = get_pos_next,
        _pos_last = nil,
        _target_pos = nil,
        _attack_targets = {},
        _weapons = def.weapons or {},
        _sight_range = def.sight_range or 16,
        _path = nil,
        _timer = 0,
        _timer_run = 0,
        _marked_for_removal = false,
        _is_constructed = false,
        _mass_storage = def.mass_storage or 0,
        _mass_generate = def.mass_generate or 0,
        _energy_storage = def.energy_storage or 0,
        _energy_generate = def.energy_generate or 0,
        _energy_usage = def.energy_usage or 0,
        _jumping = 0,
        _animation = def.animations.stand,
        _animations = def.animations or {},
        _animation_speed = def.animation_speed or 30,
        _owner_name = nil,
        _last_action_time = 0,
        _current_mapblock = nil,
        _forceloaded_block = nil,
        _state = 'idle', -- possible states: 'attack_move', 'attack', 'build', 'capture', 'guard', 'idle', 'move', reclaim', 'repair'
        _movement_type = def.movement_type or "ground",
        on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
            local hp = self.object:get_hp()
            local punch_damage = 0

            if tool_capabilities and tool_capabilities.damage_groups then
                for group, val in pairs(tool_capabilities.damage_groups) do
                    punch_damage = punch_damage + val
                end
            end

            -- If custom damage is passed (e.g., from explosion), use it
            if damage and type(damage) == "number" then
                punch_damage = punch_damage + damage
            end

            if punch_damage <= 0 then
                return
            end

            local new_hp = hp - punch_damage
            self.object:set_hp(new_hp)

            -- Optionally, play a hit sound or effect here

            -- Remove unit if HP is zero or less
            if self.object:get_hp() <= 0 then
                --core.log("Unit removing...")
                if self._is_commander then
                    --core.log("is_commander")
                    local owner = self._owner_name
                    local game = va_game.get_game_from_player(owner)
                    if game then
                        --core.log("destroy alert!")
                        game:commander_destroy_alert(self._team_uuid)
                    end
                end
                self.object:remove()
                -- Optionally, play a death effect or sound here
                return true
            end
        end,
        on_activate = function(self, staticdata, dtime_s)
            local animations = def.animations
            if staticdata ~= nil and staticdata ~= "" then
                local data = staticdata:split(';')
                self._owner_name = (type(data[1]) == "string" and #data[1] > 0) and data[1] or nil
                self._marked_for_removal = data[2] == "1" and true or false
                self._team_uuid = data[3] and data[3] or ""
            end
            self._animation = animations.stand
            self.object:set_animation(self._animation or animations.stand, 1, 0)
            self._id = tostring(self.object:get_guid())
            self._command_queue = {}
            local punits = player_units[self._owner_name] or {}
            punits[self._id] = self
            player_units[self._owner_name] = punits
            active_units[self._id] = self
            core.log("action", "Unit activated: " .. (def.nametag or name) .. " " .. self._id)
            keep_loaded(self)
            self.object:set_observers({ [self._owner_name] = true })
        end,
        on_deactivate = function(self, removal)
            core.log("action", "Unit deactivated: " .. (def.nametag or name) .. " " .. self._id)
            if self._forceloaded_block then
                core.forceload_free_block(self._forceloaded_block, true)
                self._forceloaded_block = nil
                if self._current_mapblock then
                    loaded_mapblocks[self._current_mapblock.x .. "," .. self._current_mapblock.y .. "," .. self._current_mapblock.z] = nil
                end
                self._current_mapblock = nil
            end
            local punits = player_units[self._owner_name] or {}
            punits[self._id] = nil
            player_units[self._owner_name] = punits
            active_units[self._id] = nil
            self._command_queue = {}
            self.object:set_observers({})
        end,
        on_death = function(self, killer)
            --core.log("Unit died: " .. (def.nametag or name) .. " " .. self._id)
            if self._is_commander then
                --core.log("is_commander")
                local owner = self._owner_name
                local game = va_game.get_game_from_player(owner)
                if game then
                    --core.log("destroy alert!")
                    game:commander_destroy_alert(self._team_uuid)
                end
            end
        end,
        get_staticdata = function(self)
            return (self._owner_name or "") ..
            ";" .. (self._marked_for_removal and "1" or "0") .. ";" .. (self._team_uuid or "")
        end,
        on_step = function(self, dtime, moveresult)
            if not self.object then
                return
            end

            self._timer = self._timer + dtime
            if check_for_removal(self) then
                return
            end
            self._pos_last = self.object:get_pos()
            -- get attack targets
            for _, weapon in pairs(self._weapons) do
                local targets = find_attack_targets(self, weapon)
                if targets then
                    self._attack_targets = targets
                else
                    self._attack_targets = {}
                end
                if #self._attack_targets > 0 and (not self._cooldowns or not self._cooldowns[weapon.name] or self._cooldowns[weapon.name] <= 0) then
                    local shooter = self
                    local shooter_pos = shooter.object:get_pos()
                    if weapon.offset then
                        shooter_pos = vector.add(shooter_pos, weapon.offset)
                    end
                    local target = self._attack_targets[1]
                    local target_pos = target.object:get_pos()
                    local range = weapon.range or 16
                    local damage = weapon.base_damage or 1
                    local w = va_weapons.get_weapon(weapon.name)
                    local dir = vector.direction(shooter_pos, target_pos)
                    dir.y = dir.y + 0.33 -- aim slightly upwards
                    local dist = vector.distance(shooter_pos, target_pos)
                    local launch_vector = { velocity = vector.multiply(dir, math.min(range, dist)) }
                    w.fire(shooter, shooter_pos, target_pos, range, damage, launch_vector)
                    self._cooldowns = self._cooldowns or {}
                    self._cooldowns[weapon.name] = weapon.cooldown or 1
                else
                    -- reduce cooldown
                    if self._cooldowns and self._cooldowns[weapon.name] and self._cooldowns[weapon.name] > 0 then
                        self._cooldowns[weapon.name] = self._cooldowns[weapon.name] - dtime
                        if self._cooldowns[weapon.name] < 0 then
                            self._cooldowns[weapon.name] = 0
                        end
                    end
                end
            end

            self.object:set_properties({ infotext = def.nametag ..
            "\n" .. "HP: " .. tostring(self.object:get_hp()) .. "/" .. tostring(def.hp_max) .. "" })
            update_physics(self)
            keep_loaded(self)

            -- Handle movement towards target
            local stepheight = self.object:get_properties().stepheight or 0.6

            if (self._path == nil or #self._path < 2) and self._target_pos ~= nil then
                self._path = find_path(self,
                    self._target_pos,
                    128, stepheight + 0.7, stepheight + 0.7)
            end
            if self._path and #self._path > 1 then
                -- Stuck detection: track last position and timer
                self._last_pos = self._last_pos or self.object:get_pos()
                self._stuck_timer = self._stuck_timer or 0

                local pos = self.object:get_pos()


                local moved_dist = sqrt((pos.x - self._last_pos.x) ^ 2 + (pos.y - self._last_pos.y) ^ 2 +
                    (pos.z - self._last_pos.z) ^ 2)
                if moved_dist < 0.05 then
                    self._stuck_timer = self._stuck_timer + dtime
                else
                    self._stuck_timer = 0
                    self._last_pos = { x = pos.x, y = pos.y, z = pos.z }
                end
                if self._stuck_timer > 1 then
                    self._target_pos = nil
                    self._path = nil
                    local vel = self.object:get_velocity()
                    self.object:set_velocity({ x = 0, y = vel.y, z = 0 })
                    if self._animation ~= self._animations.stand then
                        self._animation = self._animations.stand
                        self.object:set_animation(self._animation, self._animation_speed or 30)
                    end
                    self._stuck_timer = 0
                    return
                end
                -- Stop if very close to target
                local target_pos = self._target_pos
                if target_pos then
                    local tpos = self.object:get_pos()
                    local dist = sqrt((target_pos.x - tpos.x) ^ 2 + (target_pos.y - tpos.y) ^ 2 +
                        (target_pos.z - tpos.z) ^ 2)
                    if dist < 1 then
                        self._target_pos = nil
                        self._path = nil
                        local vel = self.object:get_velocity()
                        self.object:set_velocity({ x = 0, y = vel.y, z = 0 })
                        if self._animation ~= self._animations.stand then
                            self._animation = self._animations.stand
                            self.object:set_animation(self._animation, self._animation_speed or 30)
                        end
                        return
                    end
                end

                local next_pos = table.remove(self._path, 2)
                if not next_pos then
                    self._target_pos = nil
                    self._path = nil
                    local vel = self.object:get_velocity()
                    self.object:set_velocity({ x = 0, y = vel.y, z = 0 })
                    if self._animation ~= self._animations.stand then
                        self._animation = self._animations.stand
                        self.object:set_animation(self._animation, self._animation_speed or 30)
                    end
                    return
                end

                

                --check for objects that might be block the way
                local objects = core.get_objects_inside_radius(next_pos, 1)
                -- remove self and non-physical objects from the list
                for i = #objects, 1, -1 do
                    if objects[i] == self.object then
                        table.remove(objects, i)
                    else
                        local obj = objects[i]:get_luaentity()
                        if obj and not obj._is_va_unit and not objects[i]:is_player() then
                            table.remove(objects, i)
                        end
                    end
                end
                -- If there are blocking objects, try to move sideways to go around
                if #objects > 0 then
                    core.chat_send_player(self._owner_name, "Blocked by objects, trying to sidestep.")
                    local p = self.object:get_pos()
                    local dir_vector = vector.subtract(next_pos, p)
                    local right_vector = vector.new(-dir_vector.z, 0, dir_vector.x)
                    local sidestep_found = false
                    local attempt = 1
                    local sidestep_offsets = {}
                    for _, dist in ipairs({ 1, 1.5, 2 }) do
                        for _, sign in ipairs({ 1, -1 }) do
                            -- direct right/left
                            table.insert(sidestep_offsets, vector.multiply(right_vector, dist * sign))
                            -- diagonal right/left + forward
                            local diag = vector.add(vector.multiply(right_vector, dist * sign),
                                vector.multiply(dir_vector, 0.5))
                            table.insert(sidestep_offsets, diag)
                        end
                    end
                    for _, offset in ipairs(sidestep_offsets) do
                        for _, y_offset in ipairs({ 0, 1, -1 }) do
                            local sidestep_pos = vector.add(p, offset)
                            sidestep_pos.y = sidestep_pos.y + y_offset
                            -- Round to node center
                            local node_pos = {
                                x = math.floor(sidestep_pos.x + 0.5),
                                y = math.floor(sidestep_pos.y + 0.5),
                                z = math.floor(sidestep_pos.z + 0.5)
                            }
                            local node = core.get_node_or_nil(node_pos)
                            local node_above = core.get_node_or_nil({ x = node_pos.x, y = node_pos.y + 1, z = node_pos.z })
                            local node_free = false
                            if node and node.name then
                                local d = core.registered_nodes[node.name]
                                node_free = d and not d.walkable and d.liquidtype == "none"
                            end
                            local node_above_free = false
                            if node_above and node_above.name then
                                local d_above = core.registered_nodes[node_above.name]
                                node_above_free = d_above and not d_above.walkable and d_above.liquidtype == "none"
                            end
                            local objects_at_side = core.get_objects_inside_radius(sidestep_pos, 0.75)
                            local object_free = true
                            for _, obj in ipairs(objects_at_side) do
                                if obj ~= self.object then
                                    object_free = false
                                    break
                                end
                            end
                            core.chat_send_player(self._owner_name,
                                string.format(
                                "Sidestep attempt %d (offset=%.2f,%.2f,%.2f y_offset=%d): node_free=%s, node_above_free=%s, object_free=%s",
                                    attempt, offset.x, offset.y, offset.z, y_offset, tostring(node_free),
                                    tostring(node_above_free), tostring(object_free)))
                            if node_free and node_above_free and object_free then
                                next_pos = {
                                    x = node_pos.x + 0.5,
                                    y = node_pos.y,
                                    z = node_pos.z + 0.5
                                }
                                sidestep_found = true
                                core.chat_send_player(self._owner_name,
                                    "Sidestepping to " .. next_pos.x .. ", " .. next_pos.y .. ", " .. next_pos.z)
                                break
                            end
                            attempt = attempt + 1
                        end
                        if sidestep_found then break end
                    end
                    if not sidestep_found then
                        -- Cannot sidestep, stop movement
                        self._target_pos = nil
                        self._path = nil
                        local vel = self.object:get_velocity()
                        self.object:set_velocity({ x = 0, y = vel.y, z = 0 })
                        if self._animation ~= self._animations.stand then
                            self._animation = self._animations.stand
                            self.object:set_animation(self._animation, self._animation_speed or 30)
                        end
                        core.chat_send_player(self._owner_name, "No sidestep possible, stopping.")
                        return
                    end
                end

                local dir_vector = vector.subtract(next_pos, pos)
                local yaw = atan2(dir_vector.z, dir_vector.x) - (pi / 2)
                self.object:set_yaw(yaw)
                local vel = self.object:get_velocity()
                local animation = self._animation

                -- Snap to next node if close horizontally
                local horiz_dist = sqrt((next_pos.x - pos.x) ^ 2 + (next_pos.z - pos.z) ^ 2)
                if horiz_dist < 0.25 then
                    self.object:set_pos({ x = next_pos.x + 0.5, y = pos.y, z = next_pos.z + 0.5 })
                end

                -- Step-up logic for walkable or liquid nodes
                local front_pos = {
                    x = pos.x + cos(yaw + pi / 2),
                    y = pos.y,
                    z = pos.z + sin(yaw + pi / 2),
                }
                local step_pos = { x = front_pos.x, y = front_pos.y + 1, z = front_pos.z }
                local node_in_front = core.get_node_or_nil(front_pos)
                local node_above = core.get_node_or_nil(step_pos)
                local step_up_needed = false
                if node_in_front and node_in_front.name ~= "air" then
                    local node_in_front_def = core.registered_nodes[node_in_front.name]
                    if node_in_front_def and (node_in_front_def.walkable or node_in_front_def.liquidtype ~= "none") then
                        if node_above and node_above.name == "air" then
                            local height_diff = (step_pos.y + stepheight) - pos.y
                            if height_diff <= stepheight then
                                step_up_needed = true
                            end
                        end
                    end
                end

                -- If vertical movement is blocked, nudge upward
                if not step_up_needed and abs(next_pos.y - pos.y) > stepheight and horiz_dist < 0.5 then
                    self.object:set_pos({ x = pos.x, y = next_pos.y, z = pos.z })
                end

                -- Apply velocity for smooth stepping
                if step_up_needed then
                    local new_y_velocity = min(vel.y + stepheight, stepheight * 2)
                    self.object:set_velocity({
                        x = (def.movement_speed * 2.5) * cos(yaw + pi / 2),
                        y = new_y_velocity,
                        z = (def.movement_speed * 2.5) * sin(yaw + pi / 2),
                    })
                else
                    self.object:set_velocity({
                        x = (def.movement_speed * 2.5) * cos(yaw + pi / 2),
                        y = vel.y,
                        z = (def.movement_speed * 2.5) * sin(yaw + pi / 2),
                    })
                end
                if animation ~= self._animations.walk then
                    self._animation = self._animations.walk
                    self.object:set_animation(self._animation, self._animation_speed or 30)
                end
            else
                -- Reached target or no path found
                self._target_pos = nil
                self._path = nil
                local vel = self.object:get_velocity()
                self.object:set_velocity({ x = 0, y = vel.y, z = 0 })
                if self._animation ~= self._animations.stand then
                    self._animation = self._animations.stand
                    self.object:set_animation(self._animation, self._animation_speed or 30)
                end
            end
            process_queue(self)
            update_visibility(self)
        end,
        _collides = function(self, pos)
            local u_def = va_units.get_unit_def(self.name)
            if u_def == nil then
                core.log("[va_units] collides() s_def is nil")
                return false
            end
            local colb = u_def.collisionbox
            if not colb then
                core.log("[va_units] collides() no collision box")
                return false
            end
            local o_pos = self.object:get_pos()
            local pos2 = vector.add(o_pos, {
                x = colb[1],
                y = colb[2],
                z = colb[3]
            })
            local pos1 = vector.add(o_pos, {
                x = colb[4],
                y = colb[5],
                z = colb[6]
            })
            -- Check if pos is within the bounds of pos1 and pos2
            local m_x = (pos.x >= pos2.x and pos.x <= pos1.x)
            local m_y = (pos.y >= pos2.y and pos.y <= pos1.y)
            local m_z = (pos.z >= pos2.z and pos.z <= pos1.z)
            return (m_x and m_y and m_z) or false
        end
    })

    core.register_craftitem("va_units:" .. name, {
        description = def.spawn_item_description,
        inventory_image = def.item_inventory_image or ("va_units_" .. name .. ".png"),
        groups = { spawn_egg = 2, not_in_creative_inventory = 1, va_unit = 1 },
        on_place = function(itemstack, placer, pointed_thing)
            local pos = pointed_thing.above

            local under = core.get_node(pointed_thing.under)
            local node_def = core.registered_nodes[under.name]

            if node_def and node_def.on_rightclick then
                return node_def.on_rightclick(
                    pointed_thing.under, under, placer, itemstack, pointed_thing)
            end

            if pos
                and not core.is_protected(pos, placer:get_player_name()) then
                pos.y = pos.y + 1

                local team_uuid = nil
                local actor = va_game.get_player_actor(place:get_player_name())
                if actor then
                    team_uuid = actor.team
                end

                va_units.spawn_unit("va_units:" .. name, placer:get_player_name(), pos, team_uuid)
                itemstack:take_item()
            end

            return itemstack
        end
    })
end

function va_units.spawn_unit(unit_name, owner_name, pos, team_uuid)
    local registered_def = units[unit_name]
    if not registered_def then
        return nil
    end
    local obj = core.add_entity(pos, unit_name, owner_name .. ";" .. "0" .. ";" .. team_uuid)
    attach_unit_gauge(obj)
    return obj
end

function va_units.attach(player, unit)
    unit._player_rotation = unit._player_rotation or { x = 0, y = 0, z = 0 }
    unit._driver_attach_at = unit._driver_attach_at or { x = 0, y = 0, z = 0 }
    unit._driver_eye_offset = unit._driver_eye_offset or { x = 0, y = 0, z = 0 }

    local rot_view = 0

    if unit._player_rotation.y == 90 then
        rot_view = pi / 2
    end

    local attach_at = unit._driver_attach_at
    local eye_offset = unit._driver_eye_offset
    unit._driver = player

    force_detach(player)

    player_api.player_attached[player:get_player_name()] = true
    player_api.set_textures(player, { "va_units_invisible.png" })
    player:set_attach(unit.object, "", attach_at, unit._player_rotation)
    player:set_eye_offset(eye_offset, unit._driver_eye_offset)
    player:set_look_horizontal(unit.object:get_yaw() - rot_view)
end

function va_units.detach(player)
    force_detach(player)

    core.after(0.1, function()
        if player and player:is_player() then
            local pos = find_free_pos(player:get_pos())

            pos.y = pos.y + 0.5

            player:set_pos(pos)
        end
    end)
end

function va_units.check_collision(pos)
    -- check for collision with objects
    local objects = core.get_objects_inside_radius(pos, 1.75)
    local collides_with = false
    local colliding_with = nil
    for _, obj in ipairs(objects) do
        if obj ~= nil and not obj:is_player() then
            local ent = obj:get_luaentity()
            -- check if structure
            if ent._is_va_unit then
                local unit = va_units.get_unit_by_id(ent._id)
                -- check collision
                if unit and unit:_collides(pos) then
                    collides_with = true
                    colliding_with = obj
                    break
                end
            end
        end
    end
    return collides_with, colliding_with
end

function va_units.get_unit_def(unit_name)
    return units[unit_name]
end

function va_units.get_all_units()
    return active_units
end

function va_units.get_player_units(player_name)
    return player_units[player_name] or {}
end

function va_units.get_unit_by_id(unit_id)
    return active_units[unit_id]
end

function va_units.get_player_unit(player_name, unit_id)
    local punits = player_units[player_name] or {}
    return punits[unit_id]
end

function va_units.set_target(unit, target)
    unit._target_pos = target
end

function va_units.get_target(unit)
    return unit._target_pos
end

function va_units.globalstep(dtime)
    -- Update all units
end

core.register_globalstep(function(...)
    va_units.globalstep(...)
end)

core.register_on_leaveplayer(function(player)
    force_detach(player)
end)

---------------------------------

function va_units.cleanup_assets()
    for _, unit in pairs(active_units) do
        --mark for removal
        unit._marked_for_removal = true
    end
end

core.register_on_shutdown(function()
    --mark for removal on shutdown
    va_units.cleanup_assets()
end)
