local region_min = {x = -4096, y = -((16 * 136) + 2) , z = -4096}
local region_max = {x = 4096, y = (16 * 136) + 1, z = 4096}

local IN_MAPGEN_ENVIRONMENT = not core.after

local c_air = core.CONTENT_AIR
local c_barrier = core.get_content_id("barrier:barrier")
local c_bedrock = core.get_content_id("bedrock2:bedrock")

local node_data = {}

local function generate_chunk(vm, minp, maxp, chunkseed)

	local emin, emax = vm:get_emerged_area()

	local area = VoxelArea(emin, emax)

	vm:get_data(node_data)

	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
				local node_index = area:index(x, y, z)

                if x < region_min.x or x > region_max.x or
                   y < region_min.y or y > region_max.y or
                   z < region_min.z or z > region_max.z then
                    node_data[node_index] = c_barrier
                elseif y == (16 * 128) then
                    node_data[node_index] = c_bedrock
                elseif y == (16 * 136) + 1 then
                    node_data[node_index] = c_barrier
                elseif y == (16 * 7) + 1 then
                    node_data[node_index] = c_barrier
                elseif y == -16 then
                    node_data[node_index] = c_bedrock
                elseif y == -17 then
                    node_data[node_index] = c_barrier
                elseif y < -17 and y > -((16 * 128) + 1) then
                    node_data[node_index] = c_air
                elseif y == -((16 * 128) + 1) then
                    node_data[node_index] = c_bedrock
                elseif y == -((16 * 136) + 2) then
                    node_data[node_index] = c_barrier
                end
			end
		end
	end

    vm:set_data(node_data)
end

core.register_on_generated(function(vm, minp, maxp, chunkseed)
	if not IN_MAPGEN_ENVIRONMENT then
		minp, maxp, chunkseed = vm, minp, maxp
	end

	if maxp.y < -(16*136) or minp.y > (16*136) then return end

	if not IN_MAPGEN_ENVIRONMENT then
		vm = core.get_mapgen_object("voxelmanip")
	end

	generate_chunk(vm, minp, maxp, chunkseed)

	--core.generate_decorations(vm)
	--core.generate_ores(vm)
	--vm:update_liquids() -- so they start flowing

	--vm:set_lighting({day = 0, night = 0})
	--vm:calc_lighting() -- necessary after placing glowing nodes

	if not IN_MAPGEN_ENVIRONMENT then
		vm:write_to_map()
	end

end)
