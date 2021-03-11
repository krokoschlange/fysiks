fysiks.FacedPolyhedron = fysiks.Polyhedron:new(nil)
fysiks.FacedPolyhedron.__index = fysiks.FacedPolyhedron

function fysiks.FacedPolyhedron:new(obj, verts, faces)
	local p = setmetatable(fysiks.Polyhedron:new(obj, verts), self)
	p.faces = {}
	for k, face in ipairs(faces) do
		table.insert(p.faces, {})
		for __, vert in ipairs(face) do
			table.insert(p.faces[k], vert)
		end
	end
	p.neighbors = {}
	--p:calculateNeighbors()
	p:updateCenter()
	return p
end

function fysiks.FacedPolyhedron:calculateNeighbors()
	self.neighbors = {}
	--is there a better way?
	for faceIdx, face in ipairs(self.faces) do
		table.insert(self.neighbors, {})
		for face2Idx, face2 in ipairs(self.faces) do
			if faceIdx ~= face2Idx then
				local doubles = 0
				for _, vert in ipairs(face) do
					for __, vert2 in ipairs(face2) do
						if vert == vert2 then
							doubles = doubles + 1
							break
						end
					end
					if doubles >= 2 then
						table.insert(self.neighbors[faceIdx], face2Idx)
						break
					end
				end
			end
		end
	end
end

--[==[function fysiks.FacedPolyhedron:replaceFace(face, vert)
	table.insert(self.vertices, vert)
	local newVert = #self.vertices
	local faceArray = self.faces[face]

	local relPos = vector.subtract(vert, self.vertices[faceArray[1]])
	local tang1 = vector.subtract(self.vertices[faceArray[2]], self.vertices[faceArray[1]])
	local tang2 = vector.subtract(self.vertices[faceArray[3]], self.vertices[faceArray[1]])
	local normal = vector.normalize(vector.cross(tang1, tang2))
	local dist = math.abs(vector.dot(normal, relPos))
	if dist < 0.05 then
		table.insert(faceArray, newVert)
	else
		table.remove(self.faces, face)
		for i = 1, #faceArray - 1, 1 do
			local newFace = {faceArray[i], faceArray[i + 1], newVert}
			table.insert(self.faces, newFace)
		end
		local newFace = {faceArray[#faceArray], faceArray[1], newVert}
		table.insert(self.faces, newFace)
		end
	self:updateCenter()
end]==]

function fysiks.FacedPolyhedron:addVertex(vert)
	local facesToDelete = {}
	local holeEdges = {}
	for k, face in ipairs(self.faces) do
		local tang1 = vector.subtract(self.vertices[face[2]], self.vertices[face[1]])
		local tang2 = vector.subtract(self.vertices[face[3]], self.vertices[face[1]])
		local normal = vector.normalize(vector.cross(tang1, tang2))
		local relVert = vector.subtract(self.vertices[face[1]], self.center)
		if vector.dot(normal, relVert) < 0 then
			normal = vector.multiply(normal, -1)
		end
		local relPos = vector.subtract(vert, self.vertices[face[1]])
		local dot = vector.dot(normal, relPos)
		if dot >= -0.0001 then
			--in case of precision issues
			if dot < 0 then
				vert = vector.add(vert, vector.multiply(normal, 0.0001))
			end
			self.faces[k] = nil
			local addHoleEdge = function(v1, v2)
				for ke, edge in ipairs(holeEdges) do
					if v1 == edge[1] and v2 == edge[2] or v1 == edge[2] and v2 == edge[1] then
						table.remove(holeEdges, ke)
						return
					end
				end
				table.insert(holeEdges, {v1, v2})
			end
			for kv, vertIdx in ipairs(face) do
				if kv < #face then
					addHoleEdge(vertIdx, face[kv + 1])
				else
					addHoleEdge(vertIdx, face[1])
				end
			end
		end
	end
	table.insert(self.vertices, vert)
	local newVertIdx = #self.vertices
	for _, edge in ipairs(holeEdges) do
		table.insert(self.faces, {edge[1], edge[2], newVertIdx})
	end
	local j, n = 1, #self.faces
	for i = 1, n do
		if self.faces[i] then
			if i ~= j then
				self.faces[j] = self.faces[i]
				self.faces[i] = nil
			end
			j = j + 1
		end
	end
end

function fysiks.FacedPolyhedron:findClosestFace(point)
	local closestDist = nil
	local closestNormal = nil
	local faceIdx = nil
	for idx, face in ipairs(self.faces) do
		local refVert = self.vertices[face[1]]
		local relPos = vector.subtract(point, refVert)
		local tang1 = vector.subtract(self.vertices[face[2]], self.vertices[face[1]])
		local tang2 = vector.subtract(self.vertices[face[3]], self.vertices[face[1]])
		local normal = vector.normalize(vector.cross(tang1, tang2))
		local dist = math.abs(vector.dot(normal, relPos))
		if closestDist == nil or dist < closestDist then
			closestDist = dist
			closestNormal = normal
			faceIdx = idx
		end
	end
	return faceIdx, vector.multiply(closestNormal, closestDist)
end

function fysiks.FacedPolyhedron:updateCenter()
	self.center = vector.new(0, 0, 0)
	for _, v in ipairs(self.vertices) do
		self.center = vector.add(self.center, v)
	end
	self.center = vector.divide(self.center, #self.vertices)
end

function fysiks.FacedPolyhedron:updateVertexPositions()
	fysiks.Polyhedron.updateVertexPositions(self)
	self:updateCenter()
end

function fysiks.FacedPolyhedron:intersectRayImpl(pos, dir, dir_inv, dist)
	local n = 0
	local d = 0
	local normal = vector.new()
	local edge1 = vector.new()
	local edge2 = vector.new()
	local tenter = 0
	local tleave = dist
	local intersectNormal = normal
	for _, face in ipairs(self.faces) do
		edge1 = vector.subtract(self.vertices[face[1]], self.vertices[face[2]])
		edge2 = vector.subtract(self.vertices[face[1]], self.vertices[face[3]])
		normal = vector.normalize(vector.cross(edge1, edge2))
		if vector.dot(normal, vector.subtract(self.center, self.vertices[face[1]])) < 0 then
			normal = vector.multiply(normal, -1)
		end
		n = - vector.dot(normal, vector.subtract(pos, self.vertices[face[1]]))
		d = vector.dot(normal, dir)
		if math.abs(d) < 0.00000001 then
			if n < 0 then
				return nil
			end
		else
			local t = n / d
			if d > 0 then
				if t > tenter then
					tenter = t
					intersectNormal = normal
				end
			else
				tleave = math.min(tleave, t)
			end
			if tenter > tleave then
				return nil
			end
		end
	end
	return {
		type = "object",
		ref = self.object,
		intersection_point = vector.add(vector.multiply(dir, tenter), pos),
		box_id = nil,
		intersection_normal = intersectNormal,
		distance = tenter,
		fysiks_id = self.id
	}
end

-- i used this for testing, it might be handy in the future
function fysiks.FacedPolyhedron:print(n)
	local str = "["
	for _, v in ipairs(self.vertices) do
		str = str .. v.x .. ", " .. v.y .. ", " .. v.z .. ", "
	end
	str = str .. "], " .. "[" .. n.x .. ", " .. n.y .. ", " .. n.z .. "], ["
	for _, f in ipairs(self.faces) do
		str = str .. "["
		for __, v in ipairs(f) do
			str = str .. v .. ", "
		end
		str = str .. "], "
	end
	str = str .. "]"
	print(str)
end
