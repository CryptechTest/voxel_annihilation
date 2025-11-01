va_lobby = {}
local formspecs = {}

va_lobby.lobbies = {}
va_lobby.player_lobbies = {}

local pages = {}
pages.main_menu = nil


local tmp = {
    "size[8,3]",
    [[
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
    ]]
}

pages.main_menu = table.concat(tmp, "")



local function get_lobby_setup(owner)
    local pos = core.get_player_by_name(owner):get_pos()
    local setup = {
    "size[8,8]",
    [[
    no_prepend[]
    formspec_version[10]
    bgcolor[#101010;]
    style_type[label;font_size=22;font=bold]
    label[0,0;Setup Lobby]
    field[0.75,1.3;7,1;game_name;Lobby Name;]
    pwdfield[0.75,2.4;7,1;password;Password (optional)]
    style[cancel;bgcolor=#ff0000]
    style[save;bgcolor=#00ff00]
    style_type[label;font_size=16;font=bold]
    label[0.5,2.9;Mode]
    dropdown[0.5,3.3;3.5;mode;Wave Defense;1;true]
    label[4,2.9;Difficulty]
    dropdown[4,3.3;3.5;wd_difficulty;Easy,Medium,Hard,Extreme;1;true]
    field[0.75,4.6;3.5,1;game_position;Lobby Position;]] .. math.floor(pos.x) .. [[ ]] .. math.floor(pos.y) .. [[ ]] .. math.floor(pos.z) .. [[]
    button_exit[5.5,7.5;2,0.5;cancel;Cancel]
    button[0.5,7.5;2,0.5;save;Save]
    ]]
}

    return table.concat(setup, "")
end


local function get_lobby(owner)
    local lobby = va_lobby.lobbies[owner]
    if lobby == nil then
        return pages.main_menu
    end
    local formspec = {
        "size[8,8]",
        [[
        no_prepend[]
        formspec_version[10]
        bgcolor[#101010;]
        style_type[label;font_size=22;font=bold]
        label[0,0;]] .. lobby.name .. [[]
        style[leave;bgcolor=#ff0000]
        button_exit[5.5,7.5;2,0.5;leave;Leave]
        ]]
    }
    local lobby_formspec = table.concat(formspec, "")
    return lobby_formspec
end

local function get_lobbies()
    local lobbies = {
        "size[8,8]",
        [[
    no_prepend[]
    formspec_version[10]
    bgcolor[#101010;]
    style_type[label;font_size=22;font=bold]
    label[0,0;Lobbies]
    style[cancel;bgcolor=#ff0000]
    button_exit[5.5,7.5;2,0.5;cancel;Cancel]
    ]]
    }
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
            "button[0," ..
            0.75 + (count * 0.75) .. ";1,0.5;join_" .. pname .. ";" .. (lobby.password ~= "" and "Join" or "Join") .. "]")
        count = count + 1
    end
    return table.concat(lobbies, "")
end




local update_formspec = function(player)
    local formspec = formspecs[player:get_player_name()]
    if not formspec then
        formspec = pages.main_menu
        formspecs[player:get_player_name()] = formspec
    end
    player:set_inventory_formspec(formspec)
end

core.register_on_joinplayer(function(player)
    update_formspec(player)
    player:hud_set_flags({
        healthbar = false,
        breathbar = false,
        crosshair = true,
        wielditem = false,
        hotbar = true,
        minimap = false,
        minimap_radar = false,
    })
    player:set_observers({[player:get_player_name()] = true})
    --va_hud.update_hud(player)
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
        va_lobby.lobbies[pname] = {
            name = lobby_name,
            password = password,
            mode = mode,
            wd_difficulty = wd_difficulty,
            players = { pname },
            spectators = {},
            bosses = { [pname] = true },
        }
        va_lobby.player_lobbies[pname] = pname
        formspecs[pname] = get_lobby(pname)
        update_formspec(player)
    elseif fields.leave then
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
        update_formspec(player)
    else
        for lobby_owner, lobby in pairs(va_lobby.lobbies) do
            if fields["join_" .. lobby_owner] then
                local lobby_password = lobby.password
                if lobby_password and lobby_password ~= "" then
                    -- For now, no password handling
                end
                table.insert(lobby.players, pname)
                va_lobby.player_lobbies[pname] = lobby_owner
                formspecs[pname] = get_lobby(lobby_owner)
                update_formspec(player)
            end
        end
    end
end)




core.register_on_player_hpchange(function(player, hp_change, reason, modifier)
    if hp_change < 0 then
        return 0
    end
    return hp_change
end, true)

local region_min = {x = -4608, y = -30912 , z = -4608}
local region_max = {x = 4608, y = 30927, z = 4608}

minetest.register_on_generated(function(minp, maxp, seed)
    for x = minp.x, maxp.x do
        for y = minp.y, maxp.y do
            for z = minp.z, maxp.z do
                if x < region_min.x or x > region_max.x or
                   y < region_min.y or y > region_max.y or
                   z < region_min.z or z > region_max.z then
                    core.set_node({x=x, y=y, z=z}, {name="barrier:barrier"})
                end
            end
        end
    end


end)