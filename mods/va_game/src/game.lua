local GameObject = {
    idCounter = 0
}
GameObject.__index = GameObject

function GameObject.new(pos, size, mode, name, pass)
    local self = setmetatable({}, GameObject)
    self.id = GameObject.idCounter + 1
    GameObject.idCounter = self.id -- Update the counter for the next object
    local x = pos and pos.x or 0
    local y = pos and pos.y or 0
    local z = pos and pos.z or 0
    self.position = vector.new(x, y, z) -- Set the position of the game object
    self.size = size or {
        width = 256,
        height = 128,
        depth = 256
    }
    self.name = name or "Default Game"
    self.password = pass or ""
    self.mode = mode or {
        name = "wave_defense",
        difficulty = "easy"
    }
    self.update_lobby_ui = nil
    self.dipose_lobby_game = nil
    -- player lists
    self.teams = {} -- Table to store teams in the game object
    self.players = {} -- Table to store players in the game object
    self.spectators = {} -- Table to store spectators in the game object
    self.bosses = {} -- Table to store bosses in the game object
    self.victors = {}
    self.votes_stop = {}
    -- timers
    self.start_time = 0
    self.run_time = 0
    -- tick counter
    self.run_tick = 0
    self.run_tick_max = 4
    -- setup
    self.setup_index = 8 -- index of the setup step for the game
    self.start_index = 61 -- index of the start step for the game
    -- cleanup
    self.dispose_tick = 0
    self.dispose_tick_max = 30
    self._disposing = false
    self._disposed = false
    -- flags
    self.created = false -- game board is created
    self.setup = false -- game is setup
    self.ready_start = false -- all players are ready for start
    self.started = false -- game has started
    self.stopped = false -- game has stoppped (no victor)
    self.paused = false -- game is paused
    self.ended = false -- game has ended (has victor)
    return self
end

-----------------------------------------------------------------
-----------------------------------------------------------------
--- tick run functions

function GameObject:init()
    if self.setup_index == 8 then
        -- setup the game board....

    elseif self.setup_index == 7 then
        self:send_all_player_msg("Battlefield is being created... Please wait!")
        -- move players to board
        for _, p in pairs(self.players) do
            local player = core.get_player_by_name(p.name)
            if player then
                self:player_ctl_clear(p.name)
                player:move_to(self:get_pos())
            end
        end
    elseif self.setup_index == 5 then
        -- move spectators to board
        for _, p in pairs(self.spectators) do
            local player = core.get_player_by_name(p.name)
            if player then
                self:player_ctl_clear(p.name)
                player:move_to(self:get_pos())
            end
        end
    elseif self.setup_index == 3 then
        self:send_all_player_msg("Battlefield loaded! One moment...")
    elseif self.setup_index == 1 then
        self:create_player_actors()
        if self.created then
            self:send_all_player_msg("Battlefield Ready!")
        end
    elseif self.setup_index == 0 then
        -- give command marker to players
        for _, p in pairs(self.players) do
            self:player_ctl_init(p.name)
        end
        self:send_all_player_msg("Please choose a landing location for your Commander.")
        self:send_all_player_sound("va_game_amy_choose_starting_location")
        self.start_time = core.get_us_time()
    end
end

function GameObject:begin()
    if self.start_index == 0 then
        self.start_time = core.get_us_time()
        self:send_all_player_msg("Battle Started!")
        self:send_all_player_sound("va_game_amy_battle_started")
    elseif self.start_index == 1 then
        for _, p in pairs(self.players) do
            self:player_ctl_base(p.name)
        end
        -- move players to their spawn
        for _, p in pairs(self.players) do
            local player = core.get_player_by_name(p.name)
            if player then
                self:player_ctl_clear(p.name)
                --player:move_to(p.spawn_pos)
            end
        end
    elseif self.start_index == 3 then
        self:send_all_player_msg("Game Starting in 3 seconds...")
    elseif self.start_index == 10 then
        self:send_all_player_msg("Game Starting in 10 seconds...")
    elseif self.start_index == 11 then
        -- check if all players have placed start
        local all_placed = true
        for _, pplayer in pairs(self.players) do
            if not pplayer.placed then
                all_placed = false
                break
            end
        end
        if not all_placed then
            self.start_index = 30
            self:send_all_player_msg("Not all players have chosen their start location. " ..
                                         "Next game start attempt in " .. self.start_index .. " seconds...")
        end
    end
