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

    if vas_run_tick == 3 then
        va_hud.tick_player_huds()
    end

    vas_run_tick = vas_run_tick + 1
    if vas_run_tick >= vas_run_tick_max then
        vas_run_tick = 0
    end

end)

core.register_lbm({
    label = "Cleanup Board Barriers",
    name = "va_game:game_board_cleanup",
    nodenames = {"va_game:board_barrier", "barrier:barrier", "bedrock2:bedrock"},
    run_at_every_load = true,
    action = function(pos, node, dtime_s) 

        local meta = core.get_meta(pos)

        local game_id = meta:get_int("game_id")
        if game_id == nil then return end

        local prior_def = core.deserialize(meta:get_string("prior_def"))
        if prior_def == nil then return end

        local game = va_game.get_game(game_id)

        if game == nil then
            core.set_node(pos, prior_def)
        end
    
    end,
})