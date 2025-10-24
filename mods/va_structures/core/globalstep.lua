-- the interval between run calls
local vas_run_interval = 1.0

-- iterate over all collected structures and execute the run function
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < vas_run_interval then
        return
    end
    timer = 0

    -- tick structures
    va_structures.structures_run()

end)
