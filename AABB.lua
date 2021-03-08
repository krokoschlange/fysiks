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
