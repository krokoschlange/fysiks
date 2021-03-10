fysiks.AABB = {
	minimum = {},
	maximum = {},
	boundingVolume = nil
}
fysiks.AABB.__index = fysiks.AABB

function fysiks.AABB:new(max, min, bV)
	local aabb = setmetatable({}, self)
	aabb.minimum = min
	aabb.maximum = max
	aabb.boundingVolume = bV
	return aabb
end

function fysiks.AABB:getXValues()
	return {max = self.maximum.x, min = self.minimum.x}
end

function fysiks.AABB:getYValues()
	return {max = self.maximum.y, min = self.minimum.y}
end

function fysiks.AABB:getZValues()
	return {max = self.maximum.z, min = self.minimum.z}
end

function fysiks.AABB:intersectRay(pos, dir_inv, dist)
	local tx1 = (self.minimum.x - pos.x) * dir_inv.x
	local tx2 = (self.maximum.x - pos.x) * dir_inv.x
	local ty1 = (self.minimum.y - pos.y) * dir_inv.y
	local ty2 = (self.maximum.y - pos.y) * dir_inv.y
	local tz1 = (self.minimum.z - pos.z) * dir_inv.z
	local tz2 = (self.maximum.z - pos.z) * dir_inv.z

	local tmax = math.max(tx1, tx2)
	tmax = math.min(tmax, math.max(ty1, ty2))
	tmax = math.min(tmax, math.max(tz1, tz2))

	if tmax < 0 then
		return nil
	end

	local tmin = math.min(tx1, tx2)
	tmin = math.max(tmin, math.min(ty1, ty2))
	tmin = math.max(tmin, math.min(tz1, tz2))

	if tmax < tmin then
		return nil
	end
	if tmin > dist then
		return nil
	end
	return tmin
end
