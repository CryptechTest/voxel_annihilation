local function round(v)
    return math.floor(v + 0.5)
end

-- Localize this functions for better performance,
-- as it's called on every step
local vector_distance = vector.distance
local gauge_max = {
    shield = 11,
    hp = 20
}

local function attach_unit_gauge(unit)
    if unit and unit:get_luaentity() then
        local s_ent = unit:get_luaentity()
        local pos = unit:get_pos()
        local entity = core.add_entity(pos, "va_units:hp_bar")
        local colbox = unit:get_properties().collisionbox or { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
        local s_h = math.max(colbox[5], 0.25)
        local height = 0 + (s_h * 10)
        entity:set_attach(unit, "", {
            x = 0,
            y = height,
            z = 0
        }, {
            x = 0,
            y = 0,
            z = 0
        })
        entity:get_luaentity().wielder = unit
        entity:get_luaentity():_set_unit(s_ent)
    end
end

local function scaleToDefault(unit, field)
    local meta = unit.object
    local current = meta["get_" .. field](meta)
    --local max = meta["get_" .. field .. "_max"](meta)
    local unit_def = va_units.get_unit_def(unit.object:get_luaentity().name)
    local max = unit_def.hp_max
    if current == max then
        return -2
    elseif max <= 0 then
        return -1
    end
    local max_display = math.max(max, current)
    return round(current / max_display * gauge_max[field])
end

local function register_unit_gauge()
    core.register_entity("va_units:hp_bar", {

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
            static_save = true,
        },

        _unit = nil,
        _unit_id = nil,

        _set_unit = function(self, s)
            self._unit = s
        end,

        get_staticdata = function(self)
            return core.write_json({
                attached_entity_id = self._unit_id
            })
        end,

        -- activation
        on_activate = function(self, staticdata, dtime_s)
            local attached_entity_id = nil
            if staticdata ~= nil and staticdata ~= "" then
                local data = core.parse_json(staticdata)
                if data then
                    attached_entity_id = data.attached_entity_id
                end
            end
            if attached_entity_id then
                local unit = va_units.get_unit_by_id(attached_entity_id)
                if unit then
                    self._unit_id = attached_entity_id
                    self:_set_unit(unit)
                end
            end
        end,

        on_step = function(self)
            local unit = self._unit
            local owner = self.wielder
            local gauge = self.object

            if unit then
                if unit.object:get_hp() <= 0 then
                    gauge:remove()
                    return
                end
            end

            if not owner or not owner:get_pos() or not gauge or not gauge:get_pos() then
                gauge:remove()
                return
            end

            if not unit then
                gauge:remove()
                return
            elseif vector_distance(owner:get_pos(), gauge:get_pos()) > 3 then
                gauge:remove()
                attach_unit_gauge(owner)
                return
            end

            local hp = scaleToDefault(unit, "hp")
            local shield = 0 --scaleToDefault(unit, "shield")

            if self.hp ~= hp or self.shield ~= shield then
                local health_t = hp > 0 and "health_" .. hp .. ".png" or ''
                local shield_t = shield > 0 and "breath_" .. shield .. ".png" or ''

                if hp == 0 or hp == -2 then
                    health_t = "blank.png"
                end

                if shield == gauge_max.shield then
                    shield_t = "blank.png"
                end

                if unit.last_hit == 0 then
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

return register_unit_gauge, attach_unit_gauge
