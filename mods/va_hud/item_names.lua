-- Based on 4itemnames mod by 4aiman

local item_names = {} -- [player_name] = { hud, dtime, itemname }

local function set_hud(player)
	local player_name = player:get_player_name()
	local off = {x=0, y=-65}
    off.y = off.y - 25


	item_names[player_name] = {
		hud = player:hud_add({
			type = "text",
			position = {x=0.5, y=1},
			offset = off,
			alignment = {x=0, y=-1},
			number = 0xFFFFFF,
			text = "",
			style = 1
		}),
		index = 1,
		itemname = ""
	}
end

core.register_on_joinplayer(function(player)
	core.after(0, set_hud, player)
end)

core.register_on_leaveplayer(function(player)
	item_names[player:get_player_name()] = nil
end)

core.register_globalstep(function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		local data = item_names[player:get_player_name()]
		if not data or not data.hud then
			data = {} -- Update on next step
			set_hud(player)
		end

		local index = player:get_wield_index()
		local stack = player:get_wielded_item()
		local itemname = stack:get_name()

		if data.hud and (itemname ~= data.itemname or index ~= data.index) then
			data.itemname = itemname
			data.index = index
			data.dtime = 0

			local desc = stack.get_meta
				and stack:get_meta():get_string("description")

			if not desc or desc == "" then
				-- Try to use default description when none is set in the meta
				local def = core.registered_items[itemname]
				desc = def and def.description or ""
			end
			player:hud_change(data.hud, 'text', desc)
		end
	end
end)

