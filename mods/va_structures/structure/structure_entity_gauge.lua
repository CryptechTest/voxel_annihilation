-- gauges: Adds health/breath bars above players
--
-- Copyright © 2014-2020 4aiman, Hugo Locurcio and contributors - MIT License
-- See `LICENSE.md` included in the source distribution for details.
local function round(v)
    return math.floor(v + 0.5)
end

-- Localize this functions for better performance,
-- as it's called on every step
local vector_distance = vector.distance
local gauge_max = {
    shield = 11,
    health = 20
}

local function add_structure_gauge(structure)
    if structure and structure.entity_obj then
        local s_ent = structure.entity_obj
        local entity = minetest.add_entity(structure.pos, "va_structures:hp_bar")
        local s_h = math.max(structure.size.y, 0.25)
        local height = 7 + (s_h * 10)
        entity:set_attach(s_ent, "", {
            x = 0,
            y = height,
            z = 0
        }, {
            x = 0,
            y = 0,
            z = 0
        })
        entity:get_luaentity().wielder = s_ent
        entity:get_luaentity():_set_structure(structure)
    end
end

local function scaleToDefault(structure, field)
    local meta = structure:get_data()
    -- Scale "hp" or "breath" to supported amount
    local current = meta["get_" .. field](meta)
    local max = meta["get_max_" .. field](meta)
    if current == max then
        return -2
    elseif max <= 0 then
        return -1
    end
    local max_display = math.max(max, current)
    return round(current / max_display * gauge_max[field])
end

local function register_structure_gauge()
    core.register_entity("va_structures:hp_bar", {

        initial_properties = {
            visual = "sprite",
            visual_size = {
                x = 1.05,
                y = 0.095,
                z = 1.05
            },
            textures = {"blank.png"},
            glow = 9,
            collisionbox = {0},
            physical = false,
            static_save = false
        },

        _structure = nil,

        _set_structure = function(self, s)
            self._structure = s
        end,

        -- activation
        on_activate = function(self, staticdata, dtime_s)
            local pos = self.object:get_pos()
            local s = va_structures.get_active_structure(pos)
            if s then
                self:_set_structure(s)
            end
        end,

        on_step = function(self)
            local structure = self._structure
            local owner = self.wielder
            local gauge = self.object

            if structure then
                if structure:get_hp() <= 0 then
                    gauge:remove()
                    return
                end
            end

            if not owner or not owner:get_pos() or not gauge or not gauge:get_pos() then
                gauge:remove()
                return
            end

            if not structure then
                gauge:remove()
                return
            elseif vector_distance(owner:get_pos(), gauge:get_pos()) > 3 then
                gauge:remove()
                add_structure_gauge(owner)
                return
            end

            local hp = scaleToDefault(structure, "health")
            local shield = scaleToDefault(structure, "shield")

            if self.hp ~= hp or self.shield ~= shield then
                local health_t = hp > 0 and "health_" .. hp .. ".png" or ''
                local shield_t = shield > 0 and "breath_" .. shield .. ".png" or ''

                if hp == 0 or hp == -2 then
                    health_t = "blank.png"
                end

                if shield == gauge_max.shield then
                    shield_t = "blank.png"
                end

                if structure.last_hit == 0 then
                    health_t = "blank.png"
                end

                gauge:set_properties({
                    textures = {health_t .. "^" .. shield_t}
                })
                self.hp = hp
                self.shield = shield
            end
        end
    })
end

return register_structure_gauge, add_structure_gauge
