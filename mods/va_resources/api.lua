-- reclaim groups for resources
local reclaim_groups = {
    ['va_rocks'] = {
        -- uses the va_rocks node groups,
        -- these values might not have effect
        time = 25,
        mass = 1, -- acts as scaler
        energy = 0, -- acts as scaler
        use_group = true,
        priority = 3
    },
    ['va_wreckage'] = {
        -- uses the va_wreckage node groups,
        -- these values might not have effect
        time = 10,
        mass = 1, -- acts as scaler
        energy = 0, -- acts as scaler
        use_group = true,
        priority = 4
    },
    ['leaves'] = {
        time = 10,
        mass = 0,
        energy = 2.5,
        use_group = true,
        priority = 3
    },
    ['tree'] = {
        time = 25,
        mass = 0.3,
        energy = 7,
        use_group = true,
        priority = 5
    },
    ['grass'] = {
        time = 12,
        mass = 0,
        energy = 2,
        use_group = true
    },
    ['flower'] = {
        time = 13,
        mass = 0,
        energy = 2.5,
        use_group = true
    },
    ['mushroom'] = {
        time = 20,
        mass = 0.1,
        energy = 3,
        use_group = true
    },
    ['plant'] = {
        time = 15,
        mass = 0.2,
        energy = 2.7,
        use_group = true
    },
    ['saltd:salt_gem'] = {
        time = 80,
        mass = 3.0,
        energy = 2.8,
        priority = 6
    },
    ['saltd:burnt_bush'] = {
        time = 20,
        mass = 0,
        energy = 3,
        priority = 3
    },
    ['saltd:burnt_grass'] = {
        time = 12,
        mass = 0,
        energy = 2,
        priority = 4
    },
    ['saltd:thorny_bush'] = {
        time = 20,
        mass = 0,
        energy = 3.3,
        priority = 3
    },
    ['saltd:burnt_trunk'] = {
        time = 25,
        mass = 0.3,
        energy = 6.5,
        priority = 4
    },
    ['saltd:burnt_branches'] = {
        time = 10,
        mass = 0,
        energy = 2.3,
        priority = 3
    },
    ['va_terrain:slope_burnt_branches'] = {
        time = 10,
        mass = 0,
        energy = 2.3,
        priority = 3
    },
    ['va_terrain:slope_pike_burnt_branches'] = {
        time = 10,
        mass = 0,
        energy = 2.3,
        priority = 3
    },
    ['va_terrain:slope_outer_burnt_branches'] = {
        time = 10,
        mass = 0,
        energy = 2.3,
        priority = 3
    },
    ['default:papyrus'] = {
        time = 15,
        mass = 0,
        energy = 3,
        priority = 3
    },
    ['default:dry_shrub'] = {
        time = 10,
        mass = 0,
        energy = 2.0,
        priority = 5
    },
    ['default:cactus'] = {
        time = 32,
        mass = 0.2,
        energy = 8,
        priority = 4
    },
    ['food_apple'] = {
        time = 8,
        mass = 0.1,
        energy = 2,
        priority = 4,
        use_group = true
    },
    ['va_gems'] = {
        time = 100,
        mass = 5,
        energy = 4,
        priority = 3,
        use_group = true
    },
}

