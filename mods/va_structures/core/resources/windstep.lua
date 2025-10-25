-- the interval between run calls
local vas_run_interval = 2.0

local va_wind = {
    velocity = 1,
    velocity_last = 1,
    direction = {
        degree = 0
    },
    vel_change_dir = 0,
    next_change = 0,
    velocity_max = 3
}

va_structures.get_env_wind_vel = function()
    return {
        velocity = va_wind.velocity,
        direction = va_wind.direction.degree
    }
end

va_structures.set_env_wind_max = function(value)
    va_wind.velocity_max = value
end

-----------------------------------------------------------------

local function randFloat(min, max, precision)
    -- Generate a random floating point number between min and max
    local range = max - min
    local offset = range * math.random()
    local unrounded = min + offset

    -- Return unrounded number if precision isn't given
    if not precision then
        return unrounded
    end

    -- Round number to precision and return
    local powerOfTen = 10 ^ precision
    local n
    n = unrounded * powerOfTen
    n = n + 0.5
    n = math.floor(n)
    n = n / powerOfTen
    return n
end

local function do_env_wind()

    local vel = va_wind.velocity
    local vel_last = va_wind.velocity_last
    local delta = vel - vel_last
    local s = math.abs(delta) * 0.333

    local r = randFloat(-0.05, 0.05)
    local d = 0
    if va_wind.vel_change_dir == 1 then
        d = randFloat(0.01, 0.08) * 1
        d = d - s
    elseif va_wind.vel_change_dir == -1 then
        d = randFloat(0.01, 0.07) * -1
        d = d + s
    end

    local rn = math.random(0, 3)
    if rn == 1 and va_wind.next_change <= 0 then
        va_wind.vel_change_dir = -1
    elseif rn == 2 and va_wind.next_change <= 0 then
        va_wind.vel_change_dir = 0
    elseif rn == 3 and va_wind.next_change <= 0 then
        va_wind.vel_change_dir = 1
    end

    if va_wind.next_change <= 0 then
        va_wind.next_change = 3
    else
        va_wind.next_change = va_wind.next_change - 1
    end

    local dir = va_wind.direction.degree
    local new_dir = dir + (va_wind.vel_change_dir * 20)
    new_dir = new_dir % 360

    local new_vel = vel + r + d

    if new_vel <= 0 then
        new_vel = 0
    elseif new_vel > va_wind.velocity_max then
        new_vel = va_wind.velocity_max
    end

    va_wind.velocity = new_vel
    va_wind.velocity_last = vel
    va_wind.direction.degree = new_dir

    --core.log("vel= " .. va_wind.velocity .. "  dir=" .. va_wind.direction.degree)

end

-----------------------------------------------------------------

local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < vas_run_interval then
        return
    end
    timer = 0

    -- calculate wind
    do_env_wind()

end)

