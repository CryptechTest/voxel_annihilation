-----------------------------------------------------------------
-----------------------------------------------------------------
--- structures
-- entity attached to pos
-- pos stores metadata about self...
-- invisible 1/16 nodebox tile
-- has a volume (all)
-- whole volume footprint must be on solid ground
-- is either of type: build, combat, economy, utility
-- can be damaged/destroyed by explosion (all)
-- are volatile (all)
-- death explosion radius (all)
-- self-destruct explosion radius (all)
-- has self-destruct countdown (all)
-- takes damage (all)
-- can build structures based on a list (some)
-- can build units based on a list (some)
-- has build power (some)
-- has construction distance (some)
-- has health (all)
-- has armor (all)
-- has mass cost during construct (all)
-- has energy cost during construct (all)
-- has vision radius (all)
-- has radar radius (some)
-- has anti-radar radius (some)
-- has attack distance (some)
-- has attack power (some)
-- has attack type (some)
-- has faction
-- consumes energy/mass based on build power (some)
-- generates energy/mass based on resource or enviroment (some)
-- are upgradable to higher tier (some - if available)
--
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
local StructureMetaData = dofile(modpath .. "/structure/structure_meta.lua")
local register_structure_node = dofile(modpath .. "/structure/structure_node.lua")
local register_structure_entity = dofile(modpath .. "/structure/structure_entity.lua")
local _, attach_structure_gauge = dofile(modpath .. "/structure/structure_entity_gauge.lua")
local _, attach_structure_build = dofile(modpath .. "/structure/structure_entity_build.lua")

-----------------------------------------------------------------
-----------------------------------------------------------------
-----------------------------------------------------------------
-- Define the base structure class
local Structure = {}
Structure.__index = Structure

local modname = core.get_current_modname()

function Structure.new(pos, name, def, do_def_check)
    local self = setmetatable({}, Structure)
    self.pos = pos -- position of structure in world
    self.name = name or "base_structure" -- name of this structure
    self.desc = def.desc or "Abstract Structure" -- description of this structure
    self.size = def.size or {1, 0, 1} -- structure area size
    def.fqnn = modname .. ":" .. def.faction .. "_" .. self.name
    self.fqnn = def.fqnn -- fully qualified node name
    def.entity_name = def and def.entity_name or self.fqnn .. "_entity"
    self.entity_name = def.entity_name -- name of entity attached
    self.entity_obj = nil -- object corresponding to attached entity
    self.category = def.category or "none" -- build, combat, economy, utility
    self.water_type = def.water_type or false -- flag for water structures
    self.tier = def.tier -- tech tier of this structure
    self.faction = def.faction -- faction teams: 'vox' and 'cube'
    self.owner = nil -- owner player name
    self.owner_actor = nil -- owner player actor
    local w = (self.size.x * 2) + 1
    local l = (self.size.z * 2) + 1
    local h = (self.size.y * 2) + 1
    self.volume = w * l * h -- volume size
    self.do_rotate = true
    if def.do_rotate == false then
        self.do_rotate = false
    end

    -- use or build default metadata
    self.meta = StructureMetaData.new(def)

    -- external functions
    self.vas_run_pre = def.vas_run_pre or nil
    self.vas_run_post = def.vas_run_post or nil
    self.destroy_post_effects = def.destroy_post_effects or nil

    -- construction step vars
    self.build_time = def.build_time
    self.construction_tick_max = def.build_time or 10 -- max ticks to build structure
    self.construction_tick = 0
    self.is_contructed = false
    self.build_power_total = 10

    self.last_hit = 0 -- last time structure was hit by player

    -- validitiy flags
    self._active = false
    self._defined = false
    if do_def_check then
        self._defined = va_structures.is_registered_structure(self.fqnn)
    end

    -- check for valid placement location
    self.check_placement = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return itemstack
        end
        local pos = pointed_thing.above
        local name = placer:get_player_name()
        if self:collides_solid(pos) then
            minetest.chat_send_player(name, "Structure requires more room.")
            return itemstack
        elseif not self.water_type and not self:collides_has_floor(pos) then
            minetest.chat_send_player(name, "Structure requires more floor room.")
            return itemstack
        elseif not self.water_type and self:collides_liquid(pos) then
            minetest.chat_send_player(name, "Structure must be built on land.")
            return itemstack
        elseif self.water_type and not self:collides_has_floor_water(pos) then
            minetest.chat_send_player(name, "Structure must be built on water.")
            return itemstack
        elseif self:collides_other(pos, self.size) then
            -- make sure structure doesn't overlap any other structure area
            minetest.chat_send_player(name, "Structure overlaps into another structure area.")
            return itemstack
        end
        return minetest.item_place(itemstack, placer, pointed_thing)
    end

    return self
end

