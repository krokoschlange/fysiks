fysiks.BoundingVolume = {
	object = nil,
	id = 0,
	rotation = nil,
	position = nil,
	type = "abstract",
	removed = false,
	aabb = nil
}
fysiks.BoundingVolume.__index = fysiks.BoundingVolume

fysiks.nextVolumeID = 0

function fysiks.getVolumeID()
	fysiks.nextVolumeID = fysiks.nextVolumeID + 1
	return fysiks.nextVolumeID
end

function fysiks.BoundingVolume:new(obj)
	local bV = setmetatable({}, self)
	bV.object = obj
	if obj then
		bV.id = fysiks.getVolumeID()
	end
	bV.rotation = Matrix:rotation({x = 0, y = 0, z = 0})
	bV.position = {x = 0, y = 0, z = 0}
	bV.removed = false
	return bV
end

function fysiks.BoundingVolume:getAABB()
	return self.aabb
end

function fysiks.BoundingVolume:calculateAABB()
	local xMax = self:getFurthestPointInDirection({x = 1, y = 0, z = 0}).x
	local xMin = self:getFurthestPointInDirection({x = -1, y = 0, z = 0}).x
	local yMax = self:getFurthestPointInDirection({x = 0, y = 1, z = 0}).y
	local yMin = self:getFurthestPointInDirection({x = 0, y = -1, z = 0}).y
	local zMax = self:getFurthestPointInDirection({x = 0, y = 0, z = 1}).z
	local zMin = self:getFurthestPointInDirection({x = 0, y = 0, z = -1}).z

	self.aabb = fysiks.AABB:new({x = xMax, y = yMax, z = zMax}, {x = xMin, y = yMin, z = zMin}, self)
end

function fysiks.BoundingVolume:getFurthestPointInDirection(dir)
	return {x = 0, y = 0, z = 0}
end

function fysiks.BoundingVolume:setRotation(rot)
	self.rotation = rot
end

function fysiks.BoundingVolume:setPosition(pos)
	self.position = pos
	self:calculateAABB()
end

function fysiks.BoundingVolume:intersectRay(pos, dir, dir_inv, dist)
	local t = self.aabb:intersectRay(pos, dir_inv, dist)
	if t and t < dist then
		return self:intersectRayImpl(pos, dir, dir_inv, dist)
	end
	return nil
end

function fysiks.BoundingVolume:intersectRayImpl(pos, dir, dir_inv, dist)
	return nil
end
