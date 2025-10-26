local function round(v)
    return math.floor(v + 0.5)
end

-- Localize this functions for better performance,
-- as it's called on every step
local vector_distance = vector.distance

local texture_base = "construction_bar_0b.png"
local texture_build = "construction_bar_fullb.png"

local function add_structure_gauge(structure)
    if structure and structure.entity_obj then
        local s_ent = structure.entity_obj
        local entity = minetest.add_entity(structure.pos, "va_structures:build_bar")
        local s_h = math.max(structure.size.y, 0.25)
        local height = 8.5 + (s_h * 10)
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

local function register_structure_gauge()
    core.register_entity("va_structures:build_bar", {

        initial_properties = {
            visual = "sprite",
            visual_size = {
                x = 1.0,
                y = 0.1,
                z = 1.0
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

            local c_index = structure.construction_tick
            local c_max = structure.construction_tick_max

            if c_index ~= self.construction_index then

                local prog = math.floor((c_index / c_max) * 100)
                local build_t = texture_base

                build_t = build_t .. "^[lowpart:"..prog..":".. texture_build
                build_t = build_t .. "^[transformR270]"

                if c_index <= 0 then
                    build_t = "blank.png"
                end

                gauge:set_properties({
                    textures = {build_t}
                })
                self.construction_index = c_index
            end

            if c_index >= c_max then
                gauge:remove()
            end
        end
    })
end

return register_structure_gauge, add_structure_gauge
