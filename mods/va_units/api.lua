va_units = {}
va_units.registered_models = {}


local units = {}

local function update_physics(unit)
    local object = unit.object
    if not object then
        return 
    end
    physics_api.update_physics(object)
end

function va_units.register_unit(name, def)
    units["va_units:" .. name] = def
    core.register_entity("va_units:" .. name, {
        initial_properties = {
            mesh = def.mesh or name .. ".gltf",
            textures = {
                def.texture or name .. ".png",
            },
            visual = "mesh",
            visual_size = def.visual_size or { x = 1, y = 1 },
            collisionbox = def.collisionbox ~= nil and def.collisionbox or { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
            selectionbox = def.selectionbox ~= nil and def.selectionbox or { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
            stepheight = def.stepheight or 0.6,
            physical = def.physical ~= nil and def.physical or true,
            collide_with_objects = def.collide_with_objects ~= nil and def.collide_with_objects or true,
            makes_footstep_sound = def.makes_footstep_sound ~= nil and def.makes_footstep_sound or true,
            static_save = true,
            hp_max = def.hp_max or 1,
            nametag = def.nametag or "",
        },
        _target_pos = nil,
        _timer = 0,
        _jumping = 0,
        _animation = def.animations.stand,
        _owner_name = nil,
        on_activate = def.on_activate or function(self, staticdata, dtime_s)
            local animations = def.animations
            if staticdata ~= nil and staticdata ~= "" then
                local data = staticdata:split(';')
                self._owner_name = (type(data[1]) == "string" and #data[1] > 0) and data[1] or nil
            end
            self.object:set_animation(self._animation or animations.stand, 1, 0)
        end,
        get_staticdata = def.get_staticdata or function(self)
            return self._owner_name or ""
        end,
        on_step = def.on_step or function(self, dtime, moveresult)
            if not self.object then
                core.log("error", "on_step: self.object is nil for entity " .. tostring(self))
                return
            end
            update_physics(self)
            self._timer = self._timer + dtime
        end
    })

    core.register_craftitem("va_units:" .. name .. "_spawn", {
        description = def.spawn_item_description,
        inventory_image = def.item_inventory_image or ("va_units_" .. name .. "_item.png"),
        groups = { spawn_egg = 2, not_in_creative_inventory = 1 },
        on_place = function(itemstack, placer, pointed_thing)
            local pos = pointed_thing.above

            local under = core.get_node(pointed_thing.under)
            local def = core.registered_nodes[under.name]

            if def and def.on_rightclick then
                return def.on_rightclick(
                    pointed_thing.under, under, placer, itemstack, pointed_thing)
            end

            if pos
                and not core.is_protected(pos, placer:get_player_name()) then
                pos.y = pos.y + 1

                va_units.spawn_unit("va_units:" .. name, placer:get_player_name(), pos, placer:get_look_yaw())
                itemstack:take_item()
            end

            return itemstack
        end
    })

    player_api.register_model(def.mesh or name .. ".gltf", {
        mesh = def.mesh or name .. ".gltf",
        textures = { def.texture or name .. ".png" },
        visual_size = def.visual_size or { x = 1, y = 1 },
        stepheight = def.stepheight or 0.6,
        animations = def.animations or {},
        animation_speed = def.animation_speed or 30,
    })

    core.register_craftitem("va_units:" .. name .. "_test", {
        description = def.spawn_item_description,
        inventory_image = def.item_inventory_image or ("va_units_" .. name .. "_item.png"),
        groups = { spawn_egg = 2, not_in_creative_inventory = 1 },
        on_place = function(itemstack, placer, pointed_thing)

            local under = core.get_node(pointed_thing.under)
            local def = core.registered_nodes[under.name]

            if def and def.on_rightclick then
                return def.on_rightclick(
                    pointed_thing.under, under, placer, itemstack, pointed_thing)
            end
            local model = "va_units_" .. name .. ".gltf"
            if not player_api then
                core.log("error", "player_api is not loaded!")
                return itemstack
            end
            core.log("action", "Setting player model to: " .. model)
            player_api.set_model(placer, model)
            itemstack:take_item()

            return itemstack
        end
    })

    
end

function va_units.spawn_unit(unit_name, owner_name, pos)
    local registered_def = units[unit_name]
    if not registered_def then
        return nil
    end
    local obj = core.add_entity(pos, unit_name, owner_name)
    return obj
end

function va_units.globalstep(dtime)
    -- Update all units
end

core.register_globalstep(function(...)
    va_units.globalstep(...)
end)
