
local function register_structure_entity(def)
    -- display entity shown for structure
    core.register_entity(def.entity_name, {
        initial_properties = {
            physical = false,
            collisionbox = {-0.75, -0.75, -0.75, 0.75, 0.75, 0.75},
            hp = def.meta.max_health,
            hp_max = def.meta.max_health,
             -- TODO: setup texture and mesh
            visual = "mesh",
            mesh = "va_solar_collector_1.gltf",
            textures = {"va_vox_solar_collector_2.png"},
            visual_size = {x=1.5, y=1.5},
            glow = 2,
            infotext = "HP: " .. tostring(def.meta.max_health) .. "/" .. tostring(def.meta.max_health) .. ""
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

        on_step = function(self, dtime)
            self._timer = self._timer + 1
            if self._timer < 10 then
                return
            end
            self._timer = 0
            local pos = self.object:get_pos()
            local node = core.get_node(pos)
            if node and not node.name == def.fqnn then
                self.object:remove()
                return
            end
            if self._marked_for_removal then
                self.object:remove()
            end
            --process_queue(self)
            --update_visibility(self)
        end,

        on_death = function(self, killer)
            local pos = self.object:get_pos()
            core.get_node_timer(self.pos):start(30)
            local meta = core.get_meta(self.pos)
            meta:set_int("broken", 1)
            meta:set_int("health", 0)
        end,

        on_rightclick = function(self, clicker)
            local pos = self.object:get_pos();
            if pos then
                -- self.object:remove()
                self.object:set_properties({
                    is_visible = false
                })
                core.get_node_timer(pos):start(3)
            end
        end,

        on_punch = function(puncher, time_from_last_punch, tool_capabilities, direction, damage)

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