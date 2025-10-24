
local function register_structure_entity(def)
    -- display entity shown for structure
    core.register_entity(def.entity_name, {
        initial_properties = {
            physical = true,
            collisionbox = def.collisionbox,
            hp = def.max_health,
            hp_max = def.max_health,
             -- TODO: setup texture and mesh
            visual = "mesh",
            mesh = def.mesh,
            textures = def.textures,
            visual_size = {x=1.0, y=1.0},
            glow = 2,
            infotext = "HP: " .. tostring(def.max_health) .. "/" .. tostring(def.max_health) .. ""
        },

        -- va general vars
        _is_va_structure = true,
        _marked_for_removal = false,
        _command_queue = {},
        _id = nil,
        -- va driver vars
        _player_rotation = { x = 0, y = 0, z = 0 },
        _driver_attach_at = { x = 0, y = 0, z = 0 },
        _driver_eye_offset = { x = 0, y = 0, z = 0 },
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
            local pos = self.object:get_pos()
            va_structures.remove_active_structure(pos)
            if removal then
                self.object:remove()
            end
            core.remove_node(pos)
            return true
        end,

        _is_valid = function(self, pos)
            local h = core.hash_node_position(pos)
            self._valid = h == self._owner_hash and true or false
            return self._valid
        end,

        on_step = function(self, dtime)
            self._timer = self._timer + 1
            if self._timer < 10 then
                return
            end
            self._timer = 0
            local pos = self.object:get_pos()
            local node = core.get_node(pos)
            if node and node.name ~= def.fqnn then
                return self:_dispose(true)
            end
            if self._marked_for_removal then
                return self:_dispose(true)
            end
            --process_queue(self)
            --update_visibility(self)
        end,

        get_staticdata = function(self)
            return core.write_json({
                owner = self._owner_name,
                hash = self._owner_hash,
            })
        end,

        on_activate = function(self, staticdata, dtime_s)
            core.log("activating...")
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
            if not s then
                local node = core.get_node(pos)
                if node and node.name ~= def.fqnn then
                    return self:_dispose(true)
                end
            else
                local meta = core.get_meta(pos)
                if meta:get_int("active") == 0 then
                    s:activate(true)
                end
            end
        end,

        on_deactivate = function(self, removal)
            core.log("deactivating...")
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
            end
        end,

        on_punch = def.on_punch or function(puncher, time_from_last_punch, tool_capabilities, direction, damage)

            local function on_hit(self, target)

                local node = core.get_node(target)
                local meta = core.get_meta(target)
                -- core.log("hit " .. node.name)

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