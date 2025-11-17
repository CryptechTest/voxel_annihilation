local modname = core.get_current_modname()
local mod_path = core.get_modpath(modname)

local GameObject = dofile(mod_path .. "/src/game.lua")

function va_game.init_game_from_lobby(lobby)
    if not lobby then
        return nil
    end
    local pos = lobby.game_position or {
        x = 0,
        y = 0,
        z = 0
    }
    local size = lobby.board_size or {
        width = 256,
        height = 128,
        depth = 256
    }
    local mode = {
        name = lobby.mode,
        difficulty = lobby.wd_difficulty
    }

    -- create a new game instance
    local game = GameObject.new(pos, size, mode, lobby.name, lobby.password)

    -- add teams to the game object
    for _, team in ipairs(lobby.teams) do
        game:add_team(team)
    end
    -- add players to the game object
    for _, pname in pairs(lobby.players) do
        local is_boss = lobby.bosses[pname] and lobby.bosses[pname] == true or false
        game:add_player(pname, 1, "vox", is_boss)
    end
    -- add spectators to the game object
    for _, pname in pairs(lobby.spectators) do
        local is_boss = lobby.bosses[pname] and lobby.bosses[pname] == true or false
        game:add_spectator(pname, is_boss)
    end

    -- add new game to game tracking
    va_game.games[game:get_id()] = game

    return game
end

function va_game.tick_all(run_tick)
    for _, game in pairs(va_game.games) do
        game:tick(run_tick)
    end
end

function va_game.get_game(game_id)
    return va_game.games[game_id]
end

function va_game.get_game_from_lobby(lobby_name)
    for _, game in pairs(va_game.games) do
        if game:get_name() == lobby_name then
            return game
        end
    end
    return nil
end

function va_game.get_game_from_player(player_name)
    for _, game in pairs(va_game.games) do
        for _, p in pairs(game.players) do
            if p.name == player_name then
                return game
            end
        end
    end
    return nil
end