function Structure.register(def)
    if not def then
        return
    end
    local structure = Structure.new(nil, def.name, def)
    structure.after_place_node = def.after_place_node
    structure.after_dig_node = def.after_dig_node
    structure.vas_run = def.vas_run
    local result = register_structure_node(structure) and register_structure_entity(def)
    if result then
        va_structures.register_structure(structure)
        -- core.log('registered strucutre: ' .. structure.fqnn)
    end
end

function Structure.after_place_node(pos, placer, itemstack, pointed_thing)
    local node_name = core.get_node(pos).name
    if not va_structures.is_registered_structure(node_name) then
        return
    end
    -- local s = va_structures.get_new(pos, node_name)
    local def = va_structures.get_registered_structure(node_name)
    local s = Structure.new(pos, def.name, def, true)
    s:set_hp(1)
    if placer:is_player() then
        s.owner = placer:get_player_name()
    end
    va_structures.add_player_structure(s)
    va_structures.add_active_structure(pos, s)
    s:activate()
    attach_structure_build(s)
    attach_structure_gauge(s)
end

function Structure.after_dig_node(pos, oldnode, oldmetadata, digger)
    local s = va_structures.get_active_structure(pos)
    if s then
        s:dispose();
    end
end

-----------------------------------------------------------------
-- collision checks

function Structure:collides_with(pos)
    local pos1 = vector.add(self.pos, self.size)
    local pos2 = vector.subtract(self.pos, self.size)
    -- Check if pos is within the bounds of pos1 and pos2
    local m_x = (pos.x >= pos2.x and pos.x <= pos1.x)
    local m_y = (pos.y >= pos2.y and pos.y <= pos1.y)
    local m_z = (pos.z >= pos2.z and pos.z <= pos1.z)
    return (m_x and m_y and m_z) or false
end

function Structure:collides_other(pos, size)
    local size = vector.new(size)
    if size.y == 0 then
        size.y = 0.5
    end
    local _size = vector.multiply(size, 2)
    local pos1 = vector.add(pos, _size)
    local pos2 = vector.subtract(pos, _size)
    local structures = core.find_nodes_in_area(pos1, pos2, "group:va_structure")
    for _, s_pos in pairs(structures) do
        local s = va_structures.get_active_structure(s_pos)
        if s then
            if s:collides_with(pos) then
                return true
            end
            local s_pos1 = vector.subtract(pos, size)
            local s_pos2 = vector.add(pos, size)
            for y = s_pos1.y - 0.5, s_pos2.y + 0.5 do
                for x = s_pos1.x, s_pos2.x do
                    for z = s_pos1.z, s_pos2.z do
                        local n_pos = vector.new(x, y, z)
                        if s:collides_with(n_pos) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

function Structure:collides_solid(pos)
    local _size = vector.new(self.size)
    if _size.y == 0 then
        _size.y = 0.5
    end
    local pos1 = vector.add(pos, _size)
    local pos2 = vector.subtract(pos, {x=_size.x,y=0,z=_size.z})
    local nodes = core.find_nodes_in_area(pos1, pos2, {"group:cracky", "group:crumbly", "group:choppy"})
    for _, node in pairs(nodes) do
        local node = core.get_node(node)
        local def = core.registered_nodes[node.name]
        if def.walkable == true and def.buildable_to == false then
            return true
        end
    end
    return false
end

function Structure:collides_liquid(pos)
    local _size = vector.new(self.size)
    if _size.y == 0 then
        _size.y = 0.5
    end
    local pos1 = vector.add(pos, _size)
    local pos2 = vector.subtract(pos, _size)
    local nodes = core.find_nodes_in_area(pos1, pos2, {"group:liquid", "group:water"})
    return #nodes > 0
end

function Structure:collides_has_floor_water(pos)
    local f_pos = vector.new(pos)
    f_pos.y = f_pos.y - 1
    local size = vector.new(self.size.x, 0, self.size.z)
    local pos1 = vector.add(f_pos, size)
    local pos2 = vector.subtract(f_pos, size)
    local nodes = core.find_nodes_in_area(pos1, pos2, {"group:liquid", "group:water"})
    local vol = ((self.size.x * 2) + 1) * ((self.size.z * 2) + 1)
    return #nodes >= vol
end

function Structure:collides_has_floor(pos)
    local f_pos = vector.new(pos)
    f_pos.y = f_pos.y - 1
    local size = vector.new(self.size.x, 0, self.size.z)
    local pos1 = vector.add(f_pos, size)
    local pos2 = vector.subtract(f_pos, size)
    local nodes = core.find_nodes_in_area(pos1, pos2,
        {"group:cracky", "group:crumbly", "group:choppy", "group:soil", "group:sand"})
    local vol = ((self.size.x * 2) + 1) * ((self.size.z * 2) + 1)
    return #nodes >= vol
