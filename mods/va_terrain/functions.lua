--
-- Convert default:dirt to something that fits the environment
--

core.register_abm({
	label = "Grass spread",
	nodenames = {"group:family:default:dirt"},
	neighbors = {
		"air",
		"group:grass",
		"group:dry_grass",
	},
	interval = 6,
	chance = 50,
	catch_up = false,
	action = function(pos, node)
		-- Check for darkness: night, shadow or under a light-blocking node
		-- Returns if ignore above
		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		if (core.get_node_light(above) or 0) < 13 then
			return
		end

		-- Look for spreading dirt-type neighbours
		local p2 = core.find_node_near(pos, 1, "group:spreading_dirt_type")
		if p2 then
			local n3 = core.get_node(p2)
			local shape = core.get_item_group(node.name, "natural_slope")
			local all_shapes = naturalslopeslib.get_all_shapes(n3.name)
			if #all_shapes > 1 then
				core.set_node(pos, {name = all_shapes[shape + 1], param2 = node.param2})
			else
				core.set_node(pos, {name = n3.name})
			end
			return
		end

		-- Else, any seeding nodes on top?
		local name = core.get_node(above).name
		if core.get_item_group(name, "grass") ~= 0 then
			core.set_node(pos, {name = "default:dirt_with_grass"})
		elseif core.get_item_group(name, "dry_grass") ~= 0 then
			core.set_node(pos, {name = "default:dirt_with_dry_grass"})
		end
	end
})
