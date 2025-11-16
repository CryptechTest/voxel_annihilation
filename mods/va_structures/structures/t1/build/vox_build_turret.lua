-----------------------------------------------------------------
-----------------------------------------------------------------
-- Voxel Anniliation Structure Setup:
--- Build Turret
--
-----------------------------------------------------------------
-----------------------------------------------------------------
local modname = core.get_current_modname()
local modpath = core.get_modpath(modname)
-- load class
local Structure = dofile(modpath .. "/structure/structure.lua")

local function get_formspec(structure)
    if not structure then
        return
    end

    local pos = structure.pos
    local meta = core.get_meta(pos)
    local desc = structure.desc

    local formspec = "size[8,8]" .. "no_prepend[]" .. "formspec_version[10]" -- .. "allow_close[false]"

    formspec = formspec .. "style_type[label;font_size=22;font=bold]"
    formspec = formspec .. "label[0.0,-0.1;" .. desc .. " - Control]" .. "bgcolor[#101010;]"
    formspec = formspec .. "style_type[label;font_size=16;font=bold]"

    local _do_assist = meta:get_int("do_assist") == 1
    local _do_repair = meta:get_int("do_repair") == 1
    local _do_reclaim = meta:get_int("do_reclaim") == 1

    formspec = formspec .. "checkbox[0.5,1;do_assist;Assist Build;" .. tostring(_do_assist) .. "]"
    formspec = formspec .. "checkbox[2.5,1;do_repair;Repair Units;" .. tostring(_do_repair) .. "]"
    formspec = formspec .. "checkbox[4.5,1;do_reclaim;Reclaim;" .. tostring(_do_reclaim) .. "]"

    local b_focus = meta:get_int("build_focus")
    local r_focus = meta:get_int("reclaim_focus")

    formspec = formspec .. "label[0.55,2.1;Focus Priority]"
    formspec = formspec ..
                   "dropdown[0.5,2.5;2.5;build_focus;Build Units,Build Structures,Repair Units,Repair Structures,Reclaim;" ..
                   (b_focus or 1) .. ";true]"

    if _do_reclaim then
        formspec = formspec .. "label[4.55,2.1;Reclaim Priority]"
        formspec = formspec .. "dropdown[4.5,2.5;2.5;reclaim_focus;Mass,Energy,Auto;" .. (r_focus or 1) .. ";true]"
    end

    local is_paused = meta:get_int("build_pause") == 1
    local b_priority = meta:get_int("build_priority")

    formspec = formspec .. "label[0.5,3.6;Usage Priority]"
    formspec = formspec .. "style[build_priority;bgcolor=" .. (b_priority == 0 and "#00ffaaff" or "#0066ffff") .. "]"
    formspec = formspec .. "button[0.5,4.0;2.25,1;build_priority;" ..
                   (b_priority == 0 and "High Priority" or "Low Priority") .. "]"

    local reclaim_bar_mass = meta:get_int("reclaim_bar_mass")
    local reclaim_bar_energy = meta:get_int("reclaim_bar_energy")

    formspec = formspec .. "scrollbaroptions[arrows=hide;smallstep=10;largestep=100;thumbsize=1;]"
    formspec = formspec .. "label[3.5,3.6;Mass Reclaim Threshold]"
    formspec = formspec .. "scrollbar[3.5,4.0;4.0,0.3;horizontal;reclaim_bar_mass;" .. tostring(reclaim_bar_mass) .. "]"
    formspec = formspec .. "label[3.5,4.6;Energy Reclaim Threshold]"
    formspec = formspec .. "scrollbar[3.5,5.0;4.0,0.3;horizontal;reclaim_bar_energy;" .. tostring(reclaim_bar_energy) ..
                   "]"

    formspec = formspec .. "style[build_cancel;bgcolor=" .. "#ffee00ff" .. "]"
    formspec = formspec .. "button[2.0,7.3;1.5,1;build_cancel;Cancel]"
    formspec = formspec .. "style[build_pause;bgcolor=" .. (is_paused and "#ff0000ff" or "#00ff00ff") .. "]"
    formspec = formspec .. "button[3.5,7.3;1.5,1;build_pause;" .. (is_paused and "Paused" or "Pause") .. "]"

    formspec = formspec .. "style[quit;bgcolor=" .. "#ff0000ff" .. "]"
    formspec = formspec .. "button_exit[6.5,7.3;1.5,1;quit;Exit]"

    return formspec
end