end

function GameObject:check_ready()
    local all_ready = true
    for _, p in pairs(self.players) do
        if not p.placed then
            all_ready = false
        end
        if not p.ready then
            all_ready = false
        end
    end
    if all_ready then
        if self.start_index > 3 then
            self.start_index = 4
        end
        self.ready_start = true
    end
    if not self.ready_start and self.start_index < 3 then
        self.ready_start = true
    end
end

function GameObject:dispose()
    self._disposed = true
    self:dipose_lobby_game()
    for _, pplayer in pairs(self.players) do
        va_game.remove_player_actor(pplayer.name)
    end
    va_units.cleanup_assets()
    va_structures.cleanup_assets()
    for index, value in ipairs(va_game.games) do
        if value:get_id() == self:get_id() then
            table.remove(va_game.games, index)
        end
    end
end

-----------------------------------------------------------------
-----------------------------------------------------------------
--- tick

function GameObject:tick(tick_index)
    if self._disposed then
        return
    end
    if self.run_tick <= 0 then
        self.run_tick = self.run_tick_max
    end
    if tick_index == 0 then
        self.run_tick = self.run_tick - 1
    end
    ---------------------------------
    --- tick for game dispose
    if self._disposing then
        if self.dispose_tick >= self.dispose_tick_max then
            self:dispose()
        end
        if tick_index == 0 then
            self.dispose_tick = self.dispose_tick + 1
        end
        self:update_lobby_ui()
        return
    end
    ---------------------------------
    -- tick game setup
    if self.setup_index > 0 and tick_index == 0 then
        -- setup game...
        self.setup_index = self.setup_index - 1
        if self.setup_index <= 0 then
            self.setup = true
        end
        self:init()
    end
    if not self.created or not self.setup then
        return
    end
    if not self.ready_start then
        -- check if everyone ready for start...
        self:check_ready()
    end
    ---------------------------------
    -- tick game start
    if self.start_index > 0 and tick_index == 0 then
        -- do start countdown
        self.start_index = self.start_index - 1
        if self.start_index <= 0 then
            self.started = true
        end
        self:begin()
    end
    if not self.started then
        -- game hasn't started yet
        return
    end
    ---------------------------------
    if self.stopped or self.ended then
        self:send_all_player_sound("va_game_amy_battle_ended")
        self:update_lobby_ui()
        -- dispose game
        self._disposing = true
        return
    end
    if self.paused then
        -- game is paused...
        return
    end
    ---------------------------------
    -- tick game...
    self:tick_ctl()
    if tick_index == 0 then
        self:check_modes()
    end
end

-----------------------------------------------------------------
-----------------------------------------------------------------
-- Getters for general game info

function GameObject:get_id()
    return self.id
end

function GameObject:get_pos()
    return self.position
end

function GameObject:get_size()
    return self.size
end

function GameObject:get_name()
    return self.name
end

function GameObject:get_password()
    return self.password
end

function GameObject:get_mode()
    return self.mode
end

-----------------------------------------------------------------
-- Getters and Setters for game flags

function GameObject:is_created()
    return self.created
end

function GameObject:set_created(value)
    self.created = value
end

function GameObject:is_ready_start()
    return self.ready_start
end

function GameObject:set_ready_start(value)
    self.ready_start = value
end

function GameObject:is_started()
    return self.started
end

function GameObject:set_started(value)
    self.started = value
end

function GameObject:is_stopped()
    return self.stopped
end

function GameObject:set_stopped(value)
    self.stopped = value
end

function GameObject:is_paused()
    return self.paused
end

function GameObject:set_paused(value)
    self.paused = value
end

function GameObject:is_ended()
    return self.ended
end

function GameObject:set_ended(value)
    self.ended = value
end

-- Getter and Setter for victors
function GameObject:get_victors()
    return self.victors
end

function GameObject:set_victors(value)
    self.victors = value
end

-----------------------------------------------------------------

-- teams
function GameObject:add_team(team)
    table.insert(self.teams, team)
end

