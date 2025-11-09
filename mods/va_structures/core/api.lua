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

-- player selected pos list
local player_selects = {}

-- build queue mapping by construction unit
local build_command_queue = {}
-- build menu defs for construction
local build_menu_defs = {}

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
            -- base information
            name = def.name,
            fqnn = def.fqnn,
            desc = def.desc,
            size = def.size,
            tier = def.tier,
            volume = def.volume,
            faction = def.faction,
            category = def.category,
            build_time = def.build_time,
            -- node def groups
            node_groups = def.node_groups,
            -- structure type flags
            water_type = def.water_type,
            under_water_type = def.under_water_type,
            factory_type = def.factory_type,
            construction_type = def.construction_type,
            extractor_type = def.extractor_type,
            -- entity attached
            entity_name = def.entity_name,
            entity_offset = def.entity_offset,
            entity_emitters_pos = def.entity_emitters_pos,
            do_rotate = def.do_rotate,
            -- gui (optional)
            formspec = def.ui.formspec,
            -- meta defs
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
    -- local desc = def.desc
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
    pos = {
        x = math.floor(pos.x),
        y = math.floor(pos.y + 0.5),
        z = math.floor(pos.z)
    }
    local hash = core.hash_node_position(pos)
    return _active_instances[hash]
end

function va_structures.get_active_structure_by_id(id)
    local pos = nil
    for k, v in pairs(_active_instances) do
        if v.entity_obj and v.entity_obj._id == id then
            -- pos = core.unhash_node_position(k)
            pos = v.pos
            break
        end
    end
    if pos then
        return va_structures.get_active_structure(pos)
    end
    return nil
end

function va_structures.add_active_structure(pos, s)
    pos = {
        x = math.floor(pos.x),
        y = math.floor(pos.y + 0.5),
        z = math.floor(pos.z)
    }
    local hash = core.hash_node_position(pos)
    _active_instances[hash] = s
end

function va_structures.remove_active_structure(pos)
    pos = {
        x = math.floor(pos.x),
        y = math.floor(pos.y + 0.5),
        z = math.floor(pos.z)
    }
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

function va_structures.add_player_actor(owner, faction, team)
    local actor_default = {
        faction = faction or "vox",
        team = team or 1,
        energy = 100,
        energy_storage = 100,
        energy_demand = 0,
        energy_supply = 0,
        mass = 100,
        mass_storage = 100,
        mass_demand = 0,
        mass_supply = 0
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
        actor.energy_storage = 100
        actor.energy_supply = 0
        actor.energy_demand = 0
        actor.mass_storage = 100
        actor.mass_supply = 0
        actor.mass_demand = 0
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
-- player_selects

function va_structures.set_selected_pos(player_name, pos)
    player_selects[player_name] = pos
end

function va_structures.get_selected_pos(player_name)
    return player_selects[player_name]
end

-----------------------------------------------------------------
-- construction queue

function va_structures.add_construction_to_queue(constructor_id, structure)
    -- lookup constructor unit
    local unit = va_units.get_unit_by_id(constructor_id)
    if unit then
        if build_command_queue[constructor_id] == nil then
            build_command_queue[constructor_id] = {}
        end
        local command = {
            command_type = "structure_queued",
            process_started = false,
            process_complete = false,
            pos = structure.pos,
            owner_name = structure._owner_name,
            structure_name = structure.fqnn
        }
        local build_command = va_structures.util.deepcopy(command)
        local hash = core.hash_node_position(structure.pos)
        build_command.structure_ghost = structure
        build_command.structure_ghost_hash = hash
        -- queue build command in global tracking
        build_command_queue[constructor_id][hash] = build_command
        -- enqueue command within unit
        table.insert(unit._command_queue, command)
    end
end

function va_structures.get_construction_queue()
    return build_command_queue
end

function va_structures.get_unit_construction_queue(unit)
    if not unit then
        return nil
    end
    local unit_ent = unit:get_luaentity()
    local unit_id = unit_ent._id
    return build_command_queue[unit_id]
end

function va_structures.get_unit_command_queue(unit_id)
    return build_command_queue[unit_id]
end

function va_structures.remove_pos_from_command_queue(pos, unit_id)
    local to_remove = {}
    if build_command_queue[unit_id] then
        local index = 0
        for i, bcq in pairs(build_command_queue[unit_id]) do
            if bcq.pos == pos then
                table.insert(to_remove, bcq.structure_ghost_hash)
                index = i
                break
            end
        end
        table.remove(build_command_queue[unit_id], index)
    else
        local hash = core.hash_node_position(pos)
        for _, bcu in pairs(build_command_queue) do
            if bcu[hash] then
                table.insert(to_remove, bcu[hash].structure_ghost_hash)
                bcu[hash] = nil
                break
            end
        end
    end
    for _, rem in pairs(to_remove) do
        local s = build_command_queue[unit_id][rem]
        if s and s.dispose then
            --core.log("dispose... remove_pos_from_command_queue()")
            s:dispose()
        end
    end
end

function va_structures.dispose_unit_command_queue(unit_id)
    if build_command_queue[unit_id] then
        local to_remove = {}
        for _, bcq in pairs(build_command_queue[unit_id]) do
            if bcq.structure_ghost_hash then
                table.insert(to_remove, bcq.structure_ghost_hash)
            end
        end
        for _, rem in pairs(to_remove) do
            local s = build_command_queue[unit_id][rem]
            if s and s.dispose then
                --core.log("dispose... dispose_unit_command_queue()")
                s:dispose()
            end
        end
        build_command_queue[unit_id] = nil
    end
end

function va_structures.get_unit_command_queue_from_pos(pos)
    local hash = core.hash_node_position(pos)
    for k, _ in pairs(build_command_queue) do
        if build_command_queue[k][hash] then
            return build_command_queue[k][hash]
        end
    end
    return nil
end

-----------------------------------------------------------------

function va_structures.add_construction_menu(menu_name, def)
    build_menu_defs[menu_name] = def.formspec
    -- register formspec on_receive_fields
    core.register_on_player_receive_fields(function(player, formname, fields)
        -- check if our form
        if formname ~= menu_name then
            return
        end
        local name = player:get_player_name()
        local unit_id = fields.unit_id or nil -- get unit id from form field
        if (fields.close_me or fields.quit) then
            return
        end
        if unit_id then
            local refresh_form = false
            if def.on_receive_fields then
                refresh_form = def.on_receive_fields(unit_id, player, formname, fields)
            end
            if refresh_form then
                core.show_formspec(name, formname, def.formspec(menu_name, name, unit_id))
            end
        end
    end)
end

function va_structures.show_construction_menu(player_name, menu_name, unit_id)
    local menu = build_menu_defs[menu_name]
    if not menu then
        return
    end
    core.show_formspec(player_name, menu_name, menu(menu_name, player_name, unit_id))
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
    for _, s in pairs(_active_instances) do
        s:dispose()
    end
end
