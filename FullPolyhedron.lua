fysiks.FullPolyhedron = fysiks.FacedPolyhedron:new(nil, {}, {}, {})
fysiks.FullPolyhedron.type = "polyhedron"
fysiks.FullPolyhedron.__index = fysiks.FullPolyhedron


function fysiks.FullPolyhedron:new(obj, verts, edges, faces)
	local p = setmetatable(fysiks.FacedPolyhedron:new(obj, verts, faces), self)
	p.edges = edges
	return p
end

function fysiks.FullPolyhedron:clip(point, normal, doNotReplace)
	local frontVertices = {}
	local backVertices = {}
	local vertexFlags = {}
	local vertexReplacements = {}
	for k, v in ipairs(self.vertices) do
		local diff = vector.subtract(v, point)
		if vector.dot(diff, normal) < 0 then
			table.insert(frontVertices, k)
			table.insert(vertexFlags, true)
			table.insert(vertexReplacements, k)
		else
			table.insert(backVertices, k)
			table.insert(vertexFlags, false)
			table.insert(vertexReplacements, false)
		end
	end

	if doNotReplace then
		local verts = {}
		for _, v in ipairs(frontVertices) do
			table.insert(verts, vector.new(self.vertices[v]))
		end
		return verts
	end
	--create a list to store the vertices at the cut through each face
	local faceCuts = {}
	for _, face in ipairs(self.faces) do
		table.insert(faceCuts, {})
	end

	--clip all edges
	local newEdges = {}
	for _, edge in ipairs(self.edges) do
		if vertexFlags[edge[1]] ~= vertexFlags[edge[2]] then
			local back = edge[1]
			if vertexFlags[edge[1]] then
				back = edge[2]
			end
			local dir = vector.subtract(self.vertices[edge[2]], self.vertices[edge[1]])
			local dist = vector.dot(vector.subtract(point, self.vertices[edge[1]]), normal) / vector.dot(dir, normal)
			local intersect = vector.add(self.vertices[edge[1]], vector.multiply(dir, dist))
			vertexReplacements[back] = intersect
			for faceIdx, face in ipairs(self.faces) do
				local vertexInFace = false
				for _, vert in ipairs(face) do
					if vert == back then
						vertexInFace = true
						break
					end
				end
				if vertexInFace then
					table.insert(faceCuts[faceIdx], back)
				end
			end
			table.insert(newEdges, {edge[1], edge[2]})
		elseif  vertexFlags[edge[1]] then
			table.insert(newEdges, {edge[1], edge[2]})
		end
	end

	--create new list of vertices
	local newVertices = {}
	for k, vert in ipairs(vertexReplacements) do
		if vert and type(vert) == "number" then
			table.insert(newVertices, vector.new(self.vertices[vert]))
			vertexReplacements[k] = #newVertices
		elseif vert and type(vert) == "table" then
			table.insert(newVertices, vector.new(vert))
			vertexReplacements[k] = #newVertices
		end
	end

	--create new faces
	local newFaces = {}
	for _, face in ipairs(self.faces) do
		local newFace = {}
		for __, vert in ipairs(face) do
			if vertexReplacements[vert] then
				table.insert(newFace, vertexReplacements[vert])
			end
		end
		if #newFace >= 3 then
			table.insert(newFaces, newFace)
		end
	end

	--fix edge vertex indexes
	for _, edge in ipairs(newEdges) do
		edge[1] = vertexReplacements[edge[1]]
		edge[2] = vertexReplacements[edge[2]]
	end

	--close cut faces
	for _, face in ipairs(faceCuts) do
		if #face == 2 then
			table.insert(newEdges, {vertexReplacements[face[1]], vertexReplacements[face[2]]})
		end
	end

	local clipped = fysiks.FullPolyhedron:new(nil, newVertices, newEdges, newFaces)
	return clipped
end
