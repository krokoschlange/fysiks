fysiks.Cuboid = fysiks.FullPolyhedron:new(nil, {}, {}, {})
fysiks.Cuboid.__index = fysiks.Cuboid

function fysiks.Cuboid:new(obj, min, max)
	local verts = {
		{x = min.x, y = min.y, z = min.z},
		{x = min.x, y = min.y, z = max.z},
		{x = min.x, y = max.y, z = min.z},
		{x = min.x, y = max.y, z = max.z},
		{x = max.x, y = min.y, z = min.z},
		{x = max.x, y = min.y, z = max.z},
		{x = max.x, y = max.y, z = min.z},
		{x = max.x, y = max.y, z = max.z},
	}
	local edges = {
		{1, 2},
		{2, 4},
		{4, 3},
		{3, 1},
		{5, 6},
		{6, 8},
		{8, 7},
		{7, 5},
		{1, 5},
		{2, 6},
		{3, 7},
		{4, 8},
	}
	local faces = {
		{1, 2, 3, 4},
		{1, 2, 5, 6},
		{1, 3, 5, 7},
		{2, 4, 6, 8},
		{3, 4, 7, 8},
		{5, 6, 7, 8},
	}
	local c = fysiks.FullPolyhedron:new(obj, verts, edges, faces)
	c = setmetatable(c, self)
	return c
end