local function get_reclaim_value(node)
    local splt_name = {}
    for part in string.gmatch(node.name, "([^:]+)") do
        table.insert(splt_name, part)
    end
    for key, value in pairs(reclaim_groups) do
        if key == "va_rocks" then
            local rock_lvl = core.get_item_group(node.name, key)
            local rock_mass = core.get_item_group(node.name, "va_mass_value")
            local rock_energy = core.get_item_group(node.name, "va_energy_value")
            return {
                time = 1 + value.time * math.min(rock_lvl * 0.5, 2),
                -- mass = value.mass * rock_mass * rock_lvl,
                -- energy = value.energy * rock_energy * rock_lvl
                mass = value.mass * rock_mass,
                energy = value.energy * rock_energy
            }
        elseif key == "va_gems" then
            local gem_lvl = core.get_item_group(node.name, key)
            return {
                time = value.time * gem_lvl,
                mass = value.mass * gem_lvl,
                energy = value.energy * gem_lvl
            }
        elseif not value.use_group and node.name == key then
            return value
        elseif value.use_group and core.get_item_group(node.name, key) > 0 then
            return value
        end
        if not value.use_group then
            local splt_key = {}
            for part in string.gmatch(key, "([^:]+)") do
                table.insert(splt_key, part)
            end
            local s_name = #splt_name > 1 and splt_name[2] or ""
            if s_name and #splt_key > 1 and string.sub(splt_key[2], -string.len(s_name)) == s_name then
                return value
            end
        end
    end
    return nil
end

-----------------------------------------------------------------
-----------------------------------------------------------------

function va_resources.structure_find_reclaim(structure, net)
    if structure == nil then
        return false
    end
    if net.energy >= net.energy_storage and net.mass >= net.mass_storage then
        return false
    end

    local need_energy = false
    local need_mass = false
    if net.energy / net.energy_storage < 0.95 then
        need_energy = true
    end
    if net.mass / net.mass_storage < 0.97 then
        need_mass = true
    end
    if not (need_energy and need_mass) then
        --return false
    end
    local pos = structure.pos
    local dist = structure:get_data().construction_distance
    local pos1 = vector.add(pos, {
        x = dist,
        y = math.max(3, dist - 2),
        z = dist
    })
    local pos2 = vector.subtract(pos, {
        x = dist,
        y = math.max(3, dist - 3),
        z = dist
    })
    local groups = {}
    for g, group in pairs(reclaim_groups) do
        if group.use_group then
            table.insert(groups, "group:" .. g)
        else
            table.insert(groups, g)
        end
    end

    -- find nodes to reclaim in area
    local nodes = core.find_nodes_in_area(pos1, pos2, groups)
    if #nodes < 1 then
        return false
    end

    local reclaim_targets = {}
    for _, p in pairs(nodes) do
        if vector.distance(structure.pos, p) <= dist + 0.51 then
            local node = core.get_node(p)
            local meta = core.get_meta(p)
            -- get reclaim value of node
            local reclaim_value = get_reclaim_value(node)
            if reclaim_value ~= nil and reclaim_value.time > 0 then
                local claimed = (meta:get_int("claimed") ~= nil and meta:get_int("claimed")) or 0
                local reclaim_target = {
                    pos = p,
                    value = reclaim_value,
                    tick = claimed
                }
                table.insert(reclaim_targets, reclaim_target)
            end
        end
    end

    -- return if no targets found
    if #reclaim_targets < 1 then
        return false
    end

    local meta = core.get_meta(pos)
    local r_focus = meta:get_int("reclaim_focus")

    -- sort by resource value and final priority
    table.sort(reclaim_targets, function(a, b)
        local p_a = 5
        if a.value.priority ~= nil then
            p_a = a.value.priority
        end
        local p_b = 5
        if b.value.priority ~= nil then
            p_b = b.value.priority
        end
        if r_focus == 1 then
            return p_a < p_b and a.value.mass > b.value.mass
        elseif r_focus == 2 then
            return p_a < p_b and a.value.energy > b.value.energy
        elseif r_focus == 3 then
            if need_mass and not need_energy then
                return p_a < p_b and a.value.mass > b.value.mass
            elseif need_energy then
                return p_a < p_b and a.value.energy > b.value.energy
            else
                local has_tick = a.tick ~= nil and b.tick ~= nil
                return a.value.time < b.value.time and (has_tick and a.tick < b.tick)
            end
        else
            return a.value.time < b.value.time
        end
    end)
    -- sort by y pos value for found targets, from least to greatest
    table.sort(reclaim_targets, function(a, b)
        return a.pos.y > b.pos.y
    end)
    -- third sort for avoiding multiple claimers using same pos
    table.sort(reclaim_targets, function(a, b)
        local has_tick = a.tick ~= nil and b.tick ~= nil
        return (has_tick and a.tick < b.tick) or false
    end)

    local reclaim_target_a = nil
    local reclaim_target_b = nil
    for _, rec in pairs(reclaim_targets) do
        local do_exec = false
        if need_mass and rec.value.mass > 0 then
            do_exec = true
        elseif need_energy and rec.value.energy > 0 then
            do_exec = true
        end
        if do_exec then
            if rec.value.time > 0 and rec.tick <= 0 then
                reclaim_target_a = rec
                break
            elseif rec.value.time > 0 then
                reclaim_target_b = rec
                break
            end
        end
    end

    local reclaim_target = nil
    if reclaim_target_a ~= nil and reclaim_target_b ~= nil then
        if reclaim_target_a.tick < reclaim_target_b then
            reclaim_target = reclaim_target_a
        else
            reclaim_target = reclaim_target_b
        end
    elseif reclaim_target_a == nil and reclaim_target_b ~= nil then
        reclaim_target = reclaim_target_b
    elseif reclaim_target_b == nil and reclaim_target_a ~= nil then
        reclaim_target = reclaim_target_a
    end

    if reclaim_target == nil then
        -- clear build target
        structure._build_target = nil
        return false
    end
    -- set target for reclaim object
    structure._build_target = {
        structure = nil,
        unit = nil,
        reclaim = reclaim_target
    }
    return true
