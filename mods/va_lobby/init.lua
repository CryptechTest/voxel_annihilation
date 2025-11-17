local path = core.get_modpath("va_lobby")

---@diagnostic disable-next-line: lowercase-global
va_lobby = {}
va_lobby.lobbies = {}
va_lobby.player_lobbies = {}

-- load menu files
dofile(path .. "/menus" .. "/lobby.lua")
-- load player actor files
dofile(path .. "/actors" .. "/players.lua")
dofile(path .. "/actors" .. "/globalstep.lua")

-- register mapgen
core.register_mapgen_script(path .. "/mapgen.lua")

-----------------------------------------------------------------

core.override_item("bedrock2:bedrock", {
    light_source = 3,
    propagates_light = true
})

-----------------------------------------------------------------

-- disable damage to player
core.register_on_player_hpchange(function(player, hp_change, reason, modifier)
    if hp_change < 0 then
        return 0
    end
    return hp_change
end, true)

-----------------------------------------------------------------

-- make player immortal
core.register_on_joinplayer(function(player, last_login)
    player:set_lighting({
        shadows = {
            intensity = 0.25
        }
    })
    player:set_armor_groups({
        immortal = 1
    })
end)
