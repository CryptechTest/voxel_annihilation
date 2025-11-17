-- the interval between run calls
local vas_run_interval = 1.0
local vas_run_tick = 0
local vas_run_tick_max = 1

-- iterate over all collected structures and execute the run function
local timer = 0
core.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < vas_run_interval then
        return
    end
    timer = 0

    -- tick actors
    va_lobby.calculate_player_actors()

    vas_run_tick = vas_run_tick + 1
    if vas_run_tick >= vas_run_tick_max then
        vas_run_tick = 0
    end

end)
