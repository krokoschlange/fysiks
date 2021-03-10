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

function fysiks.Sphere:intersectRayImpl(pos, dir, dir_inv, dist)
	local dirToCenter = vector.subtract(self.position, pos)
	local d = vector.dot(dir, dirToCenter)
	if d < 0 then
		return nil
	end
	local dtcsqr = vector.dot(dirToCenter, dirToCenter)
	local rsqr = self.radius * self.radius
	if dtcsqr < rsqr then
		return {
			type = "object",
			ref = self.object,
			intersection_point = pos,
			box_id = nil,
			intersection_normal = {x = 0, y = 0, z = 0},
			distance = 0,
			fysiks_id = self.id
		}
	end
	local csqr = dtcsqr - d * d
	local k = math.sqrt(rsqr - csqr)
	if d < dist + k and csqr < rsqr then
		local distToSurf = d - k
		local intersect = vector.add(vector.multiply(dir, distToSurf), pos)
		return {
			type = "object",
			ref = self.object,
			intersection_point = intersect,
			box_id = nil,
			intersection_normal = vector.subtract(intersect, self.position),
			distance = distToSurf,
			fysiks_id = self.id
		}
	end
	return nil
end
