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
local function get_lobby_setup(owner)
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
    dropdown[0.465,3.3;3.5;mode;Wave Defense,Assasination;1;true]
    label[4,2.9;Difficulty]
    dropdown[4,3.3;3.5;wd_difficulty;Easy,Medium,Hard,Extreme;1;true]
    field[0.75,4.6;3.5,1;game_position;Lobby Position;]] .. math.floor(pos.x) .. [[ ]] .. math.floor(pos.y) .. [[ ]] ..
        math.floor(pos.z) .. [[]
    label[4,4.025;Map Size]
    dropdown[4,4.3655;3.5;game_board_size;256,512,768,1024;1;true]
    style[cancel;bgcolor=#ff0000]
    button_exit[5.5,7.5;2,0.5;cancel;Cancel]
    style[save;bgcolor=#00ff00]
    button[0.5,7.5;2,0.5;save;Save]
    ]]}
    return table.concat(setup, "")
end

-----------------------------------------------------------------

-- get lobby by owner
local function get_lobby(owner)
    local lobby = va_lobby.lobbies[owner]
    if lobby == nil then
        return pages.main_menu
    end
    local function update_lobby_players(formspec)
        local x_min = 0.25
        local y_min = 1.0
        local x_siz = 3.5
        local y_siz = 0.5
        local x = x_min
        local y = y_min
        table.insert(formspec, "style_type[label;font_size=20;font=bold]")
        table.insert(formspec,
            "label[" .. x_min .. "," .. y_min - 0.5 .. ";Players]" .. "label[" .. (x + 2) .. "," .. y_min - 0.5 .. ";" ..
                #lobby.players .. "/" .. 8 .. "]")
        table.insert(formspec, "style_type[label;font_size=17;font=bold]")
        for _, player in pairs(lobby.players) do
            local p_box_loc = (x - 0.05) .. "," .. (y - 0.025)
            local p_box_size = x_siz .. "," .. y_siz
            local p_box = "box[" .. p_box_loc .. ";" .. p_box_size .. ";" .. "#313131" .. "]"
            table.insert(formspec, p_box)
            local p_label = "label[" .. (x + 0.05) .. "," .. y .. ";" .. player .. "]"
            table.insert(formspec, p_label)
            local ready = lobby.players_ready[player] or false
            local p_ready = "checkbox[" .. x + 2.0 .. "," .. y - 0.2 .. ";ready_" .. player .. ";Ready;" ..
                                tostring(ready) .. "]"
            table.insert(formspec, p_ready)
            x = x + x_siz + 0.3
            if x >= 7 then
                x = x_min
                y = y + y_siz + 0.2
            end
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
        table.insert(formspec, "button[0.5,7.5;2,0.5;start;Start]")
    end
    local formspec = {"size[8,8]", [[
        no_prepend[]
        formspec_version[10]
        bgcolor[#101010;]
        style_type[label;font_size=22;font=bold]
        label[0,0;]] .. lobby.name .. [[]
        style[leave;bgcolor=#ff0000]
        button_exit[5.5,7.5;2,0.5;leave;Leave]
        ]]}
    update_lobby_players(formspec)
    add_start(formspec)
    local lobby_formspec = table.concat(formspec, "")
    return lobby_formspec
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
        if lobby.mode == 1 or lobby.mode == "1" then
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
        end
        local lobby_display = ""
        if #lobby.name > 25 then
            lobby_display = string.sub(lobby.name, 1, 25)
        else
            lobby_display = lobby.name
        end
        table.insert(lobbies, "style_type[label;font_size=16;font=mono]")
        table.insert(lobbies, "label[1," .. 0.75 + (count * 0.75) .. ";" .. lobby_display .. "]")
        table.insert(lobbies, "label[5," .. 0.75 + (count * 0.75) .. ";" .. mode .. "]")
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
    -- allow_close[false]
    local formspec = {"size[4,2]", [[
        no_prepend[]
        formspec_version[10]
        bgcolor[#101010;]
        style_type[label;font_size=22;font=bold]
        label[0,0;]] .. lobby.name .. [[]
        style_type[label;font_size=19;font=bold]
        label[0.5,0.75;Initializing in... ]] .. tostring(game.setup_index) .. [[]
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
    local vote_stop_max = math.max(1, math.ceil((game:get_player_count() / 2) + 0.5))
    local formspec = {"size[8,8]", [[
        no_prepend[]
        formspec_version[10]
        bgcolor[#101010;]
        style_type[label;font_size=22;font=bold]
        label[0,0;]] .. lobby.name .. [[]
        style_type[label;font_size=16;font=normal]
        label[0.05,0.5;]] .. game_act .. [[]
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
            "label[4.25,0;Game Closes in " .. (game.dispose_tick_max - game.dispose_tick) .. " seconds..]")
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
        if game.start_index == 60 or game.setup_index == 1 then
            core.show_formspec(pname, "", formspecs[pname])
        end
        if game.start_index <= 1 then
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

local update_lobby = function(lobby)
    if not lobby then
        return
    end
    for _, pname in pairs(lobby.players) do
        formspecs[pname] = get_lobby(va_lobby.player_lobbies[pname])
        local player = core.get_player_by_name(pname)
        if player then
            update_formspec(player)
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
            core.close_formspec(pname, "")
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
        end
        formspecs[pname] = get_lobby(pname)
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
        formspecs[pname] = get_lobby_setup(pname)
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
        local mode = fields.mode or 1
        local wd_difficulty = fields.wd_difficulty or "Easy"
        local b_size = fields.board_size or 1
        local size = nil
        if b_size == 1 then
            size = {
                width = 256,
                height = 128,
                depth = 256
            }
        elseif b_size == 2 then
            size = {
                width = 512,
                height = 128,
                depth = 512
            }
        elseif b_size == 3 then
            size = {
                width = 768,
                height = 128,
                depth = 769
            }
        elseif b_size == 4 then
            size = {
                width = 1024,
                height = 128,
                depth = 1024
            }
        end
        local s_pos = split(fields.game_position or "0 0 0")
        local pos = vector.new(tonumber(s_pos[1] or "0"), tonumber(s_pos[2] or "0"), tonumber(s_pos[3] or "0"))
        va_lobby.lobbies[pname] = {
            name = lobby_name,
            password = password,
            mode = mode,
            wd_difficulty = wd_difficulty,
            teams = {},
            players = {pname},
            players_ready = {},
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
        else
            local game = va_game.init_game_from_lobby(lobby)
            if game then
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

    elseif fields.leave or fields.quit_game then
        local lobby = va_lobby.lobbies[va_lobby.player_lobbies[pname]]
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
            if #lobby.bosses == 0 and (#lobby.players > 0 or #lobby.spectators > 0) then
                -- If no bosses left, disband lobby
            end
            if #lobby.players == 0 and #lobby.spectators == 0 then
                va_lobby.lobbies[va_lobby.player_lobbies[pname]] = nil
            end
        end
        va_lobby.player_lobbies[pname] = nil
        formspecs[pname] = pages.main_menu
        update_lobby(lobby)
        update_formspec(player)
        if fields.quit_game then
            local game = va_game.get_game_from_lobby(lobby.name)
            if game then
                game:remove_player(pname)
                game:send_all_player_msg("Player " .. pname .. " has left the match.")
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
    else
        for lobby_owner, lobby in pairs(va_lobby.lobbies) do
            if fields["join_" .. lobby_owner] then
                local lobby_password = lobby.password
                if lobby_password and lobby_password ~= "" then
                    -- For now, no password handling
                end
                table.insert(lobby.players, pname)
                va_lobby.player_lobbies[pname] = lobby_owner
                -- formspecs[pname] = get_lobby(lobby_owner)
                -- update_formspec(player)
                update_lobby(lobby)
            elseif fields["ready_" .. pname] then
                lobby.players_ready[pname] = fields["ready_" .. pname] == "true"
                update_lobby(lobby)
            elseif fields["ready_start_" .. pname] then
                local game = va_game.get_game_from_lobby(lobby.name)
                if game then
                    if game.players[pname] and game.players[pname].placed == true then
                        game.players[pname].ready = fields["ready_start_" .. pname] == "true"
                        formspecs[pname] = get_game_start(lobby_owner, pname, game)
                        update_formspec(player)
                    end
                end
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