local function on_receive_fields(structure, player, formname, fields)
    if not structure then
        return
    end
    local pos = structure.pos
    local meta = core.get_meta(pos)
    -- local owner = meta:get_string("owner") or ""

    -- core.log(dump(fields))

    if fields.build_cancel then
        structure._build_target = nil
        structure._last_dir = nil
        structure._target_locked = false
        structure._is_reclaiming = false
        structure._out_index = 0
    end
    if fields.build_pause ~= nil then
        local val = meta:get_int("build_pause")
        meta:set_int("build_pause", val == 1 and 0 or 1)
    end
    if fields.do_assist then
        local val = meta:get_int("do_assist")
        meta:set_int("do_assist", val == 1 and 0 or 1)
    end
    if fields.do_repair then
        local val = meta:get_int("do_repair")
        meta:set_int("do_repair", val == 1 and 0 or 1)
    end
    if fields.do_reclaim then
        local val = meta:get_int("do_reclaim")
        meta:set_int("do_reclaim", fields.do_reclaim == 'true' and 1 or 0)
    end
    if fields.build_priority ~= nil then
        local val = meta:get_int("build_priority")
        meta:set_int("build_priority", val == 1 and 0 or 1)
    end
    if fields.build_focus ~= nil then
        if meta:get_int("build_focus") ~= tonumber(fields.build_focus) then
            meta:set_int("build_focus", tonumber(fields.build_focus))
        end
    end
    if fields.reclaim_focus ~= nil then
        if meta:get_int("reclaim_focus") ~= tonumber(fields.reclaim_focus) then
            meta:set_int("reclaim_focus", tonumber(fields.reclaim_focus))
        end
    end
    if fields.reclaim_bar_mass ~= nil then
        if string.find(fields.reclaim_bar_mass, "CHG:") ~= nil then
            local val = string.gsub(fields.reclaim_bar_mass, "CHG:", "")
            val = string.gsub(val, "VAL:", "")
            meta:set_int("reclaim_bar_mass", tonumber(val))
        end
    end
    if fields.reclaim_bar_energy ~= nil then
        if string.find(fields.reclaim_bar_energy, "CHG:") ~= nil then
            local val = string.gsub(fields.reclaim_bar_energy, "CHG:", "")
            val = string.gsub(val, "VAL:", "")
            meta:set_int("reclaim_bar_energy", tonumber(val))
        end
    end

end

--- Find build target for given structure
---@param s any
local find_build_target = function(s)
    local pos = s.pos
    local meta = core.get_meta(pos)
    local _do_assist = meta:get_int("do_assist") == 1
    local _do_repair = meta:get_int("do_repair") == 1
    local dist = s:get_data().construction_distance
    local objs = core.get_objects_inside_radius(pos, dist + 0.55)
    for _, obj in pairs(objs) do
        local o_pos = obj:get_pos()
        if obj:get_luaentity() then
            local ent = obj:get_luaentity()
            if _do_repair and ent._is_va_unit then
                local unit = va_units.get_unit_by_id(obj:get_guid())
                if unit and not unit.object:get_luaentity()._is_constructed then
                    s._build_target = {
                        structure = nil,
                        unit = unit,
                        reclaim = nil
                    }
                    -- core.log("found repair work for build_turret!")
                end
            elseif _do_assist and ent._is_va_structure then
                local structure = va_structures.get_active_structure(o_pos)
                if structure and not s:equals(structure) then
                    if structure.is_constructed == false or structure:is_damaged() then
                        s._build_target = {
                            structure = structure,
                            unit = nil,
                            reclaim = nil
                        }
                        -- core.log("found build work for build_turret!")
                        break
                    end
                end
            end
        end
    end
end

local function num_is_close(target, actual, thrs)
    local target_frac = (target * 0.001) + thrs
    return actual < target + target_frac and actual >= target - target_frac
end

local function is_net_low_resources(pos, net)
    local meta = core.get_meta(pos)
    local reclaim_bar_mass = meta:get_int("reclaim_bar_mass")
    local reclaim_bar_energy = meta:get_int("reclaim_bar_energy")
    reclaim_bar_mass = reclaim_bar_mass and reclaim_bar_mass / 1000 or 0
    reclaim_bar_energy = reclaim_bar_energy and reclaim_bar_energy / 1000 or 0

    local net_mass = net.mass_storage > 0 and net.mass / net.mass_storage or 0
    local net_energy = net.energy_storage > 0 and net.energy / net.energy_storage or 0
    return net_mass < reclaim_bar_mass or net_energy < reclaim_bar_energy
    -- return net.mass < 10 or net.energy < 10