end

-----------------------------------------------------------------
-----------------------------------------------------------------

function va_resources.do_reclaim_with_power(reclaim_target, build_power, actor)
    if reclaim_target == nil or actor == nil then
        return false
    end
    -- check target
    local node = core.get_node(reclaim_target.pos)
    if node.name == 'air' then
        return false
    end

    local claimed_max = reclaim_target.value.time
    local mass_cost = reclaim_target.value.mass
    local energy_cost = reclaim_target.value.energy
    local mass_cost_rate = mass_cost > 0 and math.floor((mass_cost / claimed_max) * 10000) * 0.0001 or 0
    local energy_cost_rate = energy_cost > 0 and math.floor((energy_cost / claimed_max) * 10000) * 0.0001 or 0
    mass_cost_rate = math.min(mass_cost_rate * build_power, mass_cost)
    energy_cost_rate = math.min(energy_cost_rate * build_power, energy_cost)

    local mass = actor.mass
    local energy = actor.energy
    if energy + energy_cost_rate <= actor.energy_storage then
        actor.energy = actor.energy + energy_cost_rate
    else
        actor.energy = actor.energy_storage
    end
    if mass + mass_cost_rate <= actor.mass_storage then
        actor.mass = actor.mass + mass_cost_rate
    else
        actor.mass = actor.mass_storage
    end

    actor.mass_supply = actor.mass_supply + mass_cost_rate
    actor.energy_supply = actor.energy_supply + energy_cost_rate

    local meta = core.get_meta(reclaim_target.pos)
    local claimed = meta:get_int("claimed") or 0
    meta:set_int("claimed", claimed + build_power)

    if meta:get_int("claimed") >= claimed_max then
        local rock = core.get_item_group(node.name, "va_rocks")
        if rock > 0 then
            core.after(0.5, function()
                local rock_def = core.registered_nodes[node.name]
                if rock_def and rock_def._degrade then
                    if not rock_def._degrade(reclaim_target.pos) then
                        meta = core.get_meta(reclaim_target.pos)
                        meta:set_int("claimed", 0)
                    end
                    return false
                end
            end)
        else
            core.after(0.5, function()
                core.remove_node(reclaim_target.pos)
            end)
        end
        return false
    end
    return true
end
