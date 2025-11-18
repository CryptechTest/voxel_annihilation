-- the interval between run calls
local vas_run_interval = 0.25
local vas_run_tick = 0
local vas_run_tick_max = 4

local timer = 0
core.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < vas_run_interval then
        return
    end
    timer = 0

    -- tick games
    va_game.tick_all(vas_run_tick)

    if vas_run_tick == 0 then
        va_game.calculate_player_actors()
    end

    va_structures.structures_run(vas_run_tick)

    if vas_run_tick == 0 then
        va_hud.tick_player_huds()
    end

    vas_run_tick = vas_run_tick + 1
    if vas_run_tick >= vas_run_tick_max then
        vas_run_tick = 0
    end

end)
