-- update visibility of strucuture
local function update_visibility(self)

end

local function register_structure_entity(def)
    -- register structure entity
    core.register_entity(def.entity_name, {
        initial_properties = {
            physical = true,
            collide_with_objects = true,
            collisionbox = def.collisionbox,
            selectionbox = def.selectionbox and def.selectionbox or def.collisionbox,
            hp = def.max_health,
            hp_max = def.max_health,
            visual = "mesh",
            mesh = def.mesh,
            static_save = true,
            textures = def.textures,
            use_texture_alpha = true,
            visual_size = {
                x = 0.667,
                y = 0.667
            },
            glow = 2,
            type = "va_structure",
            infotext = def.desc .. "\n" .. "HP: " .. tostring(def.max_health) .. "/" .. tostring(def.max_health) .. ""
        },

        -- va general vars
        _is_va_structure = true,
        _marked_for_removal = false,
        _command_queue = {},
        _id = nil,
        _current_mapblock = nil,
        _forceloaded_block = nil,
        -- va driver vars
        _player_rotation = {
            x = 0,
            y = 0,
            z = 0
        },
        _driver_attach_at = {
            x = 0,
            y = 0,
            z = 0
        },
        _driver_eye_offset = {
            x = 0,
            y = 0,
            z = 0
        },
        _driver = nil,
        _target_pos = nil,
        -- va structure vars
        _owner_hash = nil,
        _owner_name = nil,
        _team_uuid = nil,
        -- internal
        _animations = def.entity_animations or nil,
        -- _animation = def.entity_animations and def.entity_animations.idle or nil,
        _timer = 1,
        _valid = false,
        _state = "idle", -- attack, build, guard, idle, reclaim, repair
        -- do animation for entity
        _do_animation = function(self, animation)
            local anim = self._animations[animation] or self._animation
            self.object:set_animation(anim, 1, 0)
        end,
        -- do animation once and then do next after delay length
        _apply_animation = function(self, active_anim, idle_anim, anim_length)
            local anim_active = self._animations[active_anim] or self._animation
            self.object:set_animation(anim_active, 1, 0)
            local anim_idle = self._animations[idle_anim] or self._animation
            core.after(anim_length, function()
                self.object:set_animation(anim_idle, 1, 0)
            end)
        end,

        -- dispose of instance, enitity, and node
        _dispose = function(self, removal)
            self._valid = false
            local pos = self.object:get_pos()
            va_structures.remove_active_structure(pos)
            if removal then
                self.object:remove()
            end
            local node = core.get_node(pos)
            if node and (node.name == def.fqnn or node.name == def.fqnn .. "_water") then
                core.remove_node(pos)
                if core.get_modpath("naturalslopeslib") then
                    local pos_below = vector.subtract(pos, vector.new(0,1,0))
                    local _node = core.get_node(pos_below)
                    ---@diagnostic disable-next-line: undefined-global
                    naturalslopeslib.update_shape(pos_below, _node)
                end
            end
            return true
        end,
        -- check if valid
        _is_valid = function(self)
            local pos = self.object:get_pos()
            local s = va_structures.get_active_structure(pos)
            self._valid = s ~= nil or false
            return self._valid
        end,
        _check_valid = function(self)
            local pos = self.object:get_pos()
            pos = {
                x = math.floor(pos.x),
                y = math.floor(pos.y + 0.5),
                z = math.floor(pos.z)
            }
            local node = core.get_node(pos)
            if node and node.name ~= def.fqnn and node.name ~= def.fqnn .. "_water" then
                self._marked_for_removal = true
            elseif not self:_is_valid() then
                self._marked_for_removal = true
            end
        end,
        -- update display info
        _update_info = function(self)
            local pos = self.object:get_pos()
            local s = va_structures.get_active_structure(pos)
            if s then
                local info_extra = ""
                if s.extractor_type then
                    local pos_under = vector.subtract(s.pos, {
                        x = 0,
                        y = 1,
                        z = 0
                    })
                    local mass_group = core.get_item_group(core.get_node(pos_under).name, "va_mass")
                    if mass_group > 0 then
                        local mass_amount = core.get_meta(pos_under):get_int("va_mass_amount") * 0.01
                        if mass_group == 2 then
                            mass_amount = mass_amount * 0.8
                        elseif mass_group == 1 then
                            mass_amount = mass_amount * 0.6
                        end
                        info_extra = info_extra .. "\n+" .. tostring(mass_amount) .. " Mass"
                    end
                end
                local health = s:get_hp()
                local max_health = s:get_hp_max()
                self.object:set_properties({
                    infotext = def.desc .. "\n" .. "HP: " .. tostring(health) .. "/" .. tostring(max_health) ..
                        info_extra
                })
            end
        end,

        _get_owner_color_texture = function (self, net)
            local color = net.team_color or "#00ff00"
            local texture_base = def.textures[1]
            if def.textures_color then
                local texture_player = def.textures_color[1]
                local textures = { texture_base .. "^(" .. texture_player .. "^[colorize:"..color..":alpha" .. ")"}
                return textures
            else
                return { texture_base }
            end
        end,
        _set_owner_color = function (self, net)
            local textures = self:_get_owner_color_texture(net)
            self.object:set_properties({
                textures = textures,
            })
        end,

        _construct = function(self)
            if self._constructed then
                return
            end
            local pos = self.object:get_pos()
            local s = va_structures.get_active_structure(pos)
            if s then
                local prog = s.construction_tick
                local max = s.construction_tick_max
                local hp = s:get_hp()
                if hp <= 0 then
                    local textures = {def.textures[1] .. "^[colorize:#FF0000:" .. tostring(100) .. ""}
                    self.object:set_properties({
                        textures = textures,
                        is_visible = false
                    })
                    return
                end
                local net = va_game.get_player_actor(self._owner_name)
                if prog >= max then
                    self.object:set_properties({
                        textures = def.textures,
                        use_texture_alpha = false,
                    })
                    self._constructed = true
                    self:_set_owner_color(net)
                    return
                end
                local opacity = math.min(math.max(10, math.floor((prog / max) * 255)), 255)
                local prcnt = 255 - math.floor((prog / max) * 255)
                local texture = self:_get_owner_color_texture(net)[1]
                local textures =
                    { texture .. "^[colorize:#00FF00:" .. tostring(prcnt) .. "^[colorize:#0000FF:" ..
                        tostring(math.floor(prcnt * 0.6)) .. "" .. "^[opacity:" .. tostring(opacity)}
                self.object:set_properties({
                    textures = textures,
                    is_visible = true
                })
            end
        end,

        -- main step
        on_step = function(self, dtime)
            self._timer = self._timer + 1
            if self._timer < 20 then
                return
            end
            self._timer = 0
            self:_construct()
            self:_update_info()
            if self._marked_for_removal then
                return self:_dispose(true)
            end
            self:_is_valid()
            self:_check_valid()
            va_structures.keep_loaded(self)
            -- process_queue(self)
            update_visibility(self)
            local structure = va_structures.get_active_structure(self.object:get_pos())
            if structure then
                if structure:get_hp() <= 0 then
                    structure:destroy()
                    return false
                end
            end
        end,

        get_staticdata = function(self)
            return core.write_json({
                owner = self._owner_name,
                hash = self._owner_hash,
                team_uuid = self._team_uuid
            })
        end,

        -- activation
        on_activate = function(self, staticdata, dtime_s)
            -- core.log("activating...")
            self._id = tostring(self.object:get_guid())
            self:_is_valid();
            local owner = nil
            local hash = nil
            local team_uuid = ""
            if staticdata ~= nil and staticdata ~= "" then
                local data = core.parse_json(staticdata)
                if data then
                    owner = data.owner
                    hash = data.hash
                    team_uuid = data.team_uuid
                end
            end
            self._owner_name = owner
            self._team_uuid = team_uuid
            local pos = self.object:get_pos()
            local s = va_structures.get_active_structure(pos)
            if s then
                va_structures.keep_loaded(self)
                local meta = core.get_meta(pos)
                if meta:get_int("active") == 0 then
                    s:activate(true)
                end
            end
        end,

        -- deactivation
        on_deactivate = function(self, removal)
            -- core.log("deactivating...")
            local pos = self.object:get_pos()
            local s = va_structures.get_active_structure(pos)
            if not s then
                self:_dispose(false)
            elseif not removal then
                s:deactivate()
            end
        end,

        on_death = def.on_death or function(self, killer)
            local pos = self.object:get_pos()
            local meta = core.get_meta(self.pos)
            meta:set_int("health", 0)
            self:_dispose(true)
        end,

        on_rightclick = def.on_rightclick or function(self, clicker)
            local pos = self.object:get_pos();
            if pos then
                --[[self.object:set_properties({
                    is_visible = false
                })
                core.get_node_timer(pos):start(3)]]
                -- va_structures.get_active_structure(pos):get_data():set_self_countdown_active(true)

            end
        end,

        on_punch = def.on_punch or function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)

            local function on_hit(_puncher, target, _damage)
                -- core.log("hit " .. node.name)
                local s = va_structures.get_active_structure(target)
                if not s then
                    return false
                end

                local damage_total = 0
                if tool_capabilities and tool_capabilities.damage_groups then
                    for group, val in pairs(tool_capabilities.damage_groups) do
                        if val > 0 then
                            s:damage(val, group)
                            damage_total = damage_total + val
                        end
                    end
                end

                if s then
                    if _damage > 0 then
                        s:damage(_damage)
                        damage_total = damage_total + _damage
                    end
                    if damage_total > 0 then
                        s.last_hit = core.get_us_time()
                    end
                end

                return false
            end

            local punch_damage = 0
            -- If custom damage is passed (e.g., from explosion), use it
            if damage and type(damage) == "number" then
                punch_damage = punch_damage + damage
            end

            if self and self.object and punch_damage >= 0 then
                --core.log("punched for " .. punch_damage)
                local pos = self.object:get_pos();
                on_hit(puncher, pos, punch_damage)
                return 0;
            end

            return damage;
        end
    })

    return true
end

return register_structure_entity
