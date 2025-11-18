-- player tracking...
local player_actors = {}

local env = {
    base_mass = 100,
    base_energy = 100
}

-----------------------------------------------------------------

local color_index = 1
local colors = {"#ff0000", "#0000ff", "#00ff00", "#ffff00", "#ff00ff", "#00ffff", "#800080", "#008080", "#c0c0c0", "#a52a2a", "#deb887", "#5f9ea0", "#7fff00", "#dda0dd", "#add8e6", "#9932CC"}

-- TODO: this is temp!
--[[core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    va_game.add_player_actor(name, "vox", 1, colors[color_index])
    color_index = color_index + 1
    if color_index > 16 then
        color_index = 1
    end
end)]]

-----------------------------------------------------------------

local function add_energy_demand(self, amount)
    if not self.energy_demands then
        self.energy_demands = {}
    end
    table.insert(self.energy_demands, {
        amount = amount,
        counted = false
    })
end

local function add_energy_supply(self, amount)
    if not self.energy_supplys then
        self.energy_supplys = {}
    end
    table.insert(self.energy_supplys, {
        amount = amount,
        counted = false
    })
end

local function add_mass_demand(self, amount)
    if not self.mass_demands then
        self.mass_demands = {}
    end
    table.insert(self.mass_demands, {
        amount = amount,
        counted = false
    })
end

local function add_mass_supply(self, amount)
    if not self.mass_supplys then
        self.mass_supplys = {}
    end
    table.insert(self.mass_supplys, {
        amount = amount,
        counted = false
    })
end

-----------------------------------------------------------------
-- player actor owners

function va_game.add_player_actor(owner, faction, team, color)
    if not color then
        color = colors[color_index]
        color_index = color_index + 1
        if color_index > 16 then
            color_index = 1
        end
    end
    local actor_default = {
        faction = faction or "vox",
        team = team or 1,
        team_color = color or "#ff0000",
        energy = env.base_energy,
        energy_storage = 0,
        energy_demand = 0,
        energy_demands = {},
        add_energy_demand = add_energy_demand,
        energy_supply = 0,
        energy_supplys = {},
        add_energy_supply = add_energy_supply,
        mass = env.base_mass,
        mass_storage = 0,
        mass_demand = 0,
        mass_demands = {},
        add_mass_demand = add_mass_demand,
        mass_supply = 0,
        mass_supplys = {},
        add_mass_supply = add_mass_supply
    }
    player_actors[owner] = actor_default
end

function va_game.remove_player_actor(owner)
    player_actors[owner] = nil
end

function va_game.get_player_actor(owner)
    return player_actors[owner]
end

function va_game.get_player_actors()
    return player_actors
end

-----------------------------------------------------------------

function va_game.get_actors()
    local get_player_structures = va_structures.get_player_structures
    local actors = {}
    for p, actor in pairs(player_actors) do
        actors[p] = {
            actor = actor,
            structures = get_player_structures(p)
        }
    end
    return actors
end

-----------------------------------------------------------------
-----------------------------------------------------------------
-- player actor calculations

function va_game.calculate_player_actors()
   va_game.calculate_player_actors_reset()
   va_game.calculate_player_actor_units()
   va_game.calculate_player_actor_structures()
end

function va_game.calculate_player_actors_reset()
    -- reset resource counters
    for _, actor in pairs(player_actors) do
        actor.energy_storage = 0
        actor.energy_supply = 0
        actor.energy_demand = 0
        actor.mass_storage = 0
        actor.mass_supply = 0
        actor.mass_demand = 0
    end
end

function va_game.calculate_player_actor_units(reset)
    if reset then
        va_game.calculate_player_actors_reset()
    end
    local units = va_units.get_all_units()
    -- iterate over units and group by owner
    local owner_units = {}
    for _, unit in pairs(units) do
        if not owner_units[unit._owner_name] then
            owner_units[unit._owner_name] = {}
        end
        if unit._is_constructed then
            table.insert(owner_units[unit._owner_name], unit)
        end
    end
    -- add up storages for each owner
    for n, _units in pairs(owner_units) do
        local actor = player_actors[n]
        if actor then
            for _, u in pairs(_units) do
                if u._mass_storage > 0 then
                    actor.mass_storage = actor.mass_storage + u._mass_storage
                end
                if u._mass_generate > 0 then
                    actor:add_mass_supply(u._mass_generate)
                end
                if u._energy_storage > 0 then
                    actor.energy_storage = actor.energy_storage + u._energy_storage
                end
                if u._energy_generate > 0 then
                    actor:add_energy_supply(u._energy_generate)
                end
            end
        end
    end
end

function va_game.calculate_player_actor_structures(reset)
    if reset then
        va_game.calculate_player_actors_reset()
    end
    -- tally resource demands and supplys
    for _, actor in pairs(player_actors) do
        local energy_demands = {}
        local energy_supplys = {}
        local mass_demands = {}
        local mass_supplys = {}
        for _, demand in ipairs(actor.energy_demands) do
            if not demand.counted then
                actor.energy_demand = actor.energy_demand + demand.amount
                demand.counted = true
            end
        end
        actor.energy_demands = energy_demands
        for _, supply in ipairs(actor.energy_supplys) do
            if not supply.counted then
                actor.energy_supply = actor.energy_supply + supply.amount
                supply.counted = true
            end
        end
        actor.energy_supplys = energy_supplys
        for _, demand in ipairs(actor.mass_demands) do
            if not demand.counted then
                actor.mass_demand = actor.mass_demand + demand.amount
                demand.counted = true
            end
        end
        actor.mass_demands = mass_demands
        for _, supply in ipairs(actor.mass_supplys) do
            if not supply.counted then
                actor.mass_supply = actor.mass_supply + supply.amount
                supply.counted = true
            end
        end
        actor.mass_supplys = mass_supplys
    end
    local active_structures = va_structures.get_active_structures()
    -- iterate over structures and group by owner
    local owner_structures = {}
    for _, structure in pairs(active_structures) do
        if not owner_structures[structure.owner] then
            owner_structures[structure.owner] = {}
        end
        if structure.is_constructed then
            table.insert(owner_structures[structure.owner], structure)
        end
    end
    -- add up storages for each owner
    for n, structures in pairs(owner_structures) do
        local actor = player_actors[n]
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
