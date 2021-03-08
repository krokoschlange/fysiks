fysiks.Sphere = fysiks.BoundingVolume:new(nil)
fysiks.Sphere.type = "sphere"
fysiks.Sphere.__index = fysiks.Sphere

function fysiks.Sphere:new(obj, radius)
	local s = fysiks.BoundingVolume:new(obj)
	setmetatable(s, self)
	s.object = obj
	s.radius = radius
	return s
end

function fysiks.Sphere:getFurthestPointInDirection(dir)
	return vector.add(self.position, vector.multiply(vector.normalize(dir), self.radius))
end
