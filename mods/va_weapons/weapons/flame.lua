local handles = {}

local fire_def = {
    initial_properties = {
        physical = true,
        collide_with_objects = false,
        visual = "sprite",
        visual_size = {x = 1, y = 1},
        textures = {"fire_basic_flame_animated.png"},
        spritediv = {x = 1, y = 8},
        collisionbox = {-0.25, -0.25, -0.25, 0.25, 0.25, 0.25},
        pointable = false,
        glow = 14,
    },
    _start_pos = nil,
    _range = 16,
    _damage = 0,
    _burn_duration = 3,
    on_activate = function(self, staticdata, dtime_s)
        self._lifetime = 0
    end,
    on_step = function(self, dtime)
        local lifetime = self._lifetime or 0
        lifetime = lifetime + dtime
        if lifetime >= self._burn_duration then
            self.object:remove()
            return
        end
        self._lifetime = lifetime
        --update flame animation frame
        local fps = 8
        local frame = math.floor(lifetime * fps)
        if frame > 7 then frame = 7 end
        if self._last_frame ~= frame then
            self.object:set_sprite({x=0, y=frame}, 8, 1/fps, false)
            self._last_frame = frame
        end
        local pos = self.object:get_pos()
        if not pos then
            return
        end
        local light_pos = vector.round(pos)
        local node = core.get_node(light_pos)
        local light_level = math.random(10, 14)
        if node and node.name ~= "air" and node.name ~= "va_weapons:dummy_light_" .. light_level then
            return
        end
        core.set_node(light_pos, {name = "va_weapons:dummy_light_" .. light_level})
        -- remove the light node after a short delay
        core.after(0.1, function()
            node = core.get_node(light_pos)
            if node and node.name == "va_weapons:dummy_light_" .. light_level then
                core.remove_node(light_pos)
            end
        end)
        -- if entity is not moving down stop here
        local vel = self.object:get_velocity()
        if vel and vel.y == 0 then
            self.object:set_velocity({x=0, y=0, z=0})
        end
        
    end,
}
core.register_entity("va_weapons:flame", fire_def)

va_weapons.register_weapon("flame", {
    range = 16,
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage
        local burn_duration = range / 4
        -- Fire the flame and deal damage over time
        local gain = 1.0
        local pitch = 1.0
        local player_name = shooter:get_player_name() or ""
        if handles[player_name] then
            core.sound_fade(handles[player_name], 1, 0)
            handles[player_name] = nil
        end
        core.after(0, function()
            core.sound_play("va_weapons_flame", {
                pos = shooter_pos,
                gain = gain,
                pitch = pitch,
            })
            local base_dir = vector.direction(shooter_pos, target_pos)
            local flame_length = math.min(distance, range)
            local step_distance = 1
            local fan_count = 2 -- number of flame branches
            local spread_angle = math.rad(5) -- total spread in radians
            for i = 1, fan_count do
                local angle = spread_angle * ((i - 1) / (fan_count - 1) - 0.5)
                -- Add random offset to horizontal angle (yaw)
                angle = angle + (math.random() - 0.5) * math.rad(1)
                -- Add random offset to vertical angle (pitch)
                local p = (math.random() - 0.5) * math.rad(10)
                local flame_dir = vector.rotate(base_dir, {x=p, y=angle, z=0})
                for d = 0, flame_length, step_distance do
                    core.after(d / 10, function()
                        -- Add random offset to each flame position for noisy spread
                        local offset = {
                            x = (math.random() - 0.5) * 1.0,
                            y = (math.random() - 0.5) * 1.0,
                            z = (math.random() - 0.5) * 1.0
                        }
                        local flame_pos = vector.add(shooter_pos, vector.add(vector.multiply(flame_dir, d), offset))
                        local flame_entity = core.add_entity(flame_pos, "va_weapons:flame")
                        if flame_entity then
                            local dir = vector.direction(shooter_pos, target_pos)
                            flame_entity:set_velocity(vector.multiply(dir, 15))
                            physics_api.update_physics(flame_entity)
                            local luaent = flame_entity:get_luaentity()
                            if luaent then
                                luaent._range = range
                                luaent._damage = base_damage
                                luaent._start_pos = shooter_pos
                                luaent._burn_duration = burn_duration
                            end
                            
                        end
                    end)
                end
            end
        end)
    end
})