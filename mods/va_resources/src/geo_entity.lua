local function round(v)
    return math.floor(v + 0.5)
end

local vector_distance = vector.distance
local gauge_max = {
    shield = 11,
    health = 20
}

local ent_name = "va_resources:resource_geo_indicator"

local function add_resource_indicator(pos)
    local objs = core.get_objects_inside_radius(pos, 0.05)
    for _, obj in pairs(objs) do
        if obj:get_luaentity() then
            local ent = obj:get_luaentity()
            if ent.name == ent_name then
                obj:remove()
            end
        end
    end
    local entity = core.add_entity(pos, ent_name)
end

local is_player_near = function(pos)
    local objs = core.get_objects_inside_radius(pos, 48)
    for _, obj in pairs(objs) do
        if obj:is_player() then
            return true;
        end
    end
    return false;
end

local function register_geo_indicator()
    core.register_entity(ent_name, {

        initial_properties = {
            visual = "mesh",
            mesh = "va_resource_circle_1.gltf",
            textures = {"va_resource_geo_ring_1.png"},
            use_texture_alpha = true,
            collisionbox = {0},
            visual_size = {
                x = 1.9,
                y = 1.9
            },
            type = "va_indicator",
            glow = 7,
            physical = false,
            static_save = false            
        },

        _timer = 1,

        -- activation
        on_activate = function(self, staticdata, dtime_s)
            local pos = self.object:get_pos()
        end,

        on_step = function(self)
            self._timer = self._timer + 1
            if self._timer < 20 then
                return
            end
            self._timer = 0
            local obj = self.object
            local pos = self.object:get_pos()
            local node = core.get_node(pos)
            local g = core.get_item_group(node.name, "va_geo_vent")
            if not g then
                obj:remove();
                return
            end
        end
    })
end

register_geo_indicator()

va_resources.add_geo_indicator = add_resource_indicator
