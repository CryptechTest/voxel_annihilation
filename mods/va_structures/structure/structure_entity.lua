-- update visibility of strucuture
local function update_visibility(self)

end

local function register_structure_entity(def)
    -- register structure entity
    core.register_entity(def.entity_name, {
        initial_properties = {
            physical = true,
            collisionbox = def.collisionbox,
            hp = def.max_health,
            hp_max = def.max_health,
            visual = "mesh",
            mesh = def.mesh,
            textures = def.textures,
            visual_size = {
                x = 1.0,
                y = 1.0
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
        _team_id = def.team_id,
        -- internal
        _timer = 1,
        _valid = false,

        -- dispose of instance, enitity, and node
        _dispose = function(self, removal)
            self._valid = false
            local pos = self.object:get_pos()
            va_structures.remove_active_structure(pos)
            if removal then
                self.object:remove()
            end
            local node = core.get_node(pos)
            if node and node.name == def.fqnn then
                core.remove_node(pos)
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
            local node = core.get_node(pos)
            if node and node.name ~= def.fqnn then
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
                local health = s:get_hp()
                local max_health = s:get_hp_max()
                self.object:set_properties({
                    infotext = def.desc .. "\n" .. "HP: " .. tostring(health) .. "/" .. tostring(max_health) .. ""
                })
            end
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
                if prog >= max then
                    self.object:set_properties({
                        textures = def.textures
                    })
                    self._constructed = true
                    return
                end
                local prcnt = 255 - math.floor((prog / max) * 255)
                local textures =
                    {def.textures[1] .. "^[colorize:#00FF00:" .. tostring(prcnt) .. "^[colorize:#0000FF:" ..
                        tostring(math.floor(prcnt * 0.6)) .. ""}
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
        end,

        get_staticdata = function(self)
            return core.write_json({
                owner = self._owner_name,
                hash = self._owner_hash
            })
        end,

        -- activation
        on_activate = function(self, staticdata, dtime_s)
            -- core.log("activating...")
            self._id = tostring(self.object:get_guid())
            self:_is_valid();
            local owner = nil
            local hash = nil
            if staticdata ~= nil and staticdata ~= "" then
                local data = core.parse_json(staticdata)
                if data then
                    owner = data.owner
                    hash = data.hash
                end
            end
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

        on_punch = def.on_punch or function(puncher, time_from_last_punch, tool_capabilities, direction, damage)

            local function on_hit(self, target)

                local node = core.get_node(target)
                local meta = core.get_meta(target)
                -- core.log("hit " .. node.name)

                local s = va_structures.get_active_structure(target)

                if s then
                    local hp = s:get_hp()
                    s:set_hp(hp - 1)
                    s.last_hit = core.get_us_time()
                end

                return false
            end

            if puncher and puncher.object then
                local pos = puncher.object:get_pos();
                on_hit(puncher, pos)
                return 0;
            end

            return damage;
        end
    })

    return true
end

return register_structure_entity
