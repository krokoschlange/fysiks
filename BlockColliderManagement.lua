fysiks.blockcolliders = {}
fysiks.updatedBlockColliders = {}
fysiks.nodeDefinitions = {}

fysiks.BLOCKSIZE = 4

function fysiks.getBlockPos(pos)
	return {
		x = math.floor(pos.x / fysiks.BLOCKSIZE),
		y = math.floor(pos.y / fysiks.BLOCKSIZE),
		z = math.floor(pos.z / fysiks.BLOCKSIZE)
	}
end

function fysiks.handleUpdatedBlockColliders()
	local j, n = 1, #fysiks.updatedBlockColliders
	for i = 1, n, 1 do
		local elem = fysiks.updatedBlockColliders[i]
		if elem.body.sleepTimer <= fysiks.SLEEP_TIME then
			elem.body.sleepTimer = elem.body.sleepTimer + 1
			if i ~= j then
				fysiks.updatedBlockColliders[j] = elem
				fysiks.updatedBlockColliders[i] = nil
			end
			j = j + 1
		else
			fysiks.updatedBlockColliders[i] = nil
		end
	end
end

function fysiks.updateBlockCollider(pos, create)
	if not fysiks.blockcolliders[pos.x] then
		fysiks.blockcolliders[pos.x] = {}
	end
	if not fysiks.blockcolliders[pos.x][pos.y] then
		fysiks.blockcolliders[pos.x][pos.y] = {}
	end
	if not fysiks.blockcolliders[pos.x][pos.y][pos.z] and create then
		fysiks.blockcolliders[pos.x][pos.y][pos.z] = fysiks.BlockCollider:new(pos)
	end
	local coll = fysiks.blockcolliders[pos.x][pos.y][pos.z]
	if coll then
		coll:calculateNodePositions()
		coll:recalculate()
	end
end

function fysiks.getBlockCollider(pos)
	local blockpos = fysiks.getBlockPos(pos)
	if not fysiks.blockcolliders[blockpos.x] or
			not fysiks.blockcolliders[blockpos.x][blockpos.y] or
			not fysiks.blockcolliders[blockpos.x][blockpos.y][blockpos.z] then
		fysiks.updateBlockCollider(blockpos, true)
	end
	return fysiks.blockcolliders[blockpos.x][blockpos.y][blockpos.z]
end

function fysiks.getBlockColliders(min, max)
	local blockmin = fysiks.getBlockPos(min)
	local blockmax = fysiks.getBlockPos(max)
	local colls = {}
	for x = blockmin.x, blockmax.x, 1 do
		for y = blockmin.y, blockmax.y, 1 do
			for z = blockmin.z, blockmax.z, 1 do
				if not fysiks.blockcolliders[x] or not fysiks.blockcolliders[x][y] or not fysiks.blockcolliders[x][y][z] then
					fysiks.updateBlockCollider({x = x, y = y, z = z}, true)
				end
				for _, coll in ipairs(fysiks.blockcolliders[x][y][z].colliders) do
					table.insert(colls, coll)
				end
			end
		end
	end
	return colls
end

function fysiks.register_node_properties(name, def)
	fysiks.nodeDefinitions[name] = def
end