function GameObject:remove_team(team_id)
    for i, team in ipairs(self.teams) do
        if team.id == team_id then
            table.remove(self.teams, i)
            break
        end
    end
end

function GameObject:get_teams()
    return self.teams
end

-- players
function GameObject:add_player(player_name, team_id, faction, is_boss)
    self.players[player_name] = {
        name = player_name,
        team = team_id,
        faction = faction,
        is_boss = is_boss,
        is_spawned = false,
        selected_menu = "none",
        placed = false,
        ready = false,
        spawn_pos = self:get_pos()
    }
end

function GameObject:remove_player(player_name)
    for i, player in ipairs(self.players) do
        if player.name == player_name then
            table.remove(self.players, i)
            va_game.remove_player_actor(player.name)
            break
        end
    end
end

function GameObject:get_players()
    return self.players
end

function GameObject:get_player(player_name)
    return self.players[player_name]
end

function GameObject:get_player_count()
    local count = 0
    for _, player in pairs(self.players) do
        count = count + 1
    end
    return count
end

-- spectators
function GameObject:add_spectator(player_name, is_boss)
    table.insert(self.spectators, {
        name = player_name,
        is_boss = is_boss
    })
end

function GameObject:remove_spectator(player_name)
    for i, spectator in ipairs(self.spectators) do
        if spectator.name == player_name then
            table.remove(self.spectators, i)
            break
        end
    end
end

function GameObject:get_spectators()
    return self.spectators
end

-----------------------------------------------------------------

-- check if position is within game bounds
function GameObject:is_within_bounds(pos)
    local x = pos.x
    local y = pos.y
    local z = pos.z
    local minY = self.position.y - 32
    local maxY = self.position.y + self.size.height
    local minX = self.position.x - self.size.width / 2
    local maxX = self.position.x + self.size.width / 2
    local minZ = self.position.z - self.size.depth / 2
    local maxZ = self.position.z + self.size.depth / 2
    return x >= minX and x <= maxX and y >= minY and y <= maxY and z >= minZ and z <= maxZ
end

-----------------------------------------------------------------

function GameObject:create_player_actors()
    for _, p in pairs(self.players) do
        va_game.add_player_actor(p.name, p.faction, p.team, nil)
    end
    self.created = true
end

-----------------------------------------------------------------

function GameObject:send_all_player_msg(msg)
    for _, p in pairs(self.players) do
        core.chat_send_player(p.name, msg)
    end
end

function GameObject:send_all_player_sound(sound)
    for _, p in pairs(self.players) do
        core.sound_play(sound, {
            gain = 1.0,
            pitch = 1.0,
            to_player = p.name
        })
    end
end

-----------------------------------------------------------------

function GameObject:tick_ctl()
    for _, pplayer in pairs(self.players) do
        local p_name = pplayer.name
        local selected_units = va_commands.get_player_selected_units(p_name)
        local found_builder = false
        local found_repairer = false
        local found_attacker = false
        local found_reclaimer = false
        local found_commander = false
        for _, selected_entity in ipairs(selected_units) do
            if selected_entity._can_build then
                found_builder = true
            end
            if selected_entity._can_repair then
                found_repairer = true
            end
            if selected_entity._can_attack then
                found_attacker = true
            end
            if selected_entity._can_reclaim then
                found_reclaimer = true
            end
            if selected_entity._is_commander then
                found_commander = true
            end
        end
        if #selected_units == 0 then
            self:player_ctl_base(p_name)
        elseif found_commander then
            self:player_ctl_unit_commander(p_name)
        elseif found_builder then
            self:player_ctl_unit_build(p_name)
        elseif found_attacker then
            self:player_ctl_unit_combat(p_name)
        elseif found_reclaimer or found_repairer then
            self:player_ctl_unit_reclaim(p_name)
        end
    end
end

