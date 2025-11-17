local path = core.get_modpath("va_game")

---@diagnostic disable-next-line: lowercase-global
va_game = {}
va_game.games = {}

-- load files
dofile(path .. "/src" .. "/game_manager.lua")
dofile(path .. "/src" .. "/game_marker.lua")
dofile(path .. "/src" .. "/globalstep.lua")

-- load player actor files
dofile(path .. "/src/actors" .. "/players.lua")
dofile(path .. "/src/actors" .. "/globalstep.lua")