end

local function is_net_not_low_resources(pos, net)
    local meta = core.get_meta(pos)
    local reclaim_bar_mass = meta:get_int("reclaim_bar_mass")
    local reclaim_bar_energy = meta:get_int("reclaim_bar_energy")
    reclaim_bar_mass = reclaim_bar_mass and reclaim_bar_mass / 1000 or 0
    reclaim_bar_energy = reclaim_bar_energy and reclaim_bar_energy / 1000 or 0

    -- local net_mass = net.mass_storage > 0 and net.mass / net.mass_storage or 0
    -- local net_energy = net.energy_storage > 0 and net.energy / net.energy_storage or 0
    -- return (net_mass >= 0.07 or net_energy >= 0.10) and net_mass > 0.03 and net_energy > 0.03
    return net.mass > 1 and net.energy > 3
end

local function is_net_has_resources(pos, net)
    local meta = core.get_meta(pos)
    local reclaim_bar_mass = meta:get_int("reclaim_bar_mass")
    local reclaim_bar_energy = meta:get_int("reclaim_bar_energy")
    reclaim_bar_mass = reclaim_bar_mass and reclaim_bar_mass / 1000 or 0
    reclaim_bar_energy = reclaim_bar_energy and reclaim_bar_energy / 1000 or 0

    local net_mass = net.mass_storage > 0 and net.mass / net.mass_storage or 0
    local net_energy = net.energy_storage > 0 and net.energy / net.energy_storage or 0
    return (net_mass > reclaim_bar_mass or net_energy > reclaim_bar_energy) and net_mass > 0.05 and net_energy > 0.05
end

local function is_net_not_has_resources(pos, net)
    local meta = core.get_meta(pos)
    local reclaim_bar_mass = meta:get_int("reclaim_bar_mass")
    local reclaim_bar_energy = meta:get_int("reclaim_bar_energy")
    reclaim_bar_mass = reclaim_bar_mass and reclaim_bar_mass / 1000 or 0
    reclaim_bar_energy = reclaim_bar_energy and reclaim_bar_energy / 1000 or 0.

    local net_mass = net.mass_storage > 0 and net.mass / net.mass_storage or 0
    local net_energy = net.energy_storage > 0 and net.energy / net.energy_storage or 0
    return (net_mass < reclaim_bar_mass or net_energy < reclaim_bar_energy) -- and net_mass < 0.99 and net_energy < 0.99
end

local function is_net_full_resources(net)
    local net_mass = net.mass_storage > 0 and net.mass / net.mass_storage or 0
    local net_energy = net.energy_storage > 0 and net.energy / net.energy_storage or 0
    return (net_mass > 0.98 or net_energy > 0.97) and net_mass > 0.57 and net_energy > 0.57
end

local function is_net_not_full_resources(net)
    local net_mass = net.mass_storage > 0 and net.mass / net.mass_storage or 0
    local net_energy = net.energy_storage > 0 and net.energy / net.energy_storage or 0
    return (net_mass < 0.98 or net_energy < 0.97) -- and net_mass <= 0.99 and net_energy <= 0.99
end

--- Find build/repair target for structure
---@param structure any
---@param net any
local function find_target(structure, net)
    if structure == nil or net == nil then
        return false
    end
    if structure._build_target ~= nil then
        return true
    end
    local meta = core.get_meta(structure.pos)
    local _do_assist = meta:get_int("do_assist") == 1
    local _do_repair = meta:get_int("do_repair") == 1
    local _do_reclaim = meta:get_int("do_reclaim") == 1
    local build_focus = meta:get_int("build_focus")
    if is_net_has_resources(structure.pos, net) then
        structure._is_reclaiming = false
    elseif _do_reclaim and is_net_low_resources(structure.pos, net) then
        va_resources.structure_find_reclaim(structure, net)
        structure._is_reclaiming = true
    end
    if build_focus >= 1 and build_focus <= 4 then
        if _do_assist or _do_repair then
            if structure._build_target == nil and is_net_not_low_resources(structure.pos, net) then
                -- core.log("find_build_target")
                -- find build target
                find_build_target(structure)
            end
        end
        if structure._build_target == nil and is_net_low_resources(structure.pos, net) and _do_reclaim then
            -- core.log("find_reclaim")
            -- find reclaim target
            if va_resources.structure_find_reclaim(structure, net) then
                structure._is_reclaiming = true
            end
        end
    elseif build_focus == 5 then
        if _do_reclaim then
            if is_net_not_full_resources(net) or structure._is_reclaiming then
                -- find reclaim target
                if va_resources.structure_find_reclaim(structure, net) then
                    structure._is_reclaiming = true
                end
            end
        end
        if structure._build_target == nil and (_do_assist or _do_repair) then
            -- if is_net_full_resources(net) then
            structure._is_reclaiming = false
            -- find build target
            find_build_target(structure)
            -- end
        end
    end
    -- core.log("find target= " .. tostring(structure._build_target ~= nil))
    return structure._build_target ~= nil
