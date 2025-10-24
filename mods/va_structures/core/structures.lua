local _registered_defs = {}
local _active_instances = {}

local va_teams = {
    ['vox'] = {
        energy = 100,
        energy_storage = 1000,
        mass = 100,
        mass_storage = 1000
    },
    ['cube'] = {
        energy = 100,
        energy_storage = 1000,
        mass = 100,
        mass_storage = 1000
    }
}

-----------------------------------------------------------------
-- registered structures

function va_structures.is_registered_structure(name)
    for c, categories in pairs(_registered_defs) do
        for t, tiers in pairs(categories) do
            for n, def in pairs(tiers) do
                if def.fqnn == name then
                    return true
                end
            end
        end
    end
    return false
end

function va_structures.get_registered_structure(name)
    for c, categories in pairs(_registered_defs) do
        for t, tiers in pairs(categories) do
            for n, def in pairs(tiers) do
                if def.fqnn == name then
                    return def
                end
            end
        end
    end
    return nil
end

function va_structures.register_structure(def)

    local build_structure_def = function(def)

        local sdef = {
            name = def.name,
            fqnn = def.fqnn,
            desc = def.desc,
            size = def.size,
            category = def.category,
            entity_name = def.entity_name,
            tier = def.tier,
            faction = def.faction,
            volume = def.volume,
            is_vulnerable = def.meta.is_vulnerable,
            is_volatile = def.meta.is_volatile,
            death_explosion_radius = def.meta.death_explosion_radius,
            self_explosion_radius = def.meta.self_explosion_radius,
            self_countdown = def.meta.self_countdown,
            build_output_list = def.meta.build_output_list,
            build_power = def.meta.build_power,
            construction_distance = def.meta.construction_distance,
            max_health = def.meta.max_health,
            armor = def.meta.armor,
            mass_cost = def.meta.mass_cost,
            energy_cost = def.meta.energy_cost,
            vision_radius = def.meta.vision_radius,
            radar_radius = def.meta.radar_radius,
            antiradar_radius = def.meta.antiradar_radius,
            attack_distance = def.meta.attack_distance,
            attack_power = def.meta.attack_power,
            attack_type = def.meta.attack_type,
            energy_consume = def.meta.energy_consume,
            mass_consume = def.meta.mass_consume,
            energy_generate = def.meta.energy_generate,
            mass_extract = def.meta.mass_extract,
            energy_storage = def.meta.energy_storage,
            mass_storage = def.meta.mass_storage,
            after_place_node = def.after_place_node,
            after_dig_node = def.after_dig_node,
            vas_run = def.vas_run
        }
        return sdef
    end

    local name = def.fqnn
    local tier = def.tier
    local category = def.category
    local desc = def.desc
    if not _registered_defs[category] then
        _registered_defs[category] = {}
    end
    if not _registered_defs[category][tier] then
        _registered_defs[category][tier] = {}
    end
    if not _registered_defs[category][tier][name] then
        _registered_defs[category][tier][name] = build_structure_def(def)
        return true
    end
    return false
end

-----------------------------------------------------------------
-- active structures

function va_structures.get_active_structure(pos)
    local hash = core.hash_node_position(pos)
    return _active_instances[hash]
end

function va_structures.add_active_structure(pos, s)
    local hash = core.hash_node_position(pos)
    _active_instances[hash] = s
end

function va_structures.remove_active_structure(pos)
    local hash = core.hash_node_position(pos)
    _active_instances[hash] = nil
end

-----------------------------------------------------------------
-- vas_run

local node_vas_run = {}

core.register_on_mods_loaded(function()
    for c, categories in pairs(_registered_defs) do
        for t, tiers in pairs(categories) do
            for name, def in pairs(tiers) do
                if type(core.registered_nodes[name].va_structure_run) == "function" then
                    node_vas_run[name] = core.registered_nodes[name].va_structure_run
                end
            end
        end
    end
end)

local function calculate_team_structures()
    local team_structures = {}
    for hash, structure in pairs(_active_instances) do
        if not team_structures[structure.team_id] then
            team_structures[structure.team_id] = {}
        end
        table.insert(team_structures[structure.team_id], structure)
    end
    for t, structures in pairs(team_structures) do
        local team = va_teams[t]
        team.energy_storage = 1000
        team.mass_storage = 1000
        for _, s in pairs(structures) do
            if s:can_store_energy() then
                team.energy_storage = team.energy_storage + s:get_data():get_energy_storage()
            end
            if s:can_store_mass() then
                team.mass_storage = team.mass_storage + s:get_data():get_mass_storage()
            end
        end
    end
end

local function run_nodes(list, run_stage)
    for _, pos in ipairs(list) do
        local node = core.get_node_or_nil(pos)
        if not node then
            core.load_area(pos, pos)
            node = core.get_node_or_nil(pos)
        end
        if node and node.name and node_vas_run[node.name] then
            local s = va_structures.get_active_structure(pos)
            local net = va_teams[s.team_id]
            if s:run_pre(run_stage, net) then
                node_vas_run[node.name](pos, node, s, run_stage, net)
            end
            s:run_post(run_stage, net)
        end
    end
    for t, team in pairs(va_teams) do
        core.log("Team " .. t .. ":  ENERGY= " .. team.energy .. "/" .. team.energy_storage .. "  MASS= " .. team.mass .. "/" .. team.mass_storage)
    end
end

-- structure runner
va_structures.structures_run = function()
    local s_pos = {}
    for hash, structure in pairs(_active_instances) do
        table.insert(s_pos, structure.pos)
    end
    calculate_team_structures()
    run_nodes(s_pos, "main")
    -- core.log("run " .. #s_pos .. " structures")
end

