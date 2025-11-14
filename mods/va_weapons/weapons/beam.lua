core.register_craftitem("va_weapons:beam_ammo", {
    description = "Beam Weapon Ammo",
    inventory_image = "va_weapons_beam.png",
    group = {not_in_creative_inventory=1},
})

local function on_step(self, dtime)
    local lifetime = self._lifetime or 0
    lifetime = lifetime + dtime
    if lifetime >= 10 then
        self.object:remove()
        return
    end
    self._lifetime = lifetime
    local start_pos = self._start_pos
    local dir = self._dir
    if not start_pos or not dir then
        return
    end
    local max_length = self._range or 1.0
    local end_pos = vector.add(start_pos, vector.multiply(dir, max_length))
    local ray = core.raycast(start_pos, end_pos, true, true)
    local hit = false
    local hit_pos = nil
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            hit = true
            local distance = vector.distance(start_pos, pointed_thing.under)
            if not hit_pos or distance < vector.distance(start_pos, hit_pos) then
                hit_pos = pointed_thing.under
            end
        elseif pointed_thing.type == "object" then
            local entity = pointed_thing.ref
            if entity then
                if entity:get_luaentity() and entity:get_luaentity().name ~= "va_weapons:beam" then
                    hit = true
                    local distance = vector.distance(start_pos, pointed_thing.ref:get_pos())
                    if not hit_pos or distance < vector.distance(start_pos, hit_pos) then
                        hit_pos = pointed_thing.ref:get_pos()
                    end
                end
            end            
        end
    end
    local new_length, mid_pos
    if hit and hit_pos then
        new_length = vector.distance(start_pos, hit_pos)
        mid_pos = vector.add(start_pos, vector.multiply(dir, new_length / 2))
    else
        new_length = max_length
        mid_pos = vector.add(start_pos, vector.multiply(dir, new_length / 2))
    end
    self.object:set_properties({
        visual_size = { x = 0.2, y = new_length, z = 0.2}
    })
    self.object:set_pos(mid_pos)
end


local beam = {
    initial_properties = {
        physical = false,
        collide_with_objects = true,
        visual = "wielditem",
        pointable = false,
        wield_item = "va_weapons:beam_ammo",
        glow = 14,
        visual_size = { x = 0.2, y = 1.0, z = 0.2}
    },
    _range = 64,
    _damage = 4,
    _start_pos = nil,
    _last_pos = nil,
    on_activate = function(self, staticdata, dtime_s)
        self._start_pos = self.object:get_pos()
    end,
    on_step = on_step,
}

core.register_entity("va_weapons:beam", beam)

va_weapons.register_weapon("beam", {
    range = 32,
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = base_damage -- no falloff for beam weapons
        -- attach beam entity to shooter
        core.after(0, function()
            core.sound_play("va_weapons_beam", {
                pos = shooter_pos,
                gain = 1.0,
                pitch = 1.0,
            })
            local beam_entity = core.add_entity(shooter_pos, "va_weapons:beam")
            if beam_entity then
                local dir = vector.direction(shooter_pos, target_pos)
                local yaw = core.dir_to_yaw(dir)
                local entity_pitch = math.atan2(dir.y, math.sqrt(dir.x * dir.x + dir.z * dir.z)) - math.pi/2
                beam_entity:set_rotation({x = entity_pitch, y = yaw, z = 0})
                local beam_length = math.min(distance, range)
                beam_entity:set_properties({
                    visual_size = { x = 0.2, y = beam_length, z = 0.2}
                })
                local beam_pos = vector.add(shooter_pos, vector.multiply(dir, beam_length / 2))
                beam_entity:set_pos(beam_pos)
                local luaent = beam_entity:get_luaentity()
                if luaent then
                    luaent._range = range
                    luaent._damage = base_damage
                    luaent._dir = dir -- store original direction
                end
            end
        end)
        return true
    end
})

va_weapons.register_weapon("emp_beam", {
    fire = function(shooter, shooter_pos, target_pos, range, base_damage)
        local distance = vector.distance(shooter_pos, target_pos)
        if distance > range then
            return false
        end
        local damage = 0 -- EMP does not deal direct damage
        local emp_duration = 3 / base_damage
        -- Fire the EMP beam and deal damage
        core.after(0, function()
            core.sound_play("va_weapons_beam", {
                pos = shooter_pos,
                gain = 1.0,
                pitch = 1.0,
            })
        end)
        return true
    end
})