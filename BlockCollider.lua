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

function fysiks.BlockCollider:extractNodeboxCollider(nodebox)
	local boxes = {}
	if nodebox.type == "regular" then
		boxes = {{{x = -0.5, y = -0.5, z = -0.5}, {x = 0.5, y = 0.5, z = 0.5}}}
	elseif nodebox.type == "fixed" or nodebox.type == "leveled"
			or nodebox.type == "connected" then
		if nodebox.fixed and #nodebox.fixed > 0 then
			if type(nodebox.fixed[1]) == "number" then
				local box = nodebox.fixed
				table.insert(boxes, {{x = box[1], y = box[2], z = box[3]}, {x = box[4], y = box[5], z = box[6]}})
			else
				for k, box in ipairs(nodebox.fixed) do
					table.insert(boxes, {{x = box[1], y = box[2], z = box[3]}, {x = box[4], y = box[5], z = box[6]}})
				end
			end
		end
		--TODO: figure out the leveled nodebox
		--TODO: figure out the connections of the node to be more accurate
		if nodebox.type == "connected" and nodebox.disconnected and #nodebox.disconnected > 0 then
			if type(nodebox.disconnected[1]) == "number" then
				local box = nodebox.disconnected
				table.insert(boxes, {{x = box[1], y = box[2], z = box[3]}, {x = box[4], y = box[5], z = box[6]}})
			else
				for k, box in ipairs(nodebox.disconnected) do
					table.insert(boxes, {{x = box[1], y = box[2], z = box[3]}, {x = box[4], y = box[5], z = box[6]}})
				end
			end
		end
	elseif nodebox.type == "wallmounted" then
		--TODO: figure out wallmounted nodebox
	end
	return boxes
end

function fysiks.BlockCollider:getNodeColliderInfo(node)
	local nodeDef = minetest.registered_nodes[node.name]
	local drawtype = nodeDef.drawtype
	local collisionbox = nodeDef.collision_box
	local boxtype = nil
	if collisionbox then
		boxtype = {type = "nodebox", boxes = self:extractNodeboxCollider(collisionbox)}
	elseif drawtype == "normal" or drawtype == "mesh"
			or drawtype:sub(1, #"allfaces") == "allfaces"
			or drawtype:sub(1, #"glasslike") == "glasslike" then
		boxtype = {type = "normal"}
	elseif drawtype == "nodebox" then
		local nodebox = nodeDef.node_box
		boxtype = {type = "nodebox", boxes = self:extractNodeboxCollider(nodebox)}
	end
	return boxtype
end

function fysiks.BlockCollider:calculateNodePositions()
	self.nodes = {}
	for x = 0, fysiks.BLOCKSIZE - 1, 1 do
		self.nodes[x] = {}
		for y = 0, fysiks.BLOCKSIZE - 1, 1 do
			self.nodes[x][y] = {}
			for z = 0, fysiks.BLOCKSIZE - 1, 1 do
				local pos = self:getNodePos({x = x, y = y, z = z})
				self.nodes[x][y][z] = self:getNodeColliderInfo(minetest.get_node(pos))
			end
		end
	end
end

function fysiks.BlockCollider:getNode(pos)
	local localpos = self:getLocalPos(pos)
	return self.nodes[localpos.x][localpos.y][localpos.z]
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
				local boxtype = self.nodes[x][y][z]
				if boxtype and boxtype.type == "normal" then
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
					if boxtype and boxtype.type == "nodebox" then
						for k, box in ipairs(boxtype.boxes) do
							local min = vector.add({x = x, y = y, z = z}, box[1])
							local max = vector.add({x = x, y = y, z = z}, box[2])
							local cuboid = fysiks.Cuboid:new(self.body, min, max)
							cuboid:setPosition(self.body.position)
							table.insert(self.colliders, cuboid)
						end
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
