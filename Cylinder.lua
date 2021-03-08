fysiks.Cylinder = fysiks.BoundingVolume:new(nil)
fysiks.Cylinder.type = "cylinder"
fysiks.Cylinder.__index = fysiks.Cylinder

--TODO

function fysiks.Cylinder:new(obj, radius, height)
	local c = setmetatable({}, self)
	c.object = obj
	c.radius = radius
	return c
end

function fysiks.Cylinder:getFurthestPointInDirection(dir)

end