end

--- Reset builder, find new target
---@param structure any
---@param find_new_target any
---@param net any
local function reset_builder(structure, find_new_target, net)
    if structure == nil then
        return false
    end
    structure._build_target = nil
    -- structure._last_dir = nil
    structure._target_locked = false
    structure._is_reclaiming = false
    structure._out_index = 0
    if find_new_target and net ~= nil then
        return find_target(structure, net)
    end
    return true
end

--- Execute build/repair by given focus priority for input
---@param s_obj table
---@param b_power number
---@param t_structure table | nil
---@param t_unit table | nil
---@param t_factory table | nil
---@param net table
local function do_focus_build(s_obj, b_power, t_structure, t_unit, t_factory, net)
    if s_obj == nil or net == nil then
        return false
    elseif b_power < 2.5 then
        return false
    end
    -- if is_net_low_resources(net) then
    if is_net_not_has_resources(s_obj.pos, net) then
        return false
    end
    local meta = core.get_meta(s_obj.pos)
    local _do_assist = meta:get_int("do_assist") == 1
    local _do_repair = meta:get_int("do_repair") == 1
    local b_focus = meta:get_int("build_focus")
    -- if unit; get unit hp max
    local hp_max = t_unit and core.registered_entities[t_unit.object:get_luaentity().name].hp_max or 10
    if b_focus == 1 then
        -- do unit construction assist first
        if t_unit and _do_assist and not t_unit.object:get_luaentity()._is_constructed then
            s_obj:build_unit_with_power(net, t_unit, b_power, t_structure)
            s_obj._out_index = 0
        elseif t_unit and _do_repair and t_unit.object:get_hp() < hp_max then
            s_obj:repair_unit_with_power(net, t_unit, b_power)
            s_obj._out_index = 0
        elseif t_structure and _do_assist and not t_factory and not t_structure.is_constructed then
            t_structure:construct_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        elseif t_structure and _do_repair and not t_factory and t_structure:is_damaged() then
            t_structure:repair_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        end
    elseif b_focus == 2 then
        -- do structure construction assist first
        if t_structure and _do_assist and not t_factory and not t_structure.is_constructed then
            t_structure:construct_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        elseif t_structure and _do_repair and not t_factory and t_structure:is_damaged() then
            t_structure:repair_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        elseif t_unit and _do_assist and not t_unit.object:get_luaentity()._is_constructed then
            s_obj:build_unit_with_power(net, t_unit, b_power, t_structure)
            s_obj._out_index = 0
        elseif t_unit and _do_repair and t_unit.object:get_hp() < hp_max then
            s_obj:repair_unit_with_power(net, t_unit, b_power)
            s_obj._out_index = 0
        end
    elseif b_focus == 3 then
        -- do unit repair first
        if t_unit and _do_repair and t_unit.object:get_hp() < hp_max then
            s_obj:repair_unit_with_power(net, t_unit, b_power)
            s_obj._out_index = 0
        elseif t_structure and _do_repair and not t_factory and t_structure:is_damaged() then
            t_structure:repair_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        elseif t_unit and _do_assist and not t_unit.object:get_luaentity()._is_constructed then
            s_obj:build_unit_with_power(net, t_unit, b_power, t_structure)
            s_obj._out_index = 0
        elseif t_structure and _do_assist and not t_factory and not t_structure.is_constructed then
            t_structure:construct_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        end
    elseif b_focus == 4 then
        -- do structure repair first
        if t_structure and _do_repair and not t_factory and t_structure:is_damaged() then
            t_structure:repair_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        elseif t_unit and _do_repair and t_unit.object:get_hp() < hp_max then
            s_obj:repair_unit_with_power(net, t_unit, b_power)
            s_obj._out_index = 0
        elseif t_structure and _do_assist and not t_factory and not t_structure.is_constructed then
            t_structure:construct_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        elseif t_unit and _do_assist and not t_unit.object:get_luaentity()._is_constructed then
            s_obj:build_unit_with_power(net, t_unit, b_power, t_structure)
            s_obj._out_index = 0
        end
    elseif b_focus == 5 then
        -- do default build or repair
        if t_unit and t_unit.object:get_hp() < hp_max then
            s_obj:repair_unit_with_power(net, t_unit, b_power)
            s_obj._out_index = 0
        elseif t_structure and _do_assist and not t_factory and not t_structure.is_constructed then
            t_structure:construct_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        elseif t_structure and not t_factory and t_structure:is_damaged() then
            t_structure:repair_with_power(net, b_power, s_obj)
            s_obj._out_index = 0
        elseif t_unit and _do_assist and not t_unit.object:get_luaentity()._is_constructed then
            s_obj:build_unit_with_power(net, t_unit, b_power, t_structure)
            s_obj._out_index = 0
        end
    end
    return s_obj._out_index == 0 and b_power >= 0.01
