local base_gravity = -9.81
local jump_length = 1.5
local sight_radius = 10

local animations = {
    -- Standard animations.
    stand     = {x = 1.75,   y = 5.25},
    walk      = {x = 0,  y = 0.5},
    mine 	= {x = 0.54, y = 1.08},
    walk_mine = {x = 1.13, y = 1.67},
}

local update_physics = function (scout)
    if scout._jumping > 0.8 * jump_length then
        return
    end
    local gravity = base_gravity
    local current_acceleration = scout.object:get_acceleration()
    local new_acceleration = {x = current_acceleration.x, y = gravity, z = current_acceleration.z}
    scout.object:set_acceleration(new_acceleration)
end


core.register_entity("va_units:vox_scout_bot", {
    initial_properties = {
        mesh = "vox_scout_bot.gltf",
        textures = {
            "vox_scout_bot.png",
        },
        visual = "mesh",
        visual_size = {x = 1, y = 1},
        collisionbox = {-0.3, 0.0, -0.3, 0.3, 0.4, 0.3},
        selectionbox = {-0.3, 0.0, -0.3, 0.3, 0.4, 0.3},
        stepheight = 0.6,
        physical = true,
        makes_footstep_sound = true,
        static_save = true,
        hp_max = 4,
        nametag = "",
    },
    _target_pos = nil,
    _timer = 0,
    _jumping = 0,
    _animation = animations.stand,
    on_activate = function(self, staticdata, dtime_s)
        if staticdata ~= nil and staticdata ~= "" then
            local data = staticdata:split(';')
           -- todo load data
        end
        self.object:set_animation(self._animation or animations.stand, 1, 0)
    end,
    get_staticdata = function(self)
        return ""
    end,
    on_step = function(self, dtime, moveresult)
        update_physics(self)
        self._timer = self._timer + dtime
       
    end
})

core.register_craftitem("va_units:vox_scout_bot_spawn", {

    description = "VOX Scout Bot",
    inventory_image = "va_units_vox_scout_bot_item.png",
    groups = {spawn_egg = 2, not_in_creative_inventory = 1},
    on_place = function(itemstack, placer, pointed_thing)

        local pos = pointed_thing.above

        -- does existing on_rightclick function exist?
        local under = core.get_node(pointed_thing.under)
        local def = core.registered_nodes[under.name]

        if def and def.on_rightclick then

            return def.on_rightclick(
                    pointed_thing.under, under, placer, itemstack, pointed_thing)
        end

        if pos
        and not core.is_protected(pos, placer:get_player_name()) then            

            pos.y = pos.y + 1

           va_units.spawn_unit("va_units:vox_scout_bot", pos, placer:get_look_yaw())
            itemstack:take_item()
        end

        return itemstack
    end
})
