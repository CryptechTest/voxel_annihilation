dofile(core.get_modpath("player_api") .. "/api.lua")

-- Default player appearance



-- Update appearance when the player joins
core.register_on_joinplayer(function(player)
	player_api.set_model(player, "none")
end)