end

--- Rotate the build turret to face toward the target
---@param structure any
---@param target any
local function do_turret_rotation(structure, target)
    if target == nil or structure == nil then
        return
    end
    local pos = structure.pos
    -- building effect turret rotation
    local yaw, yaw_deg = va_structures.util.calculateYaw(pos, target)
    local turret = structure.entity_obj:get_bone_override('turret')
    local yawRad = turret.rotation and turret.rotation.vec.y or 0
    local yawDeg = yaw_deg -- yawDeg = ((yawDeg + (yaw_deg * 1)) / 2) % 360
    if structure._last_dir ~= nil and num_is_close(yawDeg, math.deg(yawRad), 3) then
        -- if rotation complete mark as locked
        structure._target_locked = true
    end
    if structure._last_dir == nil or yaw_deg ~= structure._last_dir then
        if not num_is_close(yawDeg, math.deg(yawRad), 28) then
            structure._target_locked = false
        end
        structure._last_dir = yawDeg
        local rot_turret = {
            x = 0,
            y = math.rad(yawDeg),
            z = 0
        }
        -- set rotation to target
        structure.entity_obj:set_bone_override("turret", {
            rotation = {
                vec = rot_turret,
                absolute = true,
                interpolation = 0.7
            }
        })
    end
end

--- Main structure run tick for process
---@param pos table
---@param node table
---@param s_obj table
---@param run_stage string
---@param net table
local vas_run = function(pos, node, s_obj, run_stage, net)
    -- core.log("vas_run() tick... " .. s_obj.name)
    if net == nil or s_obj == nil then
        return
    end
    -- run 
    if run_stage == "main" then

        local meta = core.get_meta(pos)
        if meta:get_int("build_pause") == 1 then
            return
        end

        s_obj._out_index = s_obj._out_index + 1
        if s_obj._out_index > 3 then
            -- core.log("reset structure build... " .. tostring(s_obj._out_index))
            -- return reset_builder(s_obj)
            reset_builder(s_obj)
            -- s_obj._last_dir = nil
        end

        -- find build/repair/reclaim target for turret
        local b_found = find_target(s_obj, net)

        -- target found pre-check
        if s_obj._build_target ~= nil then
            if s_obj._build_target.structure and s_obj._build_target.structure._disposed then
                -- reset build target if target structure is disposed
                reset_builder(s_obj, true, net)
            elseif s_obj._build_target.unit and s_obj._build_target.unit.object then
                -- reset build target if target unit is disposed
                local t_obj = s_obj._build_target.unit.object
                if not t_obj or not t_obj:get_luaentity() or t_obj:get_luaentity()._marked_for_removal then
                    reset_builder(s_obj, true, net)
                end
            end
        end

        -- target found check
        if b_found and s_obj._build_target ~= nil then
            local t_structure = s_obj._build_target.structure
            local t_unit = s_obj._build_target.unit
            local t_reclaim = s_obj._build_target.reclaim
            local has_structure_or_unit = t_structure ~= nil or t_unit ~= nil
            local has_reclaim = t_reclaim ~= nil

            -- structure building unit is attached to
            local s_building = nil
            local s_attach = t_unit and t_unit.object:get_attach() or nil
            if s_attach then
                -- get the attached structure for the target unit
                t_structure = va_structures.get_active_structure(s_attach:get_pos())
                s_obj._build_target.structure = t_structure
                -- target unit building variable storage
                s_building = (t_structure and t_structure.process_queue[1]) or nil
            end

            -- reclaim
            if s_obj._target_locked and has_reclaim then
                local b_power = s_obj:get_data():get_build_power()
                local b_pos = vector.add(pos, {
                    x = 0,
                    y = 0.4,
                    z = 0
                })
                -- core.log("do reclaim with power")
                va_structures.show_reclaim_beam_effect(t_reclaim.pos, b_pos, b_power * 0.5, net.team_color)
                -- target locked, do reclaim of target
                if not va_resources.do_reclaim_with_power(t_reclaim, b_power, net) then
                    va_structures.reclaim_effect_particles(t_reclaim.pos, b_power, vector.direction(t_reclaim.pos, pos))
                    -- core.log("find next target")
                    -- return reset_builder(s_obj, true, net)
                    return reset_builder(s_obj)
                end
                s_obj._out_index = 0
            end

            -- build
            if s_obj._target_locked and has_structure_or_unit then
                -- target locked, do resource draw
                -- local e_use = s_obj:get_data():get_energy_consume()
                local e_use = 0.0001
                if net.energy - (1 + e_use) > 0 and net.mass - (1) > 0 then
                    local b_power = s_obj:get_data():get_build_power()
                    local b_priority = meta:get_int("build_priority")
                    if b_priority == 1 and is_net_not_has_resources(s_obj.pos, net) then
                        b_power = b_power * 0.5
                        if is_net_low_resources(s_obj.pos, net) then
                            b_power = b_power * 0.5
                        end
                    end
                    if is_net_not_has_resources(s_obj.pos, net) then
                        b_power = b_power * 0.5
                    end
                    -- core.log("do build with power " .. tostring(b_power))
                    if do_focus_build(s_obj, b_power, t_structure, t_unit, s_building, net) then
                        -- core.log("turret assisting build...")
                        net.energy = net.energy - e_use
                    else
                        -- core.log("turret assisting fail.")
                        s_obj._last_dir = nil
                    end
                end
                net.energy_demand = net.energy_demand + e_use
            end

            if s_obj._build_target.reclaim == nil then
                if t_structure and s_building == nil and (t_structure.is_constructed and not t_structure:is_damaged()) then
                    -- structure construction complete
                    return reset_builder(s_obj)
                elseif t_unit and s_building and s_building.build_time >= s_building.build_time_max then
                    -- queued unit construction complete
                    return reset_builder(s_obj)
                elseif t_unit and t_unit.object:get_luaentity()._is_constructed then
                    -- unit construction complete
                    return reset_builder(s_obj)
                end
            elseif s_obj._build_target.reclaim ~= nil then
                local n = core.get_node(s_obj._build_target.reclaim.pos)
                if n.name == "air" and s_obj._out_index > 0 then
                    -- object to reclaim was removed
                    -- core.log("reclaim target is gone on check!")
                    return reset_builder(s_obj)
                end
            end
            if has_structure_or_unit and s_obj._build_target.reclaim ~= nil then
                if s_obj._out_index > 1 and is_net_low_resources(s_obj.pos, net) then
                    -- core.log("low resources but has structure/unit")
                    return reset_builder(s_obj)
                end
            end

            -- get target pos
            local target = nil
            if t_structure and not s_building then
                target = t_structure.pos
            elseif t_unit then
                target = t_unit.object:get_pos()
            elseif t_reclaim then
                target = t_reclaim.pos
            end
            do_turret_rotation(s_obj, target)
        end
    end
end

-- Structure metadata definition setup
local def = {
    mesh = "va_build_turret_1.gltf",
    textures = {"va_vox_build_turret_1.png"},
    collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
    max_health = 25,
    energy_generate = 0,
    energy_storage = 0,
    mass_cost = 21,
    -- mass_cost = 1,
    energy_cost = 320,
    -- energy_cost = 1,
    energy_consume = 0.1,
    build_time = 530,
    build_power = 20,
    construction_distance = 18,
    entity_emitters_pos = {{
        x = 0,
        y = 0.3225,
        z = 0
    }},
    formspec = get_formspec,
    on_receive_fields = on_receive_fields,
    vas_run = vas_run
}

-- Setup structure definition
def.name = "build_turret"
def.desc = "Build Turret"
def.size = {
    x = 1,
    y = 0,
    z = 1
}
def.category = "build"
def.tier = 1
def.faction = "vox"

def.construction_type = true

def.do_rotate = false

-- Register a new Build Turret
Structure.register(def)
