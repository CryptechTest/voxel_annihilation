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
        id = 1,
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
    self.map_objects = {}
    -- timers
    self.start_time = 0
    self.run_time = 0
    -- tick counter
    self.run_tick = 0
    self.run_tick_max = 4
    self.end_tick = 4 * 3
    -- setup
    self.setup_index = 10 -- index of the setup step for the game
    self.start_index = 61 -- index of the start step for the game
    -- cleanup
    self.dispose_tick = 0
    self.dispose_tick_max = 21
    self._disposing = false
    self._disposed = false
    -- flags
    self.created = false -- game board is created
    self.loaded = false -- game board is loaded
    self.setup = false -- game is setup
    self.ready_start = false -- all players are ready for start
    self.started = false -- game has started
    self.stopped = false -- game has stoppped (no victor)
    self.paused = false -- game is paused
    self.ending = false -- game is ending
    self.cleared = false -- game board  is cleared
    self.ended = false -- game has ended (has victor)
    return self
end

-----------------------------------------------------------------
-----------------------------------------------------------------
--- tick run functions

function GameObject:init()
    if self.setup_index == 10 then
        self:send_all_player_msg("Battlefield is being created... Please wait!")
        -- setup the game board....
        self:load_battlefield()
    elseif self.setup_index == 8 then
        self:setup_bounding_box()
    elseif self.setup_index == 7 then
        self:send_all_player_msg("Battlefield loading...  Preparing Game...")
    elseif self.setup_index == 6 then
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
                -- player:move_to(p.spawn_pos)
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
    self:dipose_bounding_box()
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

function GameObject:clean_board()
    self.cleaned = true
    local teams = self:get_teams()
    for _, team in pairs(teams) do
        for _, pname in pairs(team.players) do
            if not self.victors[pname] then
                local structures = va_structures.get_player_structures(pname)
                if structures then
                    for _, structure in pairs(structures) do
                        structure:destroy()
                    end
                end
                local units = va_units.get_player_units(pname)
                if units then
                    for _, unit in pairs(units) do
                        if unit.object then
                            unit.object:get_luaentity():_destroy(true)
                        end
                    end
                end
            end
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
        if self.loaded then
            -- setup game...
            self.setup_index = self.setup_index - 1
            if self.setup_index <= 0 then
                self.setup = true
            end
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
    if self.ending and not self.ended then
        self.end_tick = self.end_tick - 1
        if self.end_tick <= 0 then
            self.ended = true
        end
        if not self.cleaned then
            self.cleaned = true
            core.after(0, function()
                self:clean_board()
            end)
        end
    end
    if self.stopped or self.ended then
        self:send_all_player_sound("va_game_amy_battle_ended")
        self:update_lobby_ui()
        for _, p in pairs(self.players) do
            local player = core.get_player_by_name(p.name)
            if player then
                self:player_ctl_clear(p.name)
                va_commands.clear_selection(player)
            end
        end
        -- dispose game
        self._disposing = true
        return
    end
    if self.paused then
        -- game is paused...
        return
    end
    if tick_index == 0 then
        self.run_time = self.run_time + 1
    end
    ---------------------------------
    -- tick game...
    self:tick_ctl()
    if tick_index == 0 then
        self:update_lobby_ui()
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

function GameObject:is_ending()
    return self.ending
end

function GameObject:set_ending(value)
    self.ending = value
end

-- Getter and Setter for victors
function GameObject:get_victors()
    return self.victors
end

function GameObject:set_victors(value)
    self.victors = value
end

-----------------------------------------------------------------

local function generate_uuid()
    local random = math.random
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- teams
function GameObject:add_team(id, _players)
    local uuid = generate_uuid()
    local players = {}
    for pname, v in pairs(_players) do
        if v then
            table.insert(players, pname)
        end
    end
    table.insert(self.teams, {
        id = id,
        players = players,
        uuid = uuid
    })
    core.log("Added new team: [" .. id .. "] " .. uuid)
end

function GameObject:remove_team(team_id)
    for i, team in ipairs(self.teams) do
        if team.uuid == team_id then
            table.remove(self.teams, i)
            break
        end
    end