end

-----------------------------------------------------------------
-- run functions

function Structure:run_pre(run_stage, net)
    -- core.log("structure run_internal() ticked... " .. self.name)
    if self.vas_run_pre then
        self.vas_run_pre(self)
    end
    if self:get_hp() <= 0 then
        self:destroy()
        return false
    end
    if self.owner_actor == nil and net ~= nil then
        self.owner_actor = net
    end
    if self:construct(net) then
        self:build_assist_reset()
        return false
    end
    if self:do_destruct_self() then
        return false
    end
    return true
end

function Structure:run_post(run_stage, net)
    self:entity_tick()
    if self.vas_run_post then
        self.vas_run_post(self)
    end
end

-----------------------------------------------------------------
-- local methods

function Structure:equals(structure)
    if not structure then
        return false
    end
    local s_hash = core.hash_node_position(self.pos)
    local o_hash = core.hash_node_position(structure.pos)
    return s_hash == o_hash
end

function Structure:getInfo()
    local info = {
        pos = self.pos,
        name = self.fqnn
    }
    return info
end

function Structure:is_valid()
    return self._defined
end

function Structure:is_active()
    return self._active
end

function Structure:hash()
    if not self.pos then
        return "0"
    end
    return tostring(core.hash_node_position(self.pos))
end

function Structure:get_data()
    return self.meta
end

function Structure:get_entity()
    return self.entity_obj:get_luaentity()
end

function Structure:get_hp()
    return self.meta:get_health()
end

function Structure:set_hp(val)
    self.meta:set_health(val)
end

function Structure:get_hp_max()
    return self.meta:get_max_health()
end

function Structure:can_store_energy()
    return (self.is_contructed and self.meta:get_energy_storage() > 0)
end

function Structure:can_store_mass()
    return (self.is_contructed and self.meta:get_mass_storage() > 0)
end

function Structure:get_build_step()
    return self.build_power_total
end

function Structure:build_assist_reset()
    self.build_power_total = 10 -- 1 second
end

function Structure:build_assist(amount_power)
    self.build_power_total = self.build_power_total + amount_power
end

function Structure:place(pos, param2)
    self.pos = pos
    core.set_node(self.pos, {
        name = self.fqnn,
        param2 = param2
    })
end

function Structure:dispose()
    va_structures.remove_active_structure(self.pos)
    if self.entity_obj then
        local ent = self.entity_obj:get_luaentity()
        if ent then
            ent:_dispose(true)
        end
    else
        core.remove_node(self.pos)
    end
end

function Structure:deactivate()
    local pos = self.pos
    local meta = core.get_meta(pos)
    meta:set_int("active", 0)
    self._active = false
end

function Structure:activate(visible)
    if self._active then
        return
    end
    self._active = true
    if self.entity_obj then
        self.entity_obj:remove()
        self.entity_obj = nil
    end
    -- core.log("activated structure")
    local visible = visible or false
    local pos = self.pos
    local hash = core.hash_node_position(pos)
    local meta = core.get_meta(pos)
    meta:set_int("active", 1)
    local obj = core.add_entity(pos, self.entity_name, nil)
    if obj then
        local yawRad, rotation = self:get_yaw()
        local rot = {
            x = 0,
            y = yawRad,
            z = 0
        }
        obj:set_rotation(rot)
        local ent = obj:get_luaentity()
        ent._owner_hash = tostring(hash)
        ent._owner_name = self.owner
        if not self.is_contructed then
            visible = false
        end
        obj:set_properties({
            is_visible = visible
        })
        self.entity_obj = obj
    else
        meta:set_int("active", 0)
        self._active = false
    end
end

