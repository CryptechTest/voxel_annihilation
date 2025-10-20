--
-- Sounds
--

function default.node_sound_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "", gain = 1.0}
	tbl.dug = tbl.dug or
			{name = "default_dug_node", gain = 0.25}
	tbl.place = tbl.place or
			{name = "default_place_node_hard", gain = 1.0}
	return tbl
end

function default.node_sound_stone_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_hard_footstep", gain = 0.2}
	tbl.dug = tbl.dug or
			{name = "default_hard_footstep", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_dirt_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_dirt_footstep", gain = 0.25}
	tbl.dig = tbl.dig or
			{name = "default_dig_crumbly", gain = 0.4}
	tbl.dug = tbl.dug or
			{name = "default_dirt_footstep", gain = 1.0}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_sand_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_sand_footstep", gain = 0.05}
	tbl.dug = tbl.dug or
			{name = "default_sand_footstep", gain = 0.15}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_gravel_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_gravel_footstep", gain = 0.25}
	tbl.dig = tbl.dig or
			{name = "default_gravel_dig", gain = 0.35}
	tbl.dug = tbl.dug or
			{name = "default_gravel_dug", gain = 1.0}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_wood_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_wood_footstep", gain = 0.15}
	tbl.dig = tbl.dig or
			{name = "default_dig_choppy", gain = 0.4}
	tbl.dug = tbl.dug or
			{name = "default_wood_footstep", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_leaves_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_grass_footstep", gain = 0.45}
	tbl.dug = tbl.dug or
			{name = "default_grass_footstep", gain = 0.7}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_ice_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_ice_footstep", gain = 0.15}
	tbl.dig = tbl.dig or
			{name = "default_ice_dig", gain = 0.5}
	tbl.dug = tbl.dug or
			{name = "default_ice_dug", gain = 0.5}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_metal_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_metal_footstep", gain = 0.2}
	tbl.dig = tbl.dig or
			{name = "default_dig_metal", gain = 0.5}
	tbl.dug = tbl.dug or
			{name = "default_dug_metal", gain = 0.5}
	tbl.place = tbl.place or
			{name = "default_place_node_metal", gain = 0.5}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_water_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_water_footstep", gain = 0.2}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_snow_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_snow_footstep", gain = 0.2}
	tbl.dig = tbl.dig or
			{name = "default_snow_footstep", gain = 0.3}
	tbl.dug = tbl.dug or
			{name = "default_snow_footstep", gain = 0.3}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end


--
-- Lavacooling
--

default.cool_lava = function(pos, node)
	if node.name == "default:lava_source" then
		core.set_node(pos, {name = "default:obsidian"})
	else -- Lava flowing
		core.set_node(pos, {name = "default:stone"})
	end
	core.sound_play("default_cool_lava",
		{pos = pos, max_hear_distance = 16, gain = 0.2}, true)
end

if core.settings:get_bool("enable_lavacooling") ~= false then
	core.register_abm({
		label = "Lava cooling",
		nodenames = {"default:lava_source", "default:lava_flowing"},
		neighbors = {"group:cools_lava", "group:water"},
		interval = 2,
		chance = 2,
		catch_up = false,
		action = function(...)
			default.cool_lava(...)
		end,
	})
end


--
-- Optimized helper to put all items in an inventory into a drops list
--

function default.get_inventory_drops(pos, inventory, drops)
	local inv = core.get_meta(pos):get_inventory()
	local n = #drops
	for i = 1, inv:get_size(inventory) do
		local stack = inv:get_stack(inventory, i)
		if stack:get_count() > 0 then
			drops[n+1] = stack:to_table()
			n = n + 1
		end
	end
end


--
-- Papyrus and cactus growing
--

-- Wrapping the functions in ABM action is necessary to make overriding them possible

function default.grow_cactus(pos, node)
	if node.param2 >= 4 then
		return
	end
	pos.y = pos.y - 1
	if core.get_item_group(core.get_node(pos).name, "sand") == 0 then
		return
	end
	pos.y = pos.y + 1
	local height = 0
	while node.name == "default:cactus" and height < 4 do
		height = height + 1
		pos.y = pos.y + 1
		node = core.get_node(pos)
	end
	if height == 4 or node.name ~= "air" then
		return
	end
	if core.get_node_light(pos) < 13 then
		return
	end
	core.set_node(pos, {name = "default:cactus"})
	return true
end

function default.grow_papyrus(pos, node)
	pos.y = pos.y - 1
	local name = core.get_node(pos).name
	if name ~= "default:dirt" and
			name ~= "default:dirt_with_grass" and
			name ~= "default:dirt_with_dry_grass" and
			name ~= "default:dirt_with_rainforest_litter" and
			name ~= "default:dry_dirt" and
			name ~= "default:dry_dirt_with_dry_grass" then
		return
	end
	if not core.find_node_near(pos, 3, {"group:water"}) then
		return
	end
	pos.y = pos.y + 1
	local height = 0
	while node.name == "default:papyrus" and height < 4 do
		height = height + 1
		pos.y = pos.y + 1
		node = core.get_node(pos)
	end
	if height == 4 or node.name ~= "air" then
		return
	end
	if core.get_node_light(pos) < 13 then
		return
	end
	core.set_node(pos, {name = "default:papyrus"})
	return true
end

core.register_abm({
	label = "Grow cactus",
	nodenames = {"default:cactus"},
	neighbors = {"group:sand"},
	interval = 12,
	chance = 83,
	action = function(...)
		default.grow_cactus(...)
	end
})

core.register_abm({
	label = "Grow papyrus",
	nodenames = {"default:papyrus"},
	-- Grows on the dirt and surface dirt nodes of the biomes papyrus appears in,
	-- including the old savanna nodes.
	-- 'default:dirt_with_grass' is here only because it was allowed before.
	neighbors = {
		"default:dirt",
		"default:dirt_with_grass",
		"default:dirt_with_dry_grass",
		"default:dirt_with_rainforest_litter",
		"default:dry_dirt",
		"default:dry_dirt_with_dry_grass",
	},
	interval = 14,
	chance = 71,
	action = function(...)
		default.grow_papyrus(...)
	end
})


--
-- Dig upwards
--

local in_dig_up = false

function default.dig_up(pos, node, digger, max_height)
	if in_dig_up then return end -- Do not recurse
	if digger == nil then return end
	max_height = max_height or 100

	in_dig_up = true
	for y = 1, max_height do
		local up_pos  = vector.offset(pos, 0, y, 0)
		local up_node = core.get_node(up_pos)
		if up_node.name ~= node.name then
			break
		end
		if not core.node_dig(up_pos, up_node, digger) then
			break
		end
	end
	in_dig_up = false
end

-- errors are hard to handle, instead we rely on resetting this value the next step
core.register_globalstep(function()
	in_dig_up = false
end)


--
-- Leafdecay
--

-- Prevent decay of placed leaves

default.after_place_leaves = function(pos, placer, itemstack, pointed_thing)
	if placer and placer:is_player() then
		local node = core.get_node(pos)
		node.param2 = 1
		core.set_node(pos, node)
	end
end

-- Leafdecay
local function leafdecay_after_destruct(pos, oldnode, def)
	for _, v in pairs(core.find_nodes_in_area(vector.subtract(pos, def.radius),
			vector.add(pos, def.radius), def.leaves)) do
		local node = core.get_node(v)
		local timer = core.get_node_timer(v)
		if node.param2 ~= 1 and not timer:is_started() then
			timer:start(math.random(20, 120) / 10)
		end
	end
end

local movement_gravity = tonumber(
	core.settings:get("movement_gravity")) or 9.81

local function leafdecay_on_timer(pos, def)
	if core.find_node_near(pos, def.radius, def.trunks) then
		return false
	end

	local node = core.get_node(pos)
	local drops = core.get_node_drops(node.name)
	for _, item in ipairs(drops) do
		local is_leaf
		for _, v in pairs(def.leaves) do
			if v == item then
				is_leaf = true
			end
		end
		if core.get_item_group(item, "leafdecay_drop") ~= 0 or
				not is_leaf then
			core.add_item({
				x = pos.x - 0.5 + math.random(),
				y = pos.y - 0.5 + math.random(),
				z = pos.z - 0.5 + math.random(),
			}, item)
		end
	end

	core.remove_node(pos)
	core.check_for_falling(pos)

	-- spawn a few particles for the removed node
	core.add_particlespawner({
		amount = 8,
		time = 0.001,
		minpos = vector.subtract(pos, {x=0.5, y=0.5, z=0.5}),
		maxpos = vector.add(pos, {x=0.5, y=0.5, z=0.5}),
		minvel = vector.new(-0.5, -1, -0.5),
		maxvel = vector.new(0.5, 0, 0.5),
		minacc = vector.new(0, -movement_gravity, 0),
		maxacc = vector.new(0, -movement_gravity, 0),
		minsize = 0,
		maxsize = 0,
		node = node,
	})
end

function default.register_leafdecay(def)
	assert(def.leaves)
	assert(def.trunks)
	assert(def.radius)
	for _, v in pairs(def.trunks) do
		core.override_item(v, {
			after_destruct = function(pos, oldnode)
				leafdecay_after_destruct(pos, oldnode, def)
			end,
		})
	end
	for _, v in pairs(def.leaves) do
		core.override_item(v, {
			on_timer = function(pos)
				leafdecay_on_timer(pos, def)
			end,
		})
	end
end


--
-- Convert default:dirt to something that fits the environment
--

core.register_abm({
	label = "Grass spread",
	nodenames = {"default:dirt"},
	neighbors = {
		"air",
		"group:grass",
		"group:dry_grass"
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
			core.set_node(pos, {name = n3.name})
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


--
-- Grass and dry grass removed in darkness
--

core.register_abm({
	label = "Grass covered",
	nodenames = {"group:spreading_dirt_type", "default:dry_dirt_with_dry_grass"},
	interval = 8,
	chance = 50,
	catch_up = false,
	action = function(pos, node)
		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		local name = core.get_node(above).name
		local nodedef = core.registered_nodes[name]
		if name ~= "ignore" and nodedef and not ((nodedef.sunlight_propagates or
				nodedef.paramtype == "light") and
				nodedef.liquidtype == "none") then
			if node.name == "default:dry_dirt_with_dry_grass" then
				core.set_node(pos, {name = "default:dry_dirt"})
			else
				core.set_node(pos, {name = "default:dirt"})
			end
		end
	end
})


--
-- Moss growth on cobble near water
--

local moss_correspondences = {
	["default:cobble"] = "default:mossycobble",
	["stairs:slab_cobble"] = "stairs:slab_mossycobble",
	["stairs:stair_cobble"] = "stairs:stair_mossycobble",
	["stairs:stair_inner_cobble"] = "stairs:stair_inner_mossycobble",
	["stairs:stair_outer_cobble"] = "stairs:stair_outer_mossycobble",
	["walls:cobble"] = "walls:mossycobble",
}
core.register_abm({
	label = "Moss growth",
	nodenames = {"default:cobble", "stairs:slab_cobble", "stairs:stair_cobble",
		"stairs:stair_inner_cobble", "stairs:stair_outer_cobble",
		"walls:cobble"},
	neighbors = {"group:water"},
	interval = 16,
	chance = 200,
	catch_up = false,
	action = function(pos, node)
		node.name = moss_correspondences[node.name]
		if node.name then
			core.set_node(pos, node)
		end
	end
})

--
-- Register a craft to copy the metadata of items
--

function default.register_craft_metadata_copy(ingredient, result)
	core.register_craft({
		type = "shapeless",
		output = result,
		recipe = {ingredient, result}
	})

	core.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
		if itemstack:get_name() ~= result then
			return
		end

		local original
		local index
		for i = 1, #old_craft_grid do
			if old_craft_grid[i]:get_name() == result then
				original = old_craft_grid[i]
				index = i
			end
		end
		if not original then
			return
		end
		local copymeta = original:get_meta():to_table()
		itemstack:get_meta():from_table(copymeta)
		-- put the book with metadata back in the craft grid
		craft_inv:set_stack("craft", index, original)
	end)
end

--
-- Log API / helpers
--

local log_non_player_actions = core.settings:get_bool("log_non_player_actions", false)

local is_pos = function(v)
	return type(v) == "table" and
		type(v.x) == "number" and type(v.y) == "number" and type(v.z) == "number"
end

function default.log_player_action(player, ...)
	local msg = player:get_player_name()
	if player.is_fake_player or not player:is_player() then
		if not log_non_player_actions then
			return
		end
		msg = msg .. "(" .. (type(player.is_fake_player) == "string"
			and player.is_fake_player or "*") .. ")"
	end
	for _, v in ipairs({...}) do
		-- translate pos
		local part = is_pos(v) and core.pos_to_string(v) or v
		-- no leading spaces before punctuation marks
		msg = msg .. (string.match(part, "^[;,.]") and "" or " ") .. part
	end
	core.log("action",  msg)
end

local nop = function() end
function default.set_inventory_action_loggers(def, name)
	local on_move = def.on_metadata_inventory_move or nop
	def.on_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count, player)
		default.log_player_action(player, "moves stuff in", name, "at", pos)
		return on_move(pos, from_list, from_index, to_list, to_index, count, player)
	end
	local on_put = def.on_metadata_inventory_put or nop
	def.on_metadata_inventory_put = function(pos, listname, index, stack, player)
		default.log_player_action(player, "moves", stack:get_name(), stack:get_count(), "to", name, "at", pos)
		return on_put(pos, listname, index, stack, player)
	end
	local on_take = def.on_metadata_inventory_take or nop
	def.on_metadata_inventory_take = function(pos, listname, index, stack, player)
		default.log_player_action(player, "takes", stack:get_name(), stack:get_count(), "from", name, "at", pos)
		return on_take(pos, listname, index, stack, player)
	end
end

--
-- NOTICE: This method is not an official part of the API yet.
-- This method may change in future.
--

function default.can_interact_with_node(player, pos)
	if player and player:is_player() then
		if core.check_player_privs(player, "protection_bypass") then
			return true
		end
	else
		return false
	end

	local meta = core.get_meta(pos)
	local owner = meta:get_string("owner")

	if not owner or owner == "" or owner == player:get_player_name() then
		return true
	end

	-- Is player wielding the right key?
	local item = player:get_wielded_item()
	if core.get_item_group(item:get_name(), "key") == 1 then
		local key_meta = item:get_meta()

		if key_meta:get_string("secret") == "" then
			local key_oldmeta = item:get_meta():get_string("")
			if key_oldmeta == "" or not core.parse_json(key_oldmeta) then
				return false
			end

			key_meta:set_string("secret", core.parse_json(key_oldmeta).secret)
			item:set_metadata("")
		end

		return meta:get_string("key_lock_secret") == key_meta:get_string("secret")
	end

	return false
end
