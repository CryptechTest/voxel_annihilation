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

-----------------------------------------------------------------
-----------------------------------------------------------------
-----------------------------------------------------------------
-- Define the base structure class
local Structure = {}
Structure.__index = Structure

local modname = core.get_current_modname()

function Structure.new(pos, name, desc, size, category, tier, faction, meta_def, do_def_check)
    local self = setmetatable({}, Structure)
    self.pos = pos
    self.name = name or "base_structure" -- name of this structure
    self.desc = desc or "Abstract Structure" -- description of this structure
    self.size = size or {1, 0, 1} -- base size
    meta_def.fqnn = modname .. ":" .. faction .. "_" .. self.name -- fully qualified node name
    self.fqnn = meta_def.fqnn
    meta_def.entity_name = meta_def and meta_def.entity_name or self.fqnn .. "_entity"
    self.entity_name = meta_def.entity_name -- name of entity attached
    self.entity_obj = nil -- object corresponding to attached entity
    self.category = category or "none" -- build, combat, economy, utility
    self.tier = tier -- tech tier of this structure
    self.faction = faction -- factions: 'vox' and 'cube'
    -- TODO: setup faction/team object...
    self.team_obj = nil
    -- TODO: setup owner controllers
    self.owner = nil
    local w = (self.size.x * 2) + 1
    local l = (self.size.z * 2) + 1
    local h = (self.size.y * 2) + 1
    self.volume = w * l * h -- volume size

    -- use or build default metadata
    self.meta = StructureMetaData.new(meta_def)

    self.vas_run_pre = meta_def.vas_run_pre or nil
    self.vas_run_post = meta_def.vas_run_post or nil
    self.destroy_post_effects = meta_def.destroy_post_effects or nil

    self.construction_tick_max = self.volume
    self.construction_tick = 0
    self.is_contructed = false

    self._active = false
    self._defined = false
    if do_def_check then
        self._defined = va_structures.is_registered_structure(self.fqnn)
    end
    return self
end

function Structure.register(name, desc, size, category, tier, faction, def)
    if not def then
        return
    end
    local structure = Structure.new(nil, name, desc, size, category, tier, faction, def, false)
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
    local s = Structure.new(pos, def.name, def.desc, def.size, def.category, def.tier, def.faction, def, true)
    if placer:is_player() then
        s.owner = placer:get_player_name()
    end
    va_structures.add_player_structure(s)
    va_structures.add_active_structure(pos, s)
    s:activate()
end

function Structure.after_dig_node(pos, oldnode, oldmetadata, digger)
    va_structures.remove_active_structure(pos)
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
    if self.team_obj == nil and net ~= nil then
        self.team_obj = net
    end
    if self:construct(net) then
        return false
    end
    self:entity_tick()
    self:do_destruct_self()
    return true
end

function Structure:run_post(run_stage, net)
    if self.vas_run_post then
        self.vas_run_post(self)
    end
end

-----------------------------------------------------------------
-- local methods

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

function Structure:construct(team_obj)
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
    local has_resources = false
    if team_obj then
        local mass_cost = self:get_data():get_mass_cost()
        local energy_cost = self:get_data():get_energy_cost()
        local mass_cost_rate = mass_cost > 0 and math.floor((mass_cost / self.construction_tick_max) * 10) * 0.1 or 0
        local energy_cost_rate =
            energy_cost > 0 and math.floor((energy_cost / self.construction_tick_max) * 10) * 0.1 or 0
        local mass = team_obj.mass
        local energy = team_obj.energy
        if mass - mass_cost_rate >= 0 and energy - energy_cost_rate >= 0 then
            if mass_cost_rate > 0 then
                team_obj.mass = mass - mass_cost_rate
            end
            if energy_cost_rate > 0 then
                team_obj.energy = energy - energy_cost_rate
            end
            has_resources = true
        end
        team_obj.mass_demand = team_obj.mass_demand + mass_cost_rate
        team_obj.energy_demand = team_obj.energy_demand + energy_cost_rate
    end
    if not has_resources then
        va_structures.particle_build_effect_halt(pos)
        return true
    end
    self.construction_tick = self.construction_tick + 1
    va_structures.particle_build_effect(pos)
    return true
end

-- destroy structure
function Structure:destroy()
    --core.log("structure destroyed... " .. self.name)
    self:dispose()
    va_structures.destroy_effect_particle(self.pos, 1.5)
    if self.destroy_post_effects then
        self.destroy_post_effects(self)
    end
end

function Structure:do_destruct_self()
    if self:get_data():is_self_destructing() then
        local c_max = self:get_data():get_self_countdown_max()
        local c = self:get_data():get_self_countdown()
        if c <= 0 then
            self:destroy()
        else
            self:get_data():set_self_countdown(c - 1)
        end
    end
end

-----------------------------------------------------------------
-- tick checks

function Structure:get_yaw()
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