function Structure:construct(actor)
    if self.is_contructed then
        return false
    end
    local pos = self.pos
    local meta = core.get_meta(pos)
    if self.construction_tick >= self.construction_tick_max then
        self.is_contructed = true
        meta:set_int('is_contructed', 1)
        if self.entity_obj then
            self.entity_obj:set_properties({
                is_visible = true
            })
        end
        return false
    end
    local build_power = math.min(10, self:get_build_step())
    local has_resources = false
    if actor then
        local mass_cost = self:get_data():get_mass_cost()
        local energy_cost = self:get_data():get_energy_cost()
        local mass_cost_rate = mass_cost > 0 and math.floor((mass_cost / self.construction_tick_max) * 10000) * 0.0001 or 0
        local energy_cost_rate =
            energy_cost > 0 and math.floor((energy_cost / self.construction_tick_max) * 10000) * 0.0001 or 0
        mass_cost_rate = mass_cost_rate * build_power
        energy_cost_rate = energy_cost_rate * build_power
        local mass = actor.mass
        local energy = actor.energy
        if mass - mass_cost_rate >= 0 and energy - energy_cost_rate >= 0 then
            if mass_cost_rate > 0 then
                actor.mass = mass - mass_cost_rate
            end
            if energy_cost_rate > 0 then
                actor.energy = energy - energy_cost_rate
            end
            has_resources = true
        end
        if energy - energy_cost_rate >= 0 then
            actor.mass_demand = actor.mass_demand + mass_cost_rate
        end
        if mass - mass_cost_rate >= 0 then
            actor.energy_demand = actor.energy_demand + energy_cost_rate
        end
    end
    if has_resources then
        local max_hp = self:get_hp_max()
        local hp = self:get_hp()
        if hp < max_hp then
            local step = max_hp / self.construction_tick_max
            step = step * build_power
            local hp = math.floor(math.min(max_hp, hp + step + 0.01) * 100) * 0.01
            self:set_hp(hp)
        end
    end
    local dist = 0.75 + math.max(1, self.size.y * 2)
    if not has_resources then
        va_structures.particle_build_effect_halt(pos, dist)
        return true
    end
    self.construction_tick = self.construction_tick + (build_power * 1)
    va_structures.particle_build_effect(pos, dist)
    return true
end

-- destroy structure
function Structure:destroy()
    if self.entity_obj then
        self.entity_obj:set_properties({
            is_visible = false
        })
    end
    -- core.log("structure destroyed... " .. self.name)
    core.after(0.1, function()
        self:dispose()
    end)
    if self.is_contructed then
        self:explode()
        if self.destroy_post_effects then
            self.destroy_post_effects(self)
        end
    else
        va_structures.particle_build_effect_cancel(self.pos, 3)
    end
end

function Structure:do_destruct_self()
    if self:get_data():is_self_destructing() then
        local c_max = self:get_data():get_self_countdown_max()
        local c = self:get_data():get_self_countdown()
        if c <= 0 then
            self:destroy()
            return true
        else
            self:get_data():set_self_countdown(c - 1)
        end
    end
    return false
end

function Structure:damage(amount, d_type)
    if self:get_data().is_vulnerable then
        local amount = math.floor(amount * 100) * 0.01
        -- TODO: armor handling
        local hp = self:get_hp()
        self:set_hp(hp - amount)
        self.last_hit = core.get_us_time()
    end
end

function Structure:explode()
    local meta = self:get_data()
    local s_d = meta:is_self_destructing()
    local ds = meta.self_explosion_radius
    local de = meta.death_explosion_radius
    local dist = (s_d and ds or de) + 3

    if meta.is_volatile then
        local pos = self.pos
        local objs = minetest.get_objects_inside_radius(pos, dist + 0.55)
        for _, obj in pairs(objs) do
            local o_pos = obj:get_pos()
            if obj:get_luaentity() then
                local ent = obj:get_luaentity()
                local structure = va_structures.get_active_structure(o_pos)
                if structure and not self:equals(structure) then
                    local d = vector.distance(pos, o_pos)
                    local dam = 1 + (dist - math.min(dist, (d / dist))) * 0.1
                    structure:damage(dam, "kinetic")
                end
            end
        end
    end

    local r = math.max(self.size.y, math.max(self.size.x, self.size.z))
    va_structures.destroy_effect_particle(self.pos, (r + dist) * 0.5)
    va_structures.explode_effect_sound(self.pos, (r + dist) * 0.5)
end

-----------------------------------------------------------------
-- tick checks

function Structure:get_yaw()
    if not self.do_rotate then
        return 0, 0
    end
    local pos = self.pos
    local pi = math.pi
    local rotation = minetest.get_node(pos).param2
    if rotation > 3 then
        rotation = rotation % 4 -- Mask colorfacedir values
    end
    if rotation == 1 then
        return pi / 2, rotation
    elseif rotation == 3 then
        return -pi / 2, rotation
    elseif rotation == 0 then
        return pi, rotation
    else
        return 0, rotation
    end
end

function Structure:entity_tick()
    if not self._active then
        return
    end
    local e_pos = self.pos
    local found_display = false
    local yawRad, rotation = self:get_yaw()
    local objs = minetest.get_objects_inside_radius(e_pos, 0.05)
    for _, obj in pairs(objs) do
        if obj:get_luaentity() then
            local ent = obj:get_luaentity()
            if ent.name == self.entity_name then
                if found_display then
                    obj:remove()
                end
                found_display = true
            end
        end
    end
    if not found_display then
        if not self.entity_obj then
            self.entity_obj = nil
        end
        local obj = minetest.add_entity(e_pos, self.entity_name, nil)
        local rot = {
            x = 0,
            y = yawRad,
            z = 0
        }
        obj:set_rotation(rot)
        self.entity_obj = obj
    end
end

-----------------------------------------------------------------
-- export class
return Structure
