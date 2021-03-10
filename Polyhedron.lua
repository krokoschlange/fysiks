fysiks.Polyhedron = fysiks.BoundingVolume:new(nil)
fysiks.Polyhedron.__index = fysiks.Polyhedron

function fysiks.Polyhedron:new(obj, vertices)
	local p = fysiks.BoundingVolume:new(obj)
	setmetatable(p, self)
	p.object = obj
	local vertices = vertices or {}
	p.vertices = vertices
	p.origVerts = {}

	for k, v in ipairs(vertices) do
		table.insert(p.origVerts, {x = v.x, y = v.y, z = v.z})
	end

	return p
end


function fysiks.Polyhedron:getFurthestPointInDirection(dir)
	local dotProduct = nil
	local vert = nil
	local idx = -1
	for k, v in ipairs(self.vertices) do
		local dotPr2 = vector.dot(v, vector.normalize(dir))
		if vert == nil or dotPr2 > dotProduct then
			vert = v
			idx = k
			dotProduct = dotPr2
		end
	end
	return vert, idx
end

function fysiks.Polyhedron:updateVertexPositions()
	local posDiff = vector.toMatrix(self.position)

	for k, vert in ipairs(self.origVerts) do
		local vPos = vector.toMatrix(vert)

		vPos = self.rotation * vPos + posDiff

		self.vertices[k] = vector.fromMatrix(vPos)
	end
end

function fysiks.Polyhedron:setRotation(rot)
	self.rotation = rot
	self:updateVertexPositions()
	self:calculateAABB()
end

function fysiks.Polyhedron:setPosition(pos)
	self.position = pos
	self:updateVertexPositions()
	self:calculateAABB()
end