end

function GameObject:remove_player_from_team(pname)
    for _, team in pairs(self.teams) do
        for i, p in ipairs(team.players) do
            if pname == p then
                table.remove(team.players, i)
            end
        end
    end
end

function GameObject:get_team_from_player(pname)
    for _, team in pairs(self.teams) do
        for _, p in pairs(team.players) do
            if pname == p then
                return team
            end
        end
    end
    return nil
end

function GameObject:get_teams()
    return self.teams
end

-- players
function GameObject:add_player(player_name, team_uuid, faction, is_boss)
    self.players[player_name] = {
        name = player_name,
        team = team_uuid,
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
            self:remove_player_from_team(player.name)
            va_game.remove_player_actor(player.name)
            table.remove(self.players, i)
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

local _last_emerge_times = {}

local _emerge_tick_length = 5
local _emerge_tick_avg_max = 16

local function emerge_callback(pos, action, num_calls_remaining, context)
    -- On first call, record number of blocks
    if not context.total_blocks then
        context.total_blocks = num_calls_remaining + 1
        context.loaded_blocks = 0
    end

    -- Increment number of blocks loaded
    context.loaded_blocks = context.loaded_blocks + 1

    if context.loaded_blocks == 1 and not context.started then
        local msg = core.colorize("#ffdd5fff", ">> ")
        msg = msg .. core.colorize("#00f13cff", "Mapblock emerge area has started!")
        msg = msg .. "  " .. core.colorize("#979797ff", "Battlefield is warming up; Please wait...")
        context.game:send_all_player_msg(msg)
        context.started = true
    end

    local now = core.get_us_time()

    -- Send progress message
    if context.total_blocks == context.loaded_blocks then
        local t_length = (now - context.t_us_start) * 0.000001
        local t_avg_rate = context.loaded_blocks / t_length
        local msg = string.format("> Total Blocks:  %d\n" .. "> Time Taken:    %.2f Sec\n" ..
                                      "> Load Time Avg: %.1f Blk/s", context.loaded_blocks, t_length, t_avg_rate)
        msg = core.colorize("#6fa4ffff", msg)
        msg = core.colorize("#16bcc2ff", "-------------------------------\n") .. msg
        msg = core.colorize("#14aa5fff", "Finished loading Battlefield!!!\n") .. msg
        context.game:send_all_player_msg(msg)
        context.game.loaded = true

    elseif now - context._time_last_msg > 1000 * 1000 * _emerge_tick_length then
        context._tick_end_count = context.loaded_blocks - context._tick_start_count
        local t_length = (now - context.t_us_last) * 0.000001
        local _t_rate = t_length > 0 and context._tick_end_count / t_length or 0
        local t_rate = math.max(5, _t_rate)

        if now - context.t_us_start > 1000 * 1000 * (27) then
            table.insert(_last_emerge_times, t_rate)
        end
        local t_rate_total = 0
        for _, v in pairs(_last_emerge_times) do
            t_rate_total = t_rate_total + v
        end
        local t_rate_avg = #_last_emerge_times > 0 and t_rate_total / #_last_emerge_times or 0
        local t_eta = (context.total_blocks - context.loaded_blocks) / (t_rate_avg)

        local perc = 100 * context.loaded_blocks / context.total_blocks
        local msg_est = ""
        if now - context.t_us_start > 1000 * 1000 * (40) then
            msg_est = " - " .. core.colorize("#ebac00ff", string.format("Est Time: ~%.1f Sec", t_eta))
        end
        local msg = core.colorize("#ebac00ff", "[Emerge] ") .. "Loading Battlefield: " ..
                        string.format("%d / %d (%.3f%%) ", context.loaded_blocks, context.total_blocks, perc) ..
                        core.colorize("#6fa4ffff", string.format("%.1f Blk/s ", t_rate)) .. "- " ..
                        (t_rate_avg and t_rate_avg > 0 and
                            core.colorize("#3668beff", string.format("(Avg %.1f b / %i s) ", t_rate_avg,
                    _emerge_tick_avg_max * _emerge_tick_length)) or "") ..
                        core.colorize("#6fa4ffff", string.format("RUN= %.1f sec", t_length)) .. msg_est
        context.game:send_all_player_msg(msg)
        context.t_us_last = now
        context._time_last_msg = now
        context._tick_start_count = context.loaded_blocks

        if #_last_emerge_times > _emerge_tick_avg_max then
            table.remove(_last_emerge_times, 1)
        end

    end
end

local function do_emerge(self, radius)
    local pos = self:get_pos()
    if not radius or radius < 16 then
        radius = 16
    end
    -- load mapblock area of radius, based from position 0,0
    local minpos = vector.new(-radius / 1, -radius / 1, -radius / 1)
    local maxpos = vector.new(radius / 1, radius / 1, radius / 1)

    minpos = vector.add(minpos, pos)
    maxpos = vector.add(maxpos, pos)

    if minpos.y < -32 then
        minpos.y = -32
    end
    if maxpos.y > 128 then
        maxpos.y = 128
    end

    local now = core.get_us_time()
    local context = {
        game = self,
        t_us_start = now,
        t_us_last = now,
        _tick_start_count = 0,
        _tick_end_count = 0,
        _time_last_msg = now
    }
    core.emerge_area(minpos, maxpos, emerge_callback, context)
end

function GameObject:load_battlefield()
    local radius = self.size.width / 2
    self.loaded = false
    do_emerge(self, radius)
end

function GameObject:setup_bounding_box()
    local function add_map_object(pos)
        if not pos then
            return
        end
        core.load_area(pos)
        local node = core.get_node(pos)
        if node.name == "va_game:board_barrier" then
            return
        end
        local hash = core.hash_node_position(pos)
        self.map_objects[hash] = {
            pos = pos,
            name = node.name,
            param2 = node.param2
        }
        core.set_node(pos, {
            name = "bedrock2:bedrock"
        })
        local meta = core:get_meta(pos)
        meta:set_string("game_id", self.id)
    end
    -- TODO: setup for other map heights
    local minY = -32 -- math.max(-32, self.position.y - 32)
    local maxY = 128 -- math.min(128, self.position.y + 128)
    local minX = self.position.x - self.size.width / 2
    local maxX = self.position.x + self.size.width / 2
    local minZ = self.position.z - self.size.depth / 2
    local maxZ = self.position.z + self.size.depth / 2
    -- Create a hollow cube using the bounds
    for y = minY, maxY do
        if y == minY or y == maxY then
            --[[for x = minX, maxX do
                for z = minZ, maxZ do
                    local pos = {
                        x = x,
                        y = y,
                        z = z
                    }
                    if core.get_node(pos).name == "air" then
                        core.set_node(pos, {
                            name = "barrier:barrier"
                        })
                    end
                end
            end]]
        elseif y > minY and y < maxY then
            for x = minX, maxX do
                local pos1 = {
                    x = x,
                    y = y,
                    z = minZ
                }
                local pos2 = {
                    x = x,
                    y = y,
                    z = maxZ
                }
                if y % 10 == 0 or x == minX or x == maxX then
                    if core.get_node(pos1).name == "air" then
                        core.set_node(pos1, {
                            name = "va_game:board_barrier"
                        })
                    else
                        add_map_object(pos1)
                    end
                    if core.get_node(pos2).name == "air" then
                        core.set_node(pos2, {
                            name = "va_game:board_barrier"
                        })
                    else
                        add_map_object(pos2)
                    end
                else
                    if core.get_node(pos1).name == "air" then
                        core.set_node(pos1, {
                            name = "barrier:barrier"
                        })
                    else
                        add_map_object(pos1)
                    end
                    if core.get_node(pos2).name == "air" then
                        core.set_node(pos2, {
                            name = "barrier:barrier"
                        })
                    else
                        add_map_object(pos2)
                    end
                end
            end
            for z = minZ + 1, maxZ - 1 do
                local pos3 = {
                    x = minX,
                    y = y,
                    z = z
                }
                local pos4 = {
                    x = maxX,
                    y = y,
                    z = z
                }
                if y % 10 == 0 or z == minZ or z == maxZ then
                    if core.get_node(pos3).name == "air" then
                        core.set_node(pos3, {
                            name = "va_game:board_barrier"
                        })
                    else
                        add_map_object(pos3)
                    end
                    if core.get_node(pos4).name == "air" then
                        core.set_node(pos4, {
                            name = "va_game:board_barrier"
                        })
                    else
                        add_map_object(pos4)
                    end
                else
                    if core.get_node(pos3).name == "air" then
                        core.set_node(pos3, {
                            name = "barrier:barrier"
                        })
                    else
                        add_map_object(pos3)
                    end
                    if core.get_node(pos4).name == "air" then
                        core.set_node(pos4, {
                            name = "barrier:barrier"
                        })
                    else
                        add_map_object(pos4)
                    end
                end
            end
        end
    end
end

function GameObject:dipose_bounding_box()
    -- TODO: setup for other map heights
    local minY = -32 -- math.max(-32, self.position.y - 32)
    local maxY = 128 -- math.min(128, self.position.y + 128)
    local minX = self.position.x - self.size.width / 2
    local maxX = self.position.x + self.size.width / 2
    local minZ = self.position.z - self.size.depth / 2
    local maxZ = self.position.z + self.size.depth / 2
    -- Create a hollow cube using the bounds
    for y = minY, maxY do
        if y == minY or y == maxY then
            --[[for x = minX, maxX do
                for z = minZ, maxZ do
                    local pos = {
                        x = x,
                        y = y,
                        z = z
                    }
                    if core.get_node(pos).name == "barrier:barrier" then
                        core.set_node(pos, {
                            name = "air"
                        })
                    end
                end
            end]]
        elseif y > minY and y < maxY then
            for x = minX, maxX do
                local pos1 = {
                    x = x,
                    y = y,
                    z = minZ
                }
                local pos2 = {
                    x = x,
                    y = y,
                    z = maxZ
                }
                core.load_area(pos1)
                core.load_area(pos2)
                if core.get_node(pos1).name == "va_game:board_barrier" then
                    core.set_node(pos1, {
                        name = "air"
                    })
                end
                if core.get_node(pos1).name == "barrier:barrier" then
                    core.set_node(pos1, {
                        name = "air"
                    })
                end
                if core.get_node(pos2).name == "va_game:board_barrier" then
                    core.set_node(pos2, {
                        name = "air"
                    })
                end
                if core.get_node(pos2).name == "barrier:barrier" then
                    core.set_node(pos2, {
                        name = "air"
                    })
                end
            end
            for z = minZ + 1, maxZ - 1 do
                local pos3 = {
                    x = minX,
                    y = y,
                    z = z
                }
                local pos4 = {
                    x = maxX,
                    y = y,
                    z = z
                }
                core.load_area(pos3)
                core.load_area(pos4)
                if core.get_node(pos3).name == "va_game:board_barrier" then
                    core.set_node(pos3, {
                        name = "air"
                    })
                end
                if core.get_node(pos3).name == "barrier:barrier" then
                    core.set_node(pos3, {
                        name = "air"
                    })
                end
                if core.get_node(pos4).name == "va_game:board_barrier" then
                    core.set_node(pos4, {
                        name = "air"
                    })
                end
                if core.get_node(pos4).name == "barrier:barrier" then
                    core.set_node(pos4, {
                        name = "air"
                    })
                end
            end
        end
    end
    for hash, node in pairs(self.map_objects) do
        local pos = core.get_position_from_hash(hash)
        core.load_area(pos)
        if pos and core.get_node(pos).name == "bedrock2:bedrock" then
            core.set_node(pos, {
                name = node.name,
                param2 = node.param2
            })
        end
    end
    self.map_objects = {}
end

-- check if position is within game bounds
function GameObject:is_within_bounds(pos)
    local x = pos.x
    local y = pos.y
    local z = pos.z
    -- local minY = self.position.y - 32
    -- local maxY = self.position.y + self.size.height
    local minY = -32
    local maxY = 128
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
    if self:is_ending() then
        return
    end
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
    local player_count = 0
    local remaining = 0
    local commanders = {}
    local constructors = {}
    local teams = {}
    for _, v in pairs(self.players) do
        player_count = player_count + 1
        local has_commander = false
        local units = va_units.get_player_units(v.name)
        for _, unit in pairs(units) do
            local u_ent = unit.object:get_luaentity()
            local owner_name = u_ent and u_ent._owner_name or nil
            if owner_name and owner_name == v.name then
                local team_uuid = u_ent._team_uuid
                if not teams[team_uuid] then
                    if u_ent._is_commander == true then
                        has_commander = true
                        constructors[owner_name] = true
                        commanders[owner_name] = true
                        teams[team_uuid] = true
                    elseif (self.mode == 4 or self.mode == 5) and u_ent._can_build == true then
                        constructors[owner_name] = true
                        teams[team_uuid] = true
                    end
                end
            end
        end
        if has_commander then
            remaining = remaining + 1
        end
    end
    if self.mode.id == 1 then
        if remaining <= 1 and player_count > 1 then
            for key, value in pairs(commanders) do
                if value then
                    self.victors[key] = true
                end
            end
            self:set_ending(true)
        end
    elseif self.mode.id == 2 or self.mode.id == 3 then
        local team_count = 0
        for uuid, v in pairs(teams) do
            if v then
                team_count = team_count + 1
            end
        end
        if player_count == 0 then
            self:set_ended(true)
        elseif team_count <= 1 then
            for key, value in pairs(commanders) do
                if value then
                    self.victors[key] = true
                end
            end
            self:set_ending(true)
        end
    elseif self.mode.id == 4 or self.mode.id == 5 then
        local team_count = 0
        for uuid, v in pairs(teams) do
            if v then
                team_count = team_count + 1
            end
        end
        if player_count == 0 then
            self:set_ended(true)
        elseif team_count <= 1 then
            for key, value in pairs(constructors) do
                if value then
                    self.victors[key] = true
                end
            end
            self:set_ending(true)
        end
    end
    if self:is_ending() then
        for k, v in pairs(self.victors) do
            core.chat_send_player(k, core.colorize("#1AFF39","You have won the match!"))
        end
    end
end

function GameObject:commander_destroy_alert(team_uuid)
    for _, team in pairs(self.teams) do
        for _, pname in pairs(team.players) do
            local player = core.get_player_by_name(pname)
            if player then
                if team.uuid == team_uuid then
                    core.sound_play("va_game_amy_friendly_commander_died", {
                        gain = 1.0,
                        pitch = 1.0,
                        to_player = pname
                    })
                else
                    core.sound_play("va_game_amy_enemy_commander_died", {
                        gain = 1.0,
                        pitch = 1.0,
                        to_player = pname
                    })
                end
            end
        end
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
    player:hud_set_flags({
        hotbar = false
    })
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
    player:hud_set_flags({
        hotbar = true
    })
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
    player:hud_set_flags({
        hotbar = true
    })
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
    inv:set_list(inv_name, {select, select_all, stop, move, attack_move, guard, build, reclaim, repair, attack})
    player:hud_set_hotbar_itemcount(10)
    player:hud_set_hotbar_image("va_hud_hotbar_10.png")
    player:hud_set_flags({
        hotbar = true
    })
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
    inv:set_list(inv_name, {select, select_all, stop, move, attack_move, guard, build, reclaim, repair, capture})
    player:hud_set_hotbar_itemcount(10)
    player:hud_set_hotbar_image("va_hud_hotbar_10.png")
    player:hud_set_flags({
        hotbar = true
    })
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
    player:hud_set_flags({
        hotbar = true
    })
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
    inv:set_list(inv_name, {select, select_all, stop, move, attack_move, guard, attack})
    player:hud_set_hotbar_itemcount(7)
    player:hud_set_hotbar_image("va_hud_hotbar_7.png")
    player:hud_set_flags({
        hotbar = true
    })
end

-----------------------------------------------------------------

return GameObject
