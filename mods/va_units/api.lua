va_units = {}
va_units.registered_models = {}

local units = {}

local abs, cos, floor, sin, sqrt, pi =
    math.abs, math.cos, math.floor, math.sin, math.sqrt, math.pi

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

local function update_physics(unit)
    local object = unit.object
    if not object then
        return
    end
    physics_api.update_physics(object)
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
            nametag = def.nametag or "",
        },
        _player_rotation = def.player_rotation or { x = 0, y = 0, z = 0 },
        _driver_attach_at = def.driver_attach_at or { x = 0, y = 0, z = 0 },
        _driver_eye_offset = def.driver_eye_offset or { x = 0, y = 0, z = 0 },
        _driver = nil,
        _target_pos = nil,
        _timer = 0,
        _jumping = 0,
        _v = 0,
        _animation = def.animations.stand,
        _animations = def.animations or {},
        _animation_speed = def.animation_speed or 30,
        _owner_name = nil,
        on_activate = def.on_activate or function(self, staticdata, dtime_s)
            local animations = def.animations
            if staticdata ~= nil and staticdata ~= "" then
                local data = staticdata:split(';')
                self._owner_name = (type(data[1]) == "string" and #data[1] > 0) and data[1] or nil
            end
            self.object:set_animation(self._animation or animations.stand, 1, 0)
        end,
        on_rightclick = def.on_rightclick or function(self, clicker)
            local player_name = clicker:get_player_name()
            if self._owner_name == player_name then
                if self._driver == nil then
                    va_units.attach(clicker, self)
                else
                    va_units.detach(clicker)
                end
            end
        end,
        on_punch = def.on_punch or function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
            if puncher and puncher:is_player() and self._driver == nil then
                local player_name = puncher:get_player_name()
                if self._owner_name == player_name then
                    core.chat_send_player(player_name, "Unit selected: " .. (def.nametag or name))
                end
            end
        end,
        get_staticdata = def.get_staticdata or function(self)
            return self._owner_name or ""
        end,
        on_step = def.on_step or function(self, dtime, moveresult)
            if not self.object then
                core.log("error", "on_step: self.object is nil for entity " .. tostring(self))
                return
            end
            update_physics(self)
            if self._driver then
                va_units.drive(self,
                    {
                        movement_speed = def.movement_speed * 2.5,
                        turn_speed = def.turn_speed or 1,
                        backward_speed = def
                            .backward_speed or 0
                    }, dtime)
            else
                -- check for commands from AI or other sources

                -- no driver, so stop movement
                local vel = self.object:get_velocity()
                self.object:set_velocity({ x = 0, y = vel.y, z = 0 })
                if self._animation ~= self._animations.stand then
                    self._animation = self._animations.stand
                    self.object:set_animation(self._animation, def.animation_speed or 30)
                end
            end
            self._timer = self._timer + dtime
        end
    })

    core.register_craftitem("va_units:" .. name .. "_spawn", {
        description = def.spawn_item_description,
        inventory_image = def.item_inventory_image or ("va_units_" .. name .. "_item.png"),
        groups = { spawn_egg = 2, not_in_creative_inventory = 1 },
        on_place = function(itemstack, placer, pointed_thing)
            local pos = pointed_thing.above

            local under = core.get_node(pointed_thing.under)
            local def = core.registered_nodes[under.name]

            if def and def.on_rightclick then
                return def.on_rightclick(
                    pointed_thing.under, under, placer, itemstack, pointed_thing)
            end

            if pos
                and not core.is_protected(pos, placer:get_player_name()) then
                pos.y = pos.y + 1

                va_units.spawn_unit("va_units:" .. name, placer:get_player_name(), pos, placer:get_look_yaw())
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

    va_units.force_detach(player)

    player_api.player_attached[player:get_player_name()] = true
    player_api.set_textures(player, { "va_units_invisible.png" })
    player:set_attach(unit.object, "", attach_at, unit._player_rotation)
    player:set_eye_offset(eye_offset, unit._driver_eye_offset)
    player:set_look_horizontal(unit.object:get_yaw() - rot_view)
end

function va_units.force_detach(player)
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

function va_units.detach(player)
    va_units.force_detach(player)

    core.after(0.1, function()
        if player and player:is_player() then
            local pos = find_free_pos(player:get_pos())

            pos.y = pos.y + 0.5

            player:set_pos(pos)
        end
    end)
end

function va_units.drive(unit, movement_def, dtime)
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
            local new_y_velocity = math.min(vel.y + 0.2, 1.5) -- Lower max value for less aggressive stepping
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


    if controls.LMB then
        -- perform action based on selected hotbar item or default action
    end
end

function va_units.globalstep(dtime)
    -- Update all units
end

core.register_globalstep(function(...)
    va_units.globalstep(...)
end)