function GameObject:check_modes()
    if core.get_us_time() - self.start_time < 3 * 1000 * 1000 then
        return
    end
    local vote_stop_max = math.max(1, math.ceil((self:get_player_count() / 2) + 0.5))
    local vote_stop = 0
    for _, vote in pairs(self.votes_stop) do
        if vote then
            vote_stop = vote_stop + 1
        end
    end
    if vote_stop >= vote_stop_max then
        self:send_all_player_msg("> Stop vote passed!")
        self:send_all_player_msg(core.colorize("#FF1A1A", "Battle Ended."))
        self:set_stopped(true)
        return
    end
    local remaining = 0
    local commanders = {}
    for _, v in pairs(self.players) do
        local has_commander = false
        -- local units = va_units.get_player_units(v.name)
        local units = va_units.get_all_units()
        for _, unit in pairs(units) do
            if unit._owner_name == v.name then
                if unit.object:get_luaentity()._is_commander == true then
                    has_commander = true
                    commanders[unit._owner_name] = true
                end
            end
        end
        if has_commander then
            remaining = remaining + 1
        end
    end
    if remaining <= 1 and #self.players > 1 then
        for key, value in pairs(commanders) do
            if value then
                table.insert(self.victors, key)
            end
        end
        self:set_ended(true)
    end
end

-----------------------------------------------------------------

function GameObject:player_ctl_clear(player_name)
    local player = core.get_player_by_name(player_name)
    local g_player = self:get_player(player_name)
    if not player or not g_player then
        return
    end
    if g_player.selected_menu ~= "" then
        g_player.selected_menu = ""
    else
        return
    end
    local inv = player:get_inventory()
    local inv_name = "main"
    -- local inv_list = inv:get_list(inv_name)
    inv:set_list(inv_name, {})
end

function GameObject:player_ctl_init(player_name)
    local player = core.get_player_by_name(player_name)
    local g_player = self:get_player(player_name)
    if not player or not g_player then
        return
    end
    if g_player.placed then
        -- return
    end
    if g_player.selected_menu ~= "init" then
        g_player.selected_menu = "init"
    else
        return
    end
    local inv = player:get_inventory()
    local inv_name = "main"
    local marker_item = ItemStack({
        name = "va_game:command_marker",
        count = 1
    })
    inv:set_list(inv_name, {marker_item})
    player:hud_set_hotbar_itemcount(1)
    player:hud_set_hotbar_image("va_hud_hotbar_1.png")
end

function GameObject:player_ctl_base(player_name)
    local player = core.get_player_by_name(player_name)
    local g_player = self:get_player(player_name)
    if not player or not g_player then
        return
    end
    if not g_player.placed then
        return
    end
    if g_player.selected_menu ~= "base" then
        g_player.selected_menu = "base"
    else
        return
    end
    local inv = player:get_inventory()
    local inv_name = "main"
    local select = ItemStack({
        name = "va_commands:select",
        count = 1
    })
    local select_all = ItemStack({
        name = "va_commands:select_all",
        count = 1
    })
    inv:set_list(inv_name, {select, select_all})
    player:hud_set_hotbar_itemcount(2)
    player:hud_set_hotbar_image("va_hud_hotbar_2.png")
end

function GameObject:player_ctl_unit_commander(player_name)
    local player = core.get_player_by_name(player_name)
    local g_player = self:get_player(player_name)
    if not player or not g_player then
        return
    end
    if not g_player.placed then
        return
    end
    if g_player.selected_menu ~= "commander" then
        g_player.selected_menu = "commander"
    else
        return
    end
    local inv = player:get_inventory()
    local inv_name = "main"
    local select = ItemStack({
        name = "va_commands:select",
        count = 1
    })
    local select_all = ItemStack({
        name = "va_commands:select_all",
        count = 1
    })
    local stop = ItemStack({
        name = "va_commands:stop",
        count = 1
    })
    local move = ItemStack({
        name = "va_commands:move",
        count = 1
    })
    local guard = ItemStack({
        name = "va_commands:guard",
        count = 1
    })
    local attack_move = ItemStack({
        name = "va_commands:attack_move",
        count = 1
    })
    local build = ItemStack({
        name = "va_commands:build",
        count = 1
    })
    local reclaim = ItemStack({
        name = "va_commands:reclaim",
        count = 1
    })
    local repair = ItemStack({
        name = "va_commands:repair",
        count = 1
    })
    local attack = ItemStack({
        name = "va_commands:attack",
        count = 1
    })
    player:hud_set_hotbar_itemcount(10)
    player:hud_set_hotbar_image("va_hud_hotbar_10.png")
    inv:set_list(inv_name, {select, select_all, stop, move, attack_move, guard, build, reclaim, repair, attack})
