fysiks.BlockCollider = {

}
fysiks.BlockCollider.__index = fysiks.BlockCollider

function fysiks.BlockCollider:new(pos)
	local c = setmetatable({}, fysiks.BlockCollider)
	c.colliders = {}
	c.nodes = {}
	c.pos = pos
	c.body = fysiks.Rigidbody:new()
	c.body.position = c:getNodePos({x = 0, y = 0, z = 0})
	c.body.static = true
	c.body.friction = 1
	c.body.sleepTimer = fysiks.SLEEP_TIME + 1
	return c
end

function fysiks.BlockCollider:getLocalPos(pos)
	return {
		x = pos.x - self.pos.x * fysiks.BLOCKSIZE,
		y = pos.y - self.pos.y * fysiks.BLOCKSIZE,
		z = pos.z - self.pos.z * fysiks.BLOCKSIZE
	}
end

function fysiks.BlockCollider:getNodePos(pos)
	return {
		x = self.pos.x * fysiks.BLOCKSIZE + pos.x,
		y = self.pos.y * fysiks.BLOCKSIZE + pos.y,
		z = self.pos.z * fysiks.BLOCKSIZE + pos.z,
	}
end

function fysiks.BlockCollider:nodeHasCollider(node)
	local nodeDef = minetest.registered_nodes[node.name]
	local drawtype = nodeDef.drawtype
	return drawtype == "normal" or drawtype == "mesh"
			or drawtype:sub(1, #"allfaces") == "allfaces"
			or drawtype:sub(1, #"glasslike") == "glasslike"
end

function fysiks.BlockCollider:calculateNodePositions()
	self.nodes = {}
	for x = 0, fysiks.BLOCKSIZE - 1, 1 do
		self.nodes[x] = {}
		for y = 0, fysiks.BLOCKSIZE - 1, 1 do
			self.nodes[x][y] = {}
			for z = 0, fysiks.BLOCKSIZE - 1, 1 do
				local pos = self:getNodePos({x = x, y = y, z = z})
				self.nodes[x][y][z] = self:nodeHasCollider(minetest.get_node(pos))
			end
		end
	end
end

function fysiks.BlockCollider:getNode(pos)
	local localpos = self:getLocalPos(pos)
	return self.nodes[localpos.x][localpos.y][localpos.z]
end

function fysiks.BlockCollider:setNode(pos)
	self.nodes[pos.x][pos.y][pos.z] = true
end

function fysiks.BlockCollider:removeNode(pos)
	self.nodes[pos.x][pos.y][pos.z] = false
end

function fysiks.BlockCollider:recalculate()
	for _, coll in ipairs(self.colliders) do
		coll.removed = true
	end

	self.colliders = {}
	local boxes = {}

	for y = 0, fysiks.BLOCKSIZE - 1, 1 do
		boxes[y] = {}
		for x = 0, fysiks.BLOCKSIZE - 1, 1 do
			local box = nil
			boxes[y][x] = {}
			for z = 0, fysiks.BLOCKSIZE - 1, 1 do
				if self.nodes[x][y][z] then
					if box then
						box.length = box.length + 1
					else
						box = {start = z, length = 1, width = 1, height = 1}
					end
				else
					if box then
						table.insert(boxes[y][x], box)
						box = nil
					end
				end
			end
			if box then
				table.insert(boxes[y][x], box)
			end
		end
	end

	for y = 0, fysiks.BLOCKSIZE - 1, 1 do
		for x = 1, fysiks.BLOCKSIZE - 1, 1 do
			for _, box in ipairs(boxes[y][x]) do
				local done = false
				for k2, box2 in ipairs(boxes[y][x - 1]) do
					if box.start == box2.start and box.length == box2.length then
						table.remove(boxes[y][x - 1], k2)
						box.width = box.width + box2.width
						done = true
						break
					end
				end
				if done then
					break
				end
			end
		end
	end

	for y = 1, fysiks.BLOCKSIZE - 1, 1 do
		for x = 0, fysiks.BLOCKSIZE - 1, 1 do
			for _, box in ipairs(boxes[y][x]) do
				local done = false
				for k2, box2 in ipairs(boxes[y - 1][x]) do
					if box.start == box2.start and box.length == box2.length and box.width == box2.width then
						table.remove(boxes[y - 1][x], k2)
						box.height = box.height + box2.height
						done = true
						break
					end
				end
				if done then
					break
				end
			end
		end
	end

	for y = 0, fysiks.BLOCKSIZE - 1, 1 do
		for x = 0, fysiks.BLOCKSIZE - 1, 1 do
			for _, box in ipairs(boxes[y][x]) do
				local min = {
					x = x - box.width + 0.5,
					y = y - box.height + 0.5,
					z = box.start - 0.5
				}
				local max = {
					x = x + 0.5,
					y = y + 0.5,
					z = box.start + box.length - 0.5
				}
				local cuboid = fysiks.Cuboid:new(self.body, min, max)
				cuboid:setPosition(self.body.position)
				table.insert(self.colliders, cuboid)
			end
		end
	end
	self.body.collisionBoxes = self.colliders
	self.body.sleepTimer = 0
	self.body.forceCollisionCheck = true
	table.insert(fysiks.updatedBlockColliders, self)
end
