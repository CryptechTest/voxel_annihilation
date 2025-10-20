dofile(core.get_modpath("physics_api") .. "/api.lua")

--[[]
core.register_on_joinplayer(function(player)
	player:set_physics_override({
        jump = 0.0,
        speed = 0.0,
    })
end)
--]] 