end

function GameObject:player_ctl_unit_build(player_name)
    local player = core.get_player_by_name(player_name)
    local g_player = self:get_player(player_name)
    if not player or not g_player then
        return
    end
    if not g_player.placed then
        return
    end
    if g_player.selected_menu ~= "build" then
        g_player.selected_menu = "build"
    else
        return
    end
    local inv = player:get_inventory()
    local inv_name = "main"
    local select = ItemStack({
        name = "va_commands:select",
        count = 1
    })
    local select_all = ItemStack({
        name = "va_commands:select_all",
        count = 1
    })
    local stop = ItemStack({
        name = "va_commands:stop",
        count = 1
    })
    local move = ItemStack({
        name = "va_commands:move",
        count = 1
    })
    local guard = ItemStack({
        name = "va_commands:guard",
        count = 1
    })
    local attack_move = ItemStack({
        name = "va_commands:attack_move",
        count = 1
    })
    local build = ItemStack({
        name = "va_commands:build",
        count = 1
    })
    local reclaim = ItemStack({
        name = "va_commands:reclaim",
        count = 1
    })
    local repair = ItemStack({
        name = "va_commands:repair",
        count = 1
    })
    local capture = ItemStack({
        name = "va_commands:capture",
        count = 1
    })
    player:hud_set_hotbar_itemcount(10)
    player:hud_set_hotbar_image("va_hud_hotbar_10.png")
    inv:set_list(inv_name, {select, select_all, stop, move, attack_move, guard, build, reclaim, repair, capture})
end

function GameObject:player_ctl_unit_reclaim(player_name)
    local player = core.get_player_by_name(player_name)
    local g_player = self:get_player(player_name)
    if not player or not g_player then
        return
    end
    if not g_player.placed then
        return
    end
    if g_player.selected_menu ~= "build" then
        g_player.selected_menu = "build"
    else
        return
    end
    local inv = player:get_inventory()
    local inv_name = "main"
    local select = ItemStack({
        name = "va_commands:select",
        count = 1
    })
    local select_all = ItemStack({
        name = "va_commands:select_all",
        count = 1
    })
    local stop = ItemStack({
        name = "va_commands:stop",
        count = 1
    })
    local move = ItemStack({
        name = "va_commands:move",
        count = 1
    })
    local guard = ItemStack({
        name = "va_commands:guard",
        count = 1
    })
    local attack_move = ItemStack({
        name = "va_commands:attack_move",
        count = 1
    })
    local reclaim = ItemStack({
        name = "va_commands:reclaim",
        count = 1
    })
    local repair = ItemStack({
        name = "va_commands:repair",
        count = 1
    })
    inv:set_list(inv_name, {select, select_all, stop, move, attack_move, guard, reclaim, repair})
    player:hud_set_hotbar_itemcount(8)
    player:hud_set_hotbar_image("va_hud_hotbar_8.png")
end

function GameObject:player_ctl_unit_combat(player_name)
    local player = core.get_player_by_name(player_name)
    local g_player = self:get_player(player_name)
    if not player or not g_player then
        return
    end
    if not g_player.placed then
        return
    end
    if g_player.selected_menu ~= "combat" then
        g_player.selected_menu = "combat"
    else
        return
    end
    local inv = player:get_inventory()
    local inv_name = "main"
    local select = ItemStack({
        name = "va_commands:select",
        count = 1
    })
    local select_all = ItemStack({
        name = "va_commands:select_all",
        count = 1
    })
    local stop = ItemStack({
        name = "va_commands:stop",
        count = 1
    })
    local move = ItemStack({
        name = "va_commands:move",
        count = 1
    })
    local guard = ItemStack({
        name = "va_commands:guard",
        count = 1
    })
    local attack = ItemStack({
        name = "va_commands:attack",
        count = 1
    })
    local attack_move = ItemStack({
        name = "va_commands:attack_move",
        count = 1
    })
    inv:set_list(inv_name, {select, select_all, stop, move, guard, attack_move, attack })
    player:hud_set_hotbar_itemcount(7)
    player:hud_set_hotbar_image("va_hud_hotbar_7.png")
end

-----------------------------------------------------------------

return GameObject
