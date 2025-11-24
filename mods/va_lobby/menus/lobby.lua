local formspecs = {}
local pages = {}
pages.main_menu = nil

-- main menu formspec
local tmp = {"size[8,3]", [[
    no_prepend[]
    formspec_version[10]
    bgcolor[#101010;]
    style_type[label;font_size=28;font=bold]
    label[0,0;Voxel Annihilation]
    style[join,host;bgcolor=#00ff00;font_size=22;font=bold]
    style[cancel;bgcolor=#ff0000]
    button[0.75,0.6;3,2;join;Join]
    button[4.25,0.6;3,2;host;Host]
    button_exit[5.5,2.5;2,0.5;cancel;Cancel]
    ]]}

pages.main_menu = table.concat(tmp, "")

-- lobby create formspec
local function get_lobby_setup(owner, mode)
    local pos = core.get_player_by_name(owner):get_pos()
    local setup = {"size[8,8]", [[
    no_prepend[]
    formspec_version[10]
    bgcolor[#101010;]
    style_type[label;font_size=22;font=bold]
    label[0,0;Setup Lobby]
    field[0.75,1.3;7,1;game_name;Lobby Name;]
    pwdfield[0.75,2.4;7,1;password;Password (optional)]
    style_type[label;font_size=16;font=bold]
    label[0.5,2.9;Mode]
    dropdown[0.465,3.3;3.5;mode;Wave Defense,Assassination Teams,Assassination FFA,Annihilation Teams,Annihilation FFA;]] .. mode .. [[;true]
    field[0.75,4.6;3.5,1;game_position;Lobby Position;]] .. math.floor(pos.x) .. [[ ]] .. math.floor(pos.y) .. [[ ]] ..
        math.floor(pos.z) .. [[]
    label[4,3.99;Map Size]
    dropdown[4,4.3655;3.5;game_board_size;256,384,512,640,768,896,1024;1;true]
    style[cancel;bgcolor=#ff0000]
    button_exit[5.5,7.5;2,0.5;cancel;Cancel]
    style[save;bgcolor=#00ff00]
    button[0.5,7.5;2,0.5;save;Save]
    ]]}
    if mode == 1 then
        table.insert(setup, "label[4,2.9;Difficulty]")
        table.insert(setup, "dropdown[4,3.3;3.5;wd_difficulty;Easy,Medium,Hard,Extreme;1;true]")
    end
    return table.concat(setup, "")
end

-----------------------------------------------------------------

-- get lobby by owner
local function get_lobby(owner)
    local lobby = va_lobby.lobbies[owner]
    if lobby == nil then
        return pages.main_menu
    end
    local mode = tonumber(lobby.mode)
    local t_count = #lobby.teams
    local function update_lobby_players(formspec, x_min, y_min, teamid)
        teamid = teamid or 1
        local team_player_count = 0
        for _, player in ipairs(lobby.players) do
            if lobby.teams[teamid] and lobby.teams[teamid][player] then
                team_player_count = team_player_count + 1
            end
        end
        if mode == 1 and teamid == 2 then
            team_player_count = team_player_count + 1
        end
        x_min = x_min or 0.25
        y_min = y_min or 1.0
        local x_siz = 3.5
        local y_siz = 0.4
        local x = x_min
        local y = y_min
        local t_box_loc = (x - 0.1) .. "," .. (y - 0.51)
        local t_box_size = "7.5" .. "," .. "3.0"
        local is_wave_def = false
        if mode == 1 then
            is_wave_def = true
            t_box_size = "7.5" .. "," .. "4.5"
        elseif mode == 3 or mode == 5 then
            t_box_size = "7.5" .. "," .. "6.0"
        end
        local max_team_player_count = 8
        if is_wave_def and teamid == 2 then
            max_team_player_count = 2
            t_box_size = "7.5" .. "," .. "1.40"
        elseif t_count == 2 then
            max_team_player_count = 4
        elseif t_count == 3 then
            t_box_size = "7.5" .. "," .. "1.95"
            max_team_player_count = 3
        elseif t_count == 4 then
            t_box_size = "7.5" .. "," .. "1.40"
            max_team_player_count = 2
        end
        local t_box = "box[" .. t_box_loc .. ";" .. t_box_size .. ";" .. "#1B1B1B" .. "]"
        table.insert(formspec, t_box)
        table.insert(formspec, "style_type[label;font_size=20;font=bold]")
        table.insert(formspec, "label[" .. (x_min) .. "," .. (y_min - 0.5) .. ";Team " .. teamid .. "]")
        table.insert(formspec, "style_type[label;font_size=18;font=bold]")
        table.insert(formspec, "label[" .. (x_min + 2) .. "," .. (y_min - 0.5) .. ";" ..
            core.colorize("#9EF9FF", team_player_count .. "/" .. max_team_player_count) .. "]")
        table.insert(formspec, "style_type[label;font_size=20;font=bold]")
        if t_count == 2 then
            table.insert(formspec, "real_coordinates[true]")
            table.insert(formspec, "style[team_join_" .. owner .. "_" .. teamid .. ";bgcolor=#00af00]")
            local j_y = (y_min - 0.05)
            if teamid == 2 then
                j_y = j_y + 0.515
            end
            table.insert(formspec, "button[" .. (x_min + 7.6) .. "," .. j_y .. ";2.0,0.45;team_join_" .. owner .. "_" ..
                teamid .. ";Join Team]")
            table.insert(formspec, "real_coordinates[false]")
        elseif t_count == 3 then
            table.insert(formspec, "real_coordinates[true]")
            table.insert(formspec, "style[team_join_" .. owner .. "_" .. teamid .. ";bgcolor=#00af00]")
            local j_y = (y_min - 0.05)
            if teamid == 2 then
                j_y = j_y + 0.32725
            elseif teamid == 3 then
                j_y = j_y + 0.67225
            end
            table.insert(formspec, "button[" .. (x_min + 7.6) .. "," .. j_y .. ";2.0,0.45;team_join_" .. owner .. "_" ..
                teamid .. ";Join Team]")
            table.insert(formspec, "real_coordinates[false]")
        elseif t_count == 4 then
            table.insert(formspec, "real_coordinates[true]")
            table.insert(formspec, "style[team_join_" .. owner .. "_" .. teamid .. ";bgcolor=#00af00]")
            local j_y = (y_min - 0.05)
            if teamid == 2 then
                j_y = j_y + 0.228
            elseif teamid == 3 then
                j_y = j_y + 0.515
            elseif teamid == 4 then
                j_y = j_y + 0.7515
            end
            table.insert(formspec, "button[" .. (x_min + 7.6) .. "," .. j_y .. ";2.0,0.45;team_join_" .. owner .. "_" ..
                teamid .. ";Join Team]")
            table.insert(formspec, "real_coordinates[false]")
        end
        table.insert(formspec, "style_type[label;font_size=17;font=bold]")
        for _, player in pairs(lobby.players) do
            if lobby.teams[teamid] and lobby.teams[teamid][player] ~= nil then -- player is in team
                local p_box_loc = (x - 0.05) .. "," .. (y - 0.025)
                local p_box_size = x_siz .. "," .. y_siz
                local p_box = "box[" .. p_box_loc .. ";" .. p_box_size .. ";" .. "#313131" .. "]"
                table.insert(formspec, p_box)
                local p_label = "label[" .. (x + 0.05) .. "," .. y - 0.05 .. ";" .. player .. "]"
                table.insert(formspec, p_label)
                local ready = lobby.players_ready[player] or false
                local p_ready = "checkbox[" .. x + 2.0 .. "," .. y - 0.25 .. ";ready_" .. player .. ";Ready;" ..
                                    tostring(ready) .. "]"
                table.insert(formspec, p_ready)
                x = x + x_siz + 0.3
                if x >= 7 then
                    x = x_min
                    y = y + y_siz + 0.1
                end
            end
        end
        if is_wave_def and teamid == 2 then
            local bot_ai = "Wave AI"
            local p_box_loc = (x - 0.05) .. "," .. (y - 0.025)
            local p_box_size = x_siz .. "," .. y_siz
            local p_box = "box[" .. p_box_loc .. ";" .. p_box_size .. ";" .. "#313131" .. "]"
            table.insert(formspec, p_box)
            local p_label = "label[" .. (x + 0.05) .. "," .. y - 0.05 .. ";" .. bot_ai .. "]"
            table.insert(formspec, p_label)
            local ready = true
            local p_ready = "checkbox[" .. x + 2.0 .. "," .. y - 0.25 .. ";ready_" .. bot_ai .. ";Ready;" ..
                                tostring(ready) .. "]"
            table.insert(formspec, p_ready)
        end
    end
    local function add_start(formspec)
        local can_start = true
        for _, player in pairs(lobby.players) do
            if not lobby.players_ready[player] then
                can_start = false
                break
            end
        end
        local bgcolor = "#ff9f00"
        if can_start then
            bgcolor = "#00ff00"
        end
        table.insert(formspec, "style[start;bgcolor=" .. bgcolor .. "]")
        table.insert(formspec, "button[0.0,7.5;2,0.5;start;Start]")
    end
    local function add_spectate(formspec)
        local bgcolor = "#00FFEA"
        table.insert(formspec, "style[spectate_start;bgcolor=" .. bgcolor .. "]")
        table.insert(formspec, "button[2.25,7.5;2,0.5;spectate_start;Spectate]")
    end

    local g_mode = "Unknown"
    if lobby.mode == 1 then
        local difficulty = "Unknown"
        if lobby.wd_difficulty == 1 or lobby.wd_difficulty == "1" then
            difficulty = "Easy"
        elseif lobby.wd_difficulty == 2 or lobby.wd_difficulty == "2" then
            difficulty = "Medium"
        elseif lobby.wd_difficulty == 3 or lobby.wd_difficulty == "3" then
            difficulty = "Hard"
        elseif lobby.wd_difficulty == 4 or lobby.wd_difficulty == "4" then
            difficulty = "Extreme"
        end
        g_mode = core.colorize("#AD32FF", "Wave Def" .. "(" .. difficulty .. ")")
    elseif lobby.mode == 2 then
        g_mode = core.colorize("#FFAB0F", "Assassination Teams")
    elseif lobby.mode == 3 then
        g_mode = core.colorize("#FF5B0F", "Assassination FFA")
    elseif lobby.mode == 4 then
        g_mode = core.colorize("#FF2B0F", "Annihilation Teams")
    elseif lobby.mode == 5 then
        g_mode = core.colorize("#FF170F", "Annihilation FFA")
    end

    if mode == 1 then
        local formspec = {"size[8,8]", [[
            no_prepend[]
            formspec_version[10]
            bgcolor[#101010;]
            style_type[label;font_size=22;font=bold]
            label[0,-0.1;]] .. lobby.name .. [[]
            style[leave;bgcolor=#ff0000]
            button_exit[6.5,7.5;1.5,0.5;leave;Leave]
            ]]}
        update_lobby_players(formspec)
        update_lobby_players(formspec, 0.25, 5.75, 2)
        table.insert(formspec, "style_type[label;font_size=17;font=bold]")
        table.insert(formspec,
            "label[5.5,0;Players]" .. "label[7,0;" .. #lobby.players .. "/" .. lobby.players_max .. "]")
        table.insert(formspec, "style_type[label;font_size=18;font=bold]")
        table.insert(formspec, "label[0.2,6.75;Game Mode: " .. g_mode .. "]")
        local game = va_game.get_game_from_lobby(lobby.name)
        if not game or (game and game:is_started()) then
            add_start(formspec)
        end
        add_spectate(formspec)
        local lobby_formspec = table.concat(formspec, "")
        return lobby_formspec
    elseif mode == 2 or mode == 4 then
        local formspec = {"size[8,8]", [[
            no_prepend[]
            formspec_version[10]
            bgcolor[#101010;]
            style_type[label;font_size=22;font=bold]
            label[0,-0.1;]] .. lobby.name .. [[]
            style[leave;bgcolor=#ff0000]
            button_exit[6.5,7.5;1.5,0.5;leave;Leave]
            ]]}
        if t_count == 2 then
            update_lobby_players(formspec, 0.25, 1, 1)
            update_lobby_players(formspec, 0.25, 4.2, 2)
        elseif t_count == 3 then
            update_lobby_players(formspec, 0.25, 1, 1)
            update_lobby_players(formspec, 0.25, 3.12, 2)
            update_lobby_players(formspec, 0.25, 5.265, 3)
        elseif t_count == 4 then
            update_lobby_players(formspec, 0.25, 1, 1)
            update_lobby_players(formspec, 0.25, 2.6, 2)
            update_lobby_players(formspec, 0.25, 4.2, 3)
            update_lobby_players(formspec, 0.25, 5.8, 4)
        end
        table.insert(formspec, "style_type[label;font_size=16;font=bold]")
        table.insert(formspec,
            "label[5.50,0.06;Players]" .. "label[7,0.06;" .. #lobby.players .. "/" .. lobby.players_max .. "]")
        table.insert(formspec, "real_coordinates[true]")
        table.insert(formspec, "label[7.25,0.25;Teams]")
        table.insert(formspec,
            "dropdown[8.85,0.025;1.1,0.5;team_count_" .. owner .. ";2,3,4;" .. t_count - 1 .. ";true]")
        table.insert(formspec, "real_coordinates[false]")
        table.insert(formspec, "style_type[label;font_size=18;font=bold]")
        table.insert(formspec, "label[0.20,6.75;Game Mode: " .. g_mode .. "]")
        local game = va_game.get_game_from_lobby(lobby.name)
        if not game or (game and game:is_started()) then
            add_start(formspec)
        end
        add_spectate(formspec)
        local lobby_formspec = table.concat(formspec, "")
        return lobby_formspec
    elseif mode == 3 or mode == 5 then
        local formspec = {"size[8,8]", [[
            no_prepend[]
            formspec_version[10]
            bgcolor[#101010;]
            style_type[label;font_size=22;font=bold]
            label[0,-0.1;]] .. lobby.name .. [[]
            style[leave;bgcolor=#ff0000]
            button_exit[6.5,7.5;1.5,0.5;leave;Leave]
            ]]}
        update_lobby_players(formspec)
        table.insert(formspec, "style_type[label;font_size=17;font=bold]")
        table.insert(formspec,
            "label[5.5,0;Players]" .. "label[7,0;" .. #lobby.players .. "/" .. lobby.players_max .. "]")
        table.insert(formspec, "style_type[label;font_size=18;font=bold]")
        table.insert(formspec, "label[0.2,6.75;Game Mode: " .. g_mode .. "]")
        local game = va_game.get_game_from_lobby(lobby.name)
        if not game or (game and game:is_started()) then
            add_start(formspec)
        end
        add_spectate(formspec)
        local lobby_formspec = table.concat(formspec, "")
        return lobby_formspec
    else
        core.log("mode not found?")
    end
end

--- get all lobbies
local function get_lobbies()
    local lobbies = {"size[8,8]", [[
    no_prepend[]
    formspec_version[10]
    bgcolor[#101010;]
    style_type[label;font_size=22;font=bold]
    label[0,0;Lobbies]
    style[cancel;bgcolor=#ff0000]
    button_exit[5.5,7.5;2,0.5;cancel;Cancel]
    ]]}
    local count = 0
    for pname, lobby in pairs(va_lobby.lobbies) do
        local mode = "Unknown"
        if lobby.mode == 1 then
            local difficulty = "Unknown"
            if lobby.wd_difficulty == 1 or lobby.wd_difficulty == "1" then
                difficulty = "Easy"
            elseif lobby.wd_difficulty == 2 or lobby.wd_difficulty == "2" then
                difficulty = "Medium"
            elseif lobby.wd_difficulty == 3 or lobby.wd_difficulty == "3" then
                difficulty = "Hard"
            elseif lobby.wd_difficulty == 4 or lobby.wd_difficulty == "4" then
                difficulty = "Extreme"
            end
            mode = "Wave Def" .. "(" .. difficulty .. ")"
        elseif lobby.mode == 2 then
            mode = "Assassination Teams"
        elseif lobby.mode == 3 then
            mode = "Assassination FFA"
        elseif lobby.mode == 4 then
            mode = "Annihilation Teams"
        elseif lobby.mode == 5 then
            mode = "Annihilation FFA"
        end
        local lobby_display = ""
        if #lobby.name > 25 then
            lobby_display = string.sub(lobby.name, 1, 25)
        else
            lobby_display = lobby.name
        end
        table.insert(lobbies, "style_type[label;font_size=16;font=mono]")
        table.insert(lobbies, "label[1," .. 0.75 + (count * 0.75) .. ";" .. lobby_display .. "]")
        table.insert(lobbies, "style_type[label;font_size=14;font=mono]")
        table.insert(lobbies, "label[4.8," .. 0.75 + (count * 0.75) .. ";" .. mode .. "]")
        table.insert(lobbies, "style_type[label;font_size=16;font=mono]")
        table.insert(lobbies,
            "label[7.25," .. 0.75 + (count * 0.75) .. ";" .. (lobby.players and #lobby.players or 0) .. "/8 ]")
        table.insert(lobbies, "style[join_" .. pname .. ";bgcolor=#00ff00]")
        table.insert(lobbies,
            "button[0," .. 0.75 + (count * 0.75) .. ";1,0.5;join_" .. pname .. ";" ..
                (lobby.password ~= "" and "Join" or "Join") .. "]")
        count = count + 1
    end
    return table.concat(lobbies, "")
end

local function get_game_setup(owner, game)
    local lobby = va_lobby.lobbies[owner]
    if lobby == nil then
        return pages.main_menu
    end
    local init_msg = "Initializing in... " .. tostring(game.setup_index) .. " seconds"
    if game.setup_index > 8 then
        init_msg = "...Preparing Battlefield..."
    end
    -- allow_close[false]
    local formspec = {"size[4,2]", [[
        no_prepend[]
        formspec_version[10]
        bgcolor[#101010;]
        style_type[label;font_size=22;font=bold]
        label[0,0;]] .. lobby.name .. [[]
        style_type[label;font_size=19;font=bold]
        label[0.25,0.75;]] .. init_msg .. [[]
        button_exit[2.5,1.75;1.5,0.45;close;Close]
    ]]}
    local game_formspec = table.concat(formspec, "")
    return game_formspec
end

local function get_game_start(lobby_owner, pname, game)
    local lobby = va_lobby.lobbies[lobby_owner]
    if lobby == nil then
        return pages.main_menu
    end
    local formspec = {"size[4,2.5]", [[
        no_prepend[]
        formspec_version[10]
        bgcolor[#101010;]
        style_type[label;font_size=22;font=bold]
        label[0,0;]] .. lobby.name .. [[]
        style_type[label;font_size=16;font=normal]
        label[0.05,0.5;Please choose a starting location...]
        style_type[label;font_size=18;font=bold]
        label[0.5,1.25;Starting in... ]] .. tostring(game.start_index) .. [[]
        button_exit[2.5,2.25;1.5,0.45;close;Close]
    ]]}
    local ready = game.players[pname] and game.players[pname].ready or false
    local p_ready = "checkbox[0.25,2.0;ready_start_" .. pname .. ";Ready;" .. tostring(ready) .. "]"
    table.insert(formspec, p_ready)
    local game_formspec = table.concat(formspec, "")
    return game_formspec
end

local function get_game_active(lobby_owner, pname, game)
    local lobby = va_lobby.lobbies[lobby_owner]
    if lobby == nil then
        return pages.main_menu
    end
    local game_act = "Game is Active!"
    if game:is_stopped() then
        game_act = "Game Stopped!"
    elseif game:is_ended() then
        game_act = "Game has Ended!"
    end
    local vote_stop = 0
    for _, vote in pairs(game.votes_stop) do
        if vote then
            vote_stop = vote_stop + 1
        end
    end
    local game_hour = math.floor(game.run_time / 60 / 60)
    local game_mins = math.floor(game.run_time / 60)
    local game_secs = game.run_time % 60
    local game_time = string.format("%02d:%02d", game_mins, game_secs)
    if game_hour > 0 then
        game_time = string.format("%02d:", game_hour) .. game_time
    end
    local vote_stop_max = math.max(1, math.ceil((game:get_player_count() / 2) + 0.5))
    local formspec = {"size[8,8]", [[
        no_prepend[]
        formspec_version[10]
        bgcolor[#101010;]
        style_type[label;font_size=22;font=bold]
        label[0,0;]] .. lobby.name .. [[]
        style_type[label;font_size=16;font=normal]
        label[0.05,0.5;]] .. game_act .. [[]
        style_type[label;font_size=16;font=bold]
        label[5.25,0.5;Elapsed Time: ]] .. game_time .. [[]
        style_type[label;font_size=18;font=bold]
        style[vote_stop;bgcolor=#ff1f00]
        button[0.25,6.5;2,0.5;vote_stop;Vote Stop]
        label[2.5,6.425;Votes: ]] .. vote_stop .. "/" .. vote_stop_max .. [[]
        style[quit_game;bgcolor=#ff0000]
        button[0.25,7.5;2,0.5;quit_game;Quit Game]
        style[close;bgcolor=#ff9f00]
        button_exit[6.5,7.5;1.5,0.45;close;Close]
    ]]}
    if game._disposing then
        table.insert(formspec, "style_type[label;font_size=16;font=bold;textcolor=" .. "#F5BE28" .. "]")
        table.insert(formspec,
            "label[4.25,0;Game Closes in " .. (game.dispose_tick_max - game.dispose_tick) .. " seconds...]")
    end
    local game_formspec = table.concat(formspec, "")
    return game_formspec
end

-----------------------------------------------------------------

local update_formspec = function(player)
    local formspec = formspecs[player:get_player_name()]
    if not formspec then
        formspec = pages.main_menu
        formspecs[player:get_player_name()] = formspec
    end
    player:set_inventory_formspec(formspec)
end

local update_lobby_start = function(game)
    if not game then
        return
    end
    for _, pplayer in pairs(game.players) do
        local pname = pplayer.name
        local lobby_owner = va_lobby.player_lobbies[pname]
        formspecs[pname] = get_game_start(lobby_owner, pname, game)
        if game.start_index == 11 then
            if not pplayer.ready then
                core.show_formspec(pname, "", formspecs[pname])
            end
        end
        if game.start_index <= 0 then
            core.close_formspec(pname, "")
            formspecs[pname] = get_game_active(lobby_owner, pname, game)
        end
        local player = core.get_player_by_name(pname)
        if player then
            update_formspec(player)
        end
    end
end

local function do_lobby_start(game)
    update_lobby_start(game)

    if game.start_index > 0 then
        core.after(1, function()
            do_lobby_start(game)
        end)
    end
end

local update_lobby = function(lobby, game)
    if not lobby then
        return
    end
    if game then
        for _, pname in pairs(lobby.players) do
            if not game.players[pname] then
                local lobby_owner = va_lobby.player_lobbies[pname]
                formspecs[pname] = get_lobby(lobby_owner)
                local player = core.get_player_by_name(pname)
                if player then
                    update_formspec(player)
                end
            else
                local lobby_owner = va_lobby.player_lobbies[pname]
                formspecs[pname] = get_game_active(lobby_owner, pname, game)
                local player = core.get_player_by_name(pname)
                if player then
                    update_formspec(player)
                end
            end
        end
    else
        for _, pname in pairs(lobby.players) do
            local lobby_owner = va_lobby.player_lobbies[pname]
            formspecs[pname] = get_lobby(lobby_owner)
            local player = core.get_player_by_name(pname)
            if player then
                update_formspec(player)
            end
        end
    end
end

local update_lobby_setup = function(lobby, game)
    if not lobby or not game then
        return
    end
    for _, pname in pairs(lobby.players) do
        formspecs[pname] = get_game_setup(va_lobby.player_lobbies[pname], game)
        local player = core.get_player_by_name(pname)
        if game.setup_index == 10 then
            core.show_formspec(pname, "", formspecs[pname])
        end
        if player then
            update_formspec(player)
        end
        if game.setup_index == 0 then
            -- core.close_formspec(pname, "")
        end
    end
    if game.setup_index == 0 then
        do_lobby_start(game)
    end
end

-----------------------------------------------------------------
--- callbacks...

local function do_update_lobby(game)
    if not game then
        return
    end
    if game._disposed then
        return
    end
    if game:is_started() then
        for _, pplayer in pairs(game.players) do
            local pname = pplayer.name
            local lobby_owner = va_lobby.player_lobbies[pname]
            formspecs[pname] = get_game_active(lobby_owner, pname, game)
            local player = core.get_player_by_name(pname)
            if player then
                update_formspec(player)
            end
            if game.dispose_tick == 1 then
                core.show_formspec(pname, "", formspecs[pname])
            end
        end
    end
end

local function do_dipose_game(game)
    if not game then
        return
    end
    for _, pplayer in pairs(game.players) do
        local pname = pplayer.name
        local lobby_owner = va_lobby.player_lobbies[pname]
        local lobby = va_lobby.lobbies[lobby_owner]
        if lobby then
            lobby.players_ready[pname] = false
            lobby.running = false
        end
        formspecs[pname] = get_lobby(lobby_owner)
        local player = core.get_player_by_name(pname)
        if player then
            update_formspec(player)
        end
    end
end

-----------------------------------------------------------------

local function split(str)
    local result = {}
    for word in string.gmatch(str, "%S+") do
        table.insert(result, word)
    end
    return result
end

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "" then
        return
    end
    local pname = player:get_player_name()
    if fields.join then
        formspecs[pname] = get_lobbies()
        update_formspec(player)
    elseif fields.host then
        local lobby = va_lobby.lobbies[pname]
        if lobby then
            -- Already hosting a lobby
            return
        end
        formspecs[pname] = get_lobby_setup(pname, 1)
        update_formspec(player)
    elseif fields.cancel then
        formspecs[pname] = pages.main_menu
        update_formspec(player)
    elseif fields.save then
        local lobby_name = fields.game_name
        if lobby_name == "" then
            lobby_name = pname .. "'s Lobby"
        end
        local password = fields.password
        local mode = tonumber(fields.mode or "1")
        local wd_difficulty = fields.wd_difficulty or "Easy"
        local b_size = tonumber(fields.game_board_size or "1")
        local size = nil
        if b_size == 1 then
            size = {
                width = 256,
                height = 128,
                depth = 256
            }
        elseif b_size == 2 then
            size = {
                width = 384,
                height = 128,
                depth = 384
            }
        elseif b_size == 3 then
            size = {
                width = 512,
                height = 128,
                depth = 512
            }
        elseif b_size == 4 then
            size = {
                width = 640,
                height = 128,
                depth = 640
            }
        elseif b_size == 5 then
            size = {
                width = 768,
                height = 128,
                depth = 768
            }
        elseif b_size == 6 then
            size = {
                width = 896,
                height = 128,
                depth = 896
            }
        elseif b_size == 7 then
            size = {
                width = 1024,
                height = 128,
                depth = 1024
            }
        end
        local s_pos = split(fields.game_position or "0 0 0")
        local pos = vector.new(tonumber(s_pos[1] or "0"), tonumber(s_pos[2] or "0"), tonumber(s_pos[3] or "0"))

        local teams = {
            [1] = {
                [pname] = true
            }
        }
        if mode == 2 or mode == "2" then
            teams[2] = {}
        elseif mode == 4 or mode == "4" then
            teams[2] = {}
        end
        va_lobby.lobbies[pname] = {
            name = lobby_name,
            password = password,
            mode = mode,
            wd_difficulty = wd_difficulty,
            teams = teams,
            players_max = 8,
            players = {pname},
            players_ready = {},
            players_factions = {},
            spectators = {},
            bosses = {
                [pname] = true
            },
            game_position = pos,
            board_size = size,
            update_lobby = do_update_lobby,
            dipose_game = do_dipose_game
        }
        va_lobby.player_lobbies[pname] = pname
        formspecs[pname] = get_lobby(pname)
        update_formspec(player)
    elseif fields.start then
        local lobby = va_lobby.lobbies[va_lobby.player_lobbies[pname]]

        local is_ready = true
        for _, p in pairs(lobby.players) do
            if not lobby.players_ready[p] then
                is_ready = false
                break
            end
        end

        if not is_ready then
            core.chat_send_player(pname, "Not all players in lobby are ready!")
        elseif lobby.running then
            core.chat_send_player(pname, "The game for this lobby is already running!")
        else
            local game = va_game.init_game_from_lobby(lobby)
            if game then
                if not game:is_started() then
                    lobby.running = true
                    local function do_update_check()
                        update_lobby_setup(lobby, game)
                        if game.setup_index <= 0 then
                            return
                        end
                        if game.setup_index >= 0 then
                            core.after(1, function()
                                do_update_check()
                            end)
                        end
                    end
                    do_update_check()
                end
            end
        end

    elseif fields.leave or fields.quit_game then
        local lobby_owner = va_lobby.player_lobbies[pname]
        local lobby = va_lobby.lobbies[lobby_owner]
        if lobby then
            for i, player_name in ipairs(lobby.players) do
                if player_name == pname then
                    table.remove(lobby.players, i)
                    break
                end
            end
            for i, spectator_name in ipairs(lobby.spectators) do
                if spectator_name == pname then
                    table.remove(lobby.spectators, i)
                    break
                end
            end
            for i, boss_name in ipairs(lobby.bosses) do
                if boss_name == pname then
                    table.remove(lobby.bosses, i)
                    break
                end
            end
            for t_id, t_players in pairs(lobby.teams) do
                for t_player, _ in pairs(t_players) do
                    if t_player == pname then
                        lobby.teams[t_id][pname] = nil
                    end
                end
            end
            if #lobby.bosses == 0 and (#lobby.players > 0 or #lobby.spectators > 0) then
                -- If no bosses left, disband lobby
            end
            if #lobby.players == 0 and #lobby.spectators == 0 then
                va_lobby.lobbies[va_lobby.player_lobbies[pname]] = nil
            end
            va_lobby.player_lobbies[pname] = nil
            formspecs[pname] = pages.main_menu
            local game = va_game.get_game_from_lobby(lobby.name)
            if lobby_owner == pname then
                for _, lpname in pairs(lobby.players) do
                    va_lobby.player_lobbies[lpname] = nil
                    formspecs[lpname] = pages.main_menu
                    local plyer = core.get_player_by_name(lpname)
                    if plyer then
                        update_formspec(plyer)
                    end
                end
                lobby.players = {}
                va_lobby.lobbies[pname] = nil
                if game then
                    game:send_all_player_msg("Host has disbanded the lobby.")
                else
                    core.chat_send_player(pname, "Lobby disbanded.")
                end
            else
                update_lobby(lobby, game)
            end
            update_formspec(player)
            if fields.quit_game then
                if game then
                    game:remove_player(pname)
                    game:send_all_player_msg("Player " .. pname .. " has left the match.")
                end
            end
        end
    elseif fields.vote_stop then
        local lobby = va_lobby.lobbies[va_lobby.player_lobbies[pname]]
        if lobby then
            local game = va_game.get_game_from_lobby(lobby.name)
            if game and not game:is_stopped() and not game:is_ended() then
                if not game.votes_stop[pname] then
                    game.votes_stop[pname] = true
                    formspecs[pname] = get_game_active(va_lobby.player_lobbies[pname], pname, game)
                    update_formspec(player)
                    do_update_lobby(game)
                end
            end
        end
    elseif fields.mode then
        local mode_id = tonumber(fields.mode)
        formspecs[pname] = get_lobby_setup(pname, mode_id)
        update_formspec(player)
    else
        for lobby_owner, lobby in pairs(va_lobby.lobbies) do
            if fields["join_" .. lobby_owner] then
                local lobby_password = lobby.password
                if lobby_password and lobby_password ~= "" then
                    -- For now, no password handling
                end
                local found = false
                for key, value in pairs(lobby.players) do
                    if value == pname then
                        found = true
                    end
                end
                if not found then
                    if #lobby.players >= lobby.players_max + 1 then
                        core.chat_send_player(pname, "The game is full.")
                        return
                    end
                    table.insert(lobby.players, pname)
                end
                va_lobby.player_lobbies[pname] = lobby_owner
                -- formspecs[pname] = get_lobby(lobby_owner)
                -- update_formspec(player)
                local team_count = 0
                for t_id, _ in pairs(lobby.teams) do
                    team_count = team_count + 1
                end
                local max = lobby.players_max or 8
                if team_count == 2 then
                    max = 4
                elseif team_count == 3 then
                    max = 3
                elseif team_count == 4 then
                    max = 2
                end
                local do_update = false
                for i = 1, team_count + 1, 1 do
                    local team_player_count = 0
                    for _, p in pairs(lobby.teams[i]) do
                        if p then
                            team_player_count = team_player_count + 1
                        end
                    end
                    if team_player_count < max then
                        lobby.teams[i][pname] = true
                        break
                    end
                end
                local game = nil
                if do_update then
                    game = va_game.get_game_from_lobby(lobby.name)
                end
                update_lobby(lobby, game)
            elseif fields["ready_" .. pname] then
                lobby.players_ready[pname] = fields["ready_" .. pname] == "true"
                local game = va_game.get_game_from_lobby(lobby.name)
                update_lobby(lobby, game)
            elseif fields["ready_start_" .. pname] then
                local game = va_game.get_game_from_lobby(lobby.name)
                if game then
                    if not game.started then
                        if game.players[pname] and game.players[pname].placed == true then
                            game.players[pname].ready = fields["ready_start_" .. pname] == "true"
                            formspecs[pname] = get_game_start(lobby_owner, pname, game)
                            update_formspec(player)
                        end
                    end
                end
            elseif fields["team_count_" .. lobby_owner] and lobby_owner == pname then
                local i = 0
                local c_index = tonumber(fields["team_count_" .. lobby_owner]) + 1
                local new_teams = {}
                if c_index >= 2 then
                    new_teams[1] = {}
                    new_teams[2] = {}
                end
                if c_index >= 3 then
                    new_teams[3] = {}
                end
                if c_index >= 4 then
                    new_teams[4] = {}
                end
                for t_id, t_players in pairs(lobby.teams) do
                    i = i + 1
                    for t_player, v in pairs(t_players) do
                        if i <= c_index then
                            if not new_teams[t_id] then
                                new_teams[t_id] = {}
                            end
                            new_teams[t_id][t_player] = true
                        else
                            new_teams[1][t_player] = true
                        end
                    end
                end
                if c_index > 1 and c_index > #new_teams then
                    for j = i, c_index, 1 do
                        new_teams[j] = {}
                    end
                end
                lobby.teams = new_teams
                local game = va_game.get_game_from_lobby(lobby.name)
                update_lobby(lobby, game)
            end
            -- check for join team
            local joined_team = false
            local team_id = 1
            local team_count = 0
            for t_id, _ in pairs(lobby.teams) do
                team_count = team_count + 1
                if fields["team_join_" .. lobby_owner .. "_" .. t_id] then
                    joined_team = true
                    team_id = t_id
                end
            end
            if joined_team then
                local max = lobby.players_max or 8
                if team_count == 2 then
                    max = 5
                elseif team_count == 3 then
                    max = 4
                elseif team_count == 4 then
                    max = 3
                end
                local team_player_count = 0
                for _, p in pairs(lobby.teams[team_id]) do
                    if p then
                        team_player_count = team_player_count + 1
                    end
                end
                if team_player_count >= max then
                    core.chat_send_player(pname, "The team is full.")
                    return
                end
                for t_id, t_players in pairs(lobby.teams) do
                    for t_player, _ in pairs(t_players) do
                        if t_player == pname then
                            lobby.teams[t_id][pname] = nil
                        end
                    end
                end
                for t_id, _ in pairs(lobby.teams) do
                    if fields["team_join_" .. lobby_owner .. "_" .. t_id] then
                        lobby.teams[t_id][pname] = true
                        break
                    end
                end
                local game = va_game.get_game_from_lobby(lobby.name)
                update_lobby(lobby, game)
            end
        end
    end
end)

-----------------------------------------------------------------
-----------------------------------------------------------------

core.register_on_joinplayer(function(player)
    update_formspec(player)
    player:hud_set_flags({
        healthbar = false,
        breathbar = false,
        crosshair = true,
        wielditem = false,
        hotbar = false,
        minimap = false,
        minimap_radar = false
    })
    player:hud_set_hotbar_itemcount(0)
    local inv = player:get_inventory()
    local inv_name = "main"
    inv:set_list(inv_name, {})
    player:set_observers({
        [player:get_player_name()] = true
    })
    player:hud_set_hotbar_selected_image("va_hud_hotbar_selected.png")
    -- va_hud.update_hud(player)
end)

core.register_on_leaveplayer(function(player, timed_out)
    local pname = player:get_player_name()
    local lobby = va_lobby.lobbies[pname]
    if lobby then
        for i, player_name in ipairs(lobby.players) do
            if player_name == pname then
                table.remove(lobby.players, i)
                va_lobby.player_lobbies[pname] = nil
                formspecs[pname] = pages.main_menu
                update_formspec(player)
                break
            end
        end
        for i, spectator_name in ipairs(lobby.spectators) do
            if spectator_name == pname then
                table.remove(lobby.spectators, i)
                va_lobby.player_lobbies[pname] = nil
                formspecs[pname] = pages.main_menu
                update_formspec(player)
                break
            end
        end
        for i, boss_name in ipairs(lobby.bosses) do
            if boss_name == pname then
                table.remove(lobby.bosses, i)
                va_lobby.player_lobbies[pname] = nil
                formspecs[pname] = pages.main_menu
                update_formspec(player)
                break
            end
        end
        if #lobby.bosses == 0 and (#lobby.players > 0 or #lobby.spectators > 0) then
            -- If no bosses left, disband lobby
        end
        if #lobby.players == 0 and #lobby.spectators == 0 then
            va_lobby.lobbies[pname] = nil
        end
    end
    va_lobby.player_lobbies[pname] = nil
    formspecs[pname] = nil
    update_formspec(player)
end)
