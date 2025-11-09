-- update visibility of structure
local function update_visibility(self)

end

local function register_structure_entity_ghost(def)
    -- register structure entity
    core.register_entity(def.entity_name .. "_ghost", {
        initial_properties = {
            physical = false,
            collide_with_objects = false,
            collisionbox = {},
            -- selectionbox = def.selectionbox and def.selectionbox or def.collisionbox,
            hp = def.max_health,
            hp_max = def.max_health,
            visual = "mesh",
            mesh = def.mesh,
            static_save = true,
            textures = { def.textures[1] .. "^[colorize:#00ff00:138^[opacity:72" },
            use_texture_alpha = true,
            visual_size = {
                x = 0.66,
                y = 0.66
            },
            glow = 4,
            type = "va_structure_ghost",
            infotext = def.desc
        },

        -- va general vars
        _is_va_structure = true,
        _marked_for_removal = false,
        _id = nil,
        _current_mapblock = nil,
        _forceloaded_block = nil,
        -- va structure vars
        _owner_hash = nil,
        _owner_name = nil,
        _constructor_id = nil,
        -- internal
        _timer = 1,
        _valid = false,

        -- dispose of instance, enitity, and node
        _dispose = function(self, removal)
            self._valid = false
            va_structures.remove_pos_from_command_queue(self.object:get_pos(), self._constructor_id)
            if removal then
                self.object:remove()
            end
            --core.log("structure ghost disposed")
            return true
        end,
        -- check if valid
        _is_valid = function(self)
            local s = va_structures.get_unit_command_queue(self._constructor_id)
            self._valid = s ~= nil or false
            --core.log(tostring(self._constructor_id) .. " " ..  tostring(self._valid))
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
            if node and node.name ~= "air" then
                self._marked_for_removal = true
            elseif not self:_is_valid() then
                self._marked_for_removal = true
            end
        end,

        -- main step
        on_step = function(self, dtime)
            self._timer = self._timer + 1
            if self._timer < 50 then
                return
            end
            self._timer = 0
            if self._marked_for_removal then
                return self:_dispose(true)
            end
            self:_is_valid()
            self:_check_valid()
            va_structures.keep_loaded(self)
            -- process_queue(self)
            update_visibility(self)
            --[[local structure = va_structures.get_unit_command_queue(self._constructor_id)
            if structure then
                if structure:get_hp() <= 0 then
                    structure:destroy()
                    return false
                end
            end]]
        end,

        get_staticdata = function(self)
            return core.write_json({
                owner = self._owner_name or "",
                hash = self._owner_hash or "",
                constructor_id = self._constructor_id
            })
        end,

        -- activation
        on_activate = function(self, staticdata, dtime_s)
            --core.log("structure ghost activating...")
            self._id = tostring(self.object:get_guid())
            self:_is_valid();
            local owner = nil
            local hash = nil
            local constructor_id = nil
            if staticdata ~= nil and staticdata ~= "" then
                local data = core.parse_json(staticdata)
                if data then
                    owner = data.owner
                    hash = data.hash
                    constructor_id = data.constructor_id
                end
            end
            --core.log(tostring(owner) .. " " .. tostring(constructor_id))
            --local pos = self.object:get_pos()
            self._owner_name = owner
            self._constructor_id = constructor_id
            va_structures.keep_loaded(self)
        end,

        -- deactivation
        on_deactivate = function(self, removal)
            -- core.log("deactivating...")
            if not removal then
                --s:deactivate()
            end
        end,

        on_death = def.on_death or function(self, killer)
            local meta = core.get_meta(self.pos)
            meta:set_int("health", 0)
            self:_dispose(true)
        end,

        on_rightclick = def.on_rightclick or function(self, clicker)

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

return register_structure_entity_ghost
