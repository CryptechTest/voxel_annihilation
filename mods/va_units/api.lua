va_units = {}
va_units.registered_models = {}

local units = {}
local player_units = {}
local active_units = {}
local loaded_mapblocks = {}

local abs, atan2, cos, floor, min, sin, sqrt, pi =
    math.abs, math.atan2, math.cos, math.floor, math.min, math.sin, math.sqrt, math.pi

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
    local start = unit.object:get_pos()
    local step_height = unit.object:get_properties().stepheight or 0.6
    return core.find_path(start, target_pos, ...) or
        core.find_path(vector.add(start, vector.new(0, step_height, 0)), target_pos, ...)
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
    if not unit.object then
        return
    end
    local pos = unit.object:get_pos()
    local mapblock_pos = {
        x = floor(pos.x / 16),
        y = floor(pos.y / 16),
        z = floor(pos.z / 16),
    }
    local mapblock_key = mapblock_pos.x .. "," .. mapblock_pos.y .. "," .. mapblock_pos.z
    local current_mapblock = unit._current_mapblock
    local current_key = current_mapblock and
        (current_mapblock.x .. "," .. current_mapblock.y .. "," .. current_mapblock.z) or nil

    if current_key and (current_key ~= mapblock_key) then
        if unit._forceloaded_block then
            core.forceload_free_block(unit._forceloaded_block, true)
            loaded_mapblocks[current_key] = nil
            unit._forceloaded_block = nil
        end
    end

    if not loaded_mapblocks[mapblock_key] then
        core.forceload_block(pos, true)
        loaded_mapblocks[mapblock_key] = true
        unit._forceloaded_block = pos
    end

    unit._current_mapblock = mapblock_pos
end

local function update_visibility(unit)
    local unit_owner = unit._owner_name
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
                if distance <= 4 then
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
    local collisionbox = object:get_properties().collisionbox or {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    local feet_y = pos.y + collisionbox[2] + 0.01 -- slightly below feet
    local node_pos = {x = floor(pos.x + 0.5), y = floor(feet_y + 0.5), z = floor(pos.z + 0.5)}
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

local function process_queue(unit)
    if not unit._command_queue or #unit._command_queue == 0 then
        return
    end
    -- Process next command in the queue
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
        },
        _is_va_unit = true,
        _command_queue = {},
        _id = nil,
        _team = nil,
        _player_rotation = def.player_rotation or { x = 0, y = 0, z = 0 },
        _driver_attach_at = def.driver_attach_at or { x = 0, y = 0, z = 0 },
        _driver_eye_offset = def.driver_eye_offset or { x = 0, y = 0, z = 0 },
        _driver = nil,
        _target_pos = nil,
        _timer = 0,
        _marked_for_removal = false,
        _jumping = 0,
        _animation = def.animations.stand,
        _animations = def.animations or {},
        _animation_speed = def.animation_speed or 30,
        _owner_name = nil,
        _last_action_time = 0,
        _current_mapblock = nil,
        _forceloaded_block = nil,
        _movement_type = def.movement_type or "ground",
        on_activate = function(self, staticdata, dtime_s)
            local animations = def.animations
            if staticdata ~= nil and staticdata ~= "" then
                local data = staticdata:split(';')
                self._owner_name = (type(data[1]) == "string" and #data[1] > 0) and data[1] or nil
            end
            self._animation = animations.stand
            self.object:set_animation(self._animation or animations.stand, 1, 0)
            self._id = tostring(self.object:get_guid())
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
            self.object:set_observers({})
        end,
        get_staticdata = function(self)
            return self._owner_name or ""
        end,
        on_step = function(self, dtime, moveresult)
            if not self.object then
                return
            end
            self._timer = self._timer + dtime
            if check_for_removal(self) then
                return
            end
            update_physics(self)
            keep_loaded(self)            
            
            if not self._target_pos and (not self._command_queue or #self._command_queue == 0) then
                drive(self, {
                    movement_speed = def.movement_speed * 2.5,
                    turn_speed = def.turn_speed or 1,
                    backward_speed = def.backward_speed or 0,
                }, dtime)
            else
                -- Handle movement towards target
                local stepheight = self.object:get_properties().stepheight or 0.6

                local path = find_path(self,
                    self._target_pos,
                    1024, stepheight + 0.18, stepheight * 2)
                if path and #path > 1 then
                    -- Stuck detection: track last position and timer
                    self._last_pos = self._last_pos or self.object:get_pos()
                    self._stuck_timer = self._stuck_timer or 0
                    local pos = self.object:get_pos()
                    local moved_dist = sqrt((pos.x - self._last_pos.x)^2 + (pos.y - self._last_pos.y)^2 + (pos.z - self._last_pos.z)^2)
                    if moved_dist < 0.05 then
                        self._stuck_timer = self._stuck_timer + dtime
                    else
                        self._stuck_timer = 0
                        self._last_pos = {x = pos.x, y = pos.y, z = pos.z}
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
                        local dist = sqrt((target_pos.x - tpos.x)^2 + (target_pos.y - tpos.y)^2 + (target_pos.z - tpos.z)^2)
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
                    
                    local next_pos = path[2]
                    local dir_vector = vector.subtract(next_pos, pos)
                    local yaw = atan2(dir_vector.z, dir_vector.x) - (pi / 2)
                    self.object:set_yaw(yaw)
                    local vel = self.object:get_velocity()
                    local animation = self._animation

                    -- Snap to next node if close horizontally
                    local horiz_dist = sqrt((next_pos.x - pos.x)^2 + (next_pos.z - pos.z)^2)
                    if horiz_dist < 0.25 then
                        self.object:set_pos({x = next_pos.x + 0.5, y = pos.y, z = next_pos.z + 0.5})
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
                        self.object:set_pos({x = pos.x, y = next_pos.y, z = pos.z})
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
            end
            process_queue(self)
            update_visibility(self)
        end
    })

    core.register_craftitem("va_units:" .. name, {
        description = def.spawn_item_description,
        inventory_image = def.item_inventory_image or ("va_units_" .. name .. "_item.png"),
        groups = { spawn_egg = 2, not_in_creative_inventory = 1 },
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

                va_units.spawn_unit("va_units:" .. name, placer:get_player_name(), pos, placer:get_look_horizontal())
                itemstack:take_item()
            end

            return itemstack
        end
    })
end

function va_units.spawn_unit(unit_name, owner_name, pos)
    local registered_def = units[unit_name]
    if not registered_def then
        return nil
    end
    local obj = core.add_entity(pos, unit_name, owner_name)
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
