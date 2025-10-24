-- keeploaded mapblocks
local loaded_mapblocks = {}

-- internal registered structure definitions
local _registered_defs = {}
-- internal active structure instances
local _active_instances = {}

-- player structure tracking
local player_structures = {}
-- player tracking...
local player_actors = {}

-----------------------------------------------------------------
-- registered structures

function va_structures.keep_loaded(unit)
    if not unit.object then
        return
    end
    local pos = unit.object:get_pos()
    local mapblock_pos = {
        x = math.floor(pos.x / 16),
        y = math.floor(pos.y / 16),
        z = math.floor(pos.z / 16)
    }
    local mapblock_key = mapblock_pos.x .. "," .. mapblock_pos.y .. "," .. mapblock_pos.z
    local current_mapblock = unit._current_mapblock
    local current_key = current_mapblock and
                            (current_mapblock.x .. "," .. current_mapblock.y .. "," .. current_mapblock.z) or nil

    if current_key and (current_key ~= mapblock_key) then
        if unit._forceloaded_block then
            core.forceload_free_block(unit._forceloaded_block, true)
            loaded_mapblocks[current_key] = nil
            unit._forceloaded_block = nil
        end
    end

    if not loaded_mapblocks[mapblock_key] then
        core.forceload_block(pos, true)
        loaded_mapblocks[mapblock_key] = true
        unit._forceloaded_block = pos
    end

    unit._current_mapblock = mapblock_pos
end

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
            mass_storage = def.meta.mass_storage
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
    if _active_instances[hash] then
        _active_instances[hash] = nil
    end
end

function va_structures.get_active_structures()
    return _active_instances
end

function va_structures.get_all_structures()
    local structures = va_structures.get_active_structures()
    local s_ents = {}
    for _, s in pairs(structures) do
        local ent = s:get_entity()
        if s:is_active() and ent ~= nil then
            table.insert(s_ents, s:get_entity())
        end
    end
    return s_ents
end

-----------------------------------------------------------------
-- player structures

function va_structures.add_player_structure(structure)
    local owner = structure.owner
    if not player_structures[owner] then
        player_structures[owner] = {}
    end
    table.insert(player_structures[owner], structure)
end

function va_structures.remove_player_structure(structure)
    local owner = structure.owner
    local index = 0
    for i, s in pairs(player_structures[owner]) do
        if s:hash() == structure:hash() then
            index = i
        end
    end
    table.remove(player_structures[owner], index)
end

function va_structures.get_player_structures(owner)
    return player_structures[owner]
end

-----------------------------------------------------------------
-- player actor owners

function va_structures.add_player_actor(owner, team)
    local actor_default = {
        team_id = team or "vox",
        energy = 100,
        energy_storage = 1000,
        mass = 100,
        mass_storage = 1000
    }
    player_actors[owner] = actor_default
end

function va_structures.remove_player_actor(owner)
    player_actors[owner] = nil
end

function va_structures.get_player_actor(owner)
    return player_actors[owner]
end

function va_structures.get_player_actors()
    return player_actors
end

-----------------------------------------------------------------

function va_structures.get_actors()
    local actors = {}
    for p, actor in pairs(player_actors) do
        actors[p] = {
            actor = player_actors[p],
            structures = player_structures[p]
        }
    end
    return actors
end

-----------------------------------------------------------------
-- player actor calculations

local function calculate_player_actor_structures()
    local owner_structures = {}
    for hash, structure in pairs(_active_instances) do
        if not owner_structures[structure.owner] then
            owner_structures[structure.owner] = {}
        end
        table.insert(owner_structures[structure.owner], structure)
    end
    for n, structures in pairs(owner_structures) do
        local actor = player_actors[n]
        actor.energy_storage = 1000
        actor.mass_storage = 1000
        for _, s in pairs(structures) do
            if s:can_store_energy() then
                actor.energy_storage = actor.energy_storage + s:get_data():get_energy_storage()
            end
            if s:can_store_mass() then
                actor.mass_storage = actor.mass_storage + s:get_data():get_mass_storage()
            end
        end
    end
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

local function run_nodes(list, run_stage)
    for _, pos in ipairs(list) do
        local node = core.get_node_or_nil(pos)
        if not node then
            core.load_area(pos, pos)
            node = core.get_node_or_nil(pos)
        end
        if node and node.name and node_vas_run[node.name] then
            local s = va_structures.get_active_structure(pos)
            local actor = player_actors[s.owner]
            if s:run_pre(run_stage, actor) then
                node_vas_run[node.name](pos, node, s, run_stage, actor)
            end
            s:run_post(run_stage, actor)
        end
    end
    --[[for t, team in pairs(va_teams) do
        core.log("Team " .. t .. ":  ENERGY= " .. team.energy .. "/" .. team.energy_storage .. "  MASS= " .. team.mass .. "/" .. team.mass_storage)
    end]]
end

-- structure runner
va_structures.structures_run = function()
    local s_pos = {}
    for hash, structure in pairs(_active_instances) do
        table.insert(s_pos, structure.pos)
    end
    calculate_player_actor_structures()
    run_nodes(s_pos, "main")
    -- core.log("run " .. #s_pos .. " structures")
end


-----------------------------------------------------------------
-- cleanup_assets

va_structures.cleanup_assets = function()
    for _,s in pairs(_active_instances) do
        s:dispose()
    end
end
