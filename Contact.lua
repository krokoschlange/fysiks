fysiks.Contact = {
	bodyA = nil,
	aPoint = nil,
	localAPoint = nil,
	bodyB = nil,
	bPoint = nil,
	localBPoint = nil,
	normal = nil,
	tangent1 = nil,
	tangent2 = nil,
	frictionCoeff = nil,
	depth = 0,
	normalConstraint = nil,
	tangentConstraint1 = nil,
	tangentConstraint2 = nil,
	baumgarte = minetest.settings:get("fysiks_baumgarte") or 0.25,
	penSlop = minetest.settings:get("fysiks_pen_slop") or 0.1,
	resSlop = minetest.settings:get("fysiks_res_slop") or 1,
	persistentThresh = 0.07
}
fysiks.Contact.__index = fysiks.Contact


function fysiks.Contact:new(a, b, aPoint, bPoint, normal, dtime)
	local c = setmetatable({}, fysiks.Contact)
	c.bodyA = a
	c.bodyB = b
	c.aPoint = aPoint
	c.localAPoint = a:globalToLocal(aPoint)
	c.bPoint = bPoint
	c.localBPoint = b:globalToLocal(bPoint)
	c.normal = vector.normalize(normal)
	local fricA = a.friction
	local fricB = b.friction
	local exponent = (fricA - fricB) / (fricA + fricB)
	c.frictionCoeff = (fricA + fricB) / 2 * math.pow(2, -exponent * exponent)
	c:calculateDepth()
	c:calculateTangents()
	c.normalConstraint = fysiks.ContactConstraint:new(Matrix:new(1, 12), Matrix:new(1, 1), a, b, c)
	--c.normalConstraint = fysiks.Constraint:new(Matrix:new(1, 1), Matrix:new(1, 1), a, b)
	--fysiks.ContactConstraint:new(a, b, aPoint, bPoint, normal, dtime, self.baumgarte, self.penSlop, self.resSlop, c)
	c:calculateContactConstraint(dtime)
	c.tangentConstraint1 = fysiks.Constraint:new(Matrix:new(1, 12), Matrix:new(1, 1), a, b)
	c.tangentConstraint1.clampTop = true
	c.tangentConstraint1.clampBottom = true
	c.tangentConstraint2 = fysiks.Constraint:new(Matrix:new(1, 12), Matrix:new(1, 1), a, b)
	c.tangentConstraint2.clampTop = true
	c.tangentConstraint2.clampBottom = true
	c:calculateTangentConstraints()
	return c
end

function fysiks.Contact:addConstraints()
	table.insert(fysiks.constraints, self.normalConstraint)
	table.insert(fysiks.constraints, self.tangentConstraint1)
	table.insert(fysiks.constraints, self.tangentConstraint2)
end

function fysiks.Contact:isValid()
	local aP = self.bodyA:localToGlobal(self.localAPoint)
	local bP = self.bodyB:localToGlobal(self.localBPoint)
	if vector.dot(vector.subtract(bP, aP), self.normal) > 0 then
		return false
	end
	local rA = vector.subtract(aP, self.aPoint)
	local rB = vector.subtract(bP, self.bPoint)
	if vector.length(rA) < self.persistentThresh and
			vector.length(rB) < self.persistentThresh then
		return true
	end
	return false
end

function fysiks.Contact:isSimilar(other)
	local rA = vector.length(vector.subtract(self.aPoint, other.aPoint))
	local rB = vector.length(vector.subtract(self.bPoint, other.bPoint))
	return rA < self.persistentThresh and rB < self.persistentThresh
end

function fysiks.Contact:calculateDepth()
	self.depth = vector.length(vector.subtract(self.aPoint, self.bPoint))
end

function fysiks.Contact:calculateTangents()
	--[[if self.normal.x >= 0.57735 then
		self.tangent1 = {x = self.normal.y, y = -self.normal.x, z = 0}
	else
		self.tangent1 = {x = 0, y = self.normal.z, z = -self.normal.y}
	end
	self.tangent1 = vector.normalize(self.tangent1)
	self.tangent2 = vector.normalize(vector.cross(self.normal, self.tangent1))]]
	local v = vector.subtract(self.bodyA.velocity, self.bodyB.velocity)
	if vector.length(v) < 0.001 or math.abs(vector.dot(vector.normalize(v), self.normal)) > 0.95 then
		v = {x = 0, y = 1, z = 0}
		if math.abs(vector.dot(v, self.normal)) > 0.95 then
			v = {x = 1, y = 0, z = 0}
		end
	end
	self.tangent2 = vector.normalize(vector.cross(v, self.normal))
	self.tangent1 = vector.normalize(vector.cross(self.tangent2, self.normal))
end

function fysiks.Contact:calculateTangentConstraints()
	local aLever = vector.subtract(self.aPoint, self.bodyA.position)
	local invALever = vector.multiply(aLever, -1)
	local aRot1 = vector.cross(invALever, self.tangent1)
	local bLever = vector.subtract(self.bPoint, self.bodyB.position)
	local bRot1 = vector.cross(bLever, self.tangent1)
	self.tangentConstraint1:setJacobianM({{
		-self.tangent1.x,
		-self.tangent1.y,
		-self.tangent1.z,
		aRot1.x,
		aRot1.y,
		aRot1.z,
		self.tangent1.x,
		self.tangent1.y,
		self.tangent1.z,
		bRot1.x,
		bRot1.y,
		bRot1.z
	}})
	local aRot2 = vector.cross(invALever, self.tangent2)
	local bRot2 = vector.cross(bLever, self.tangent2)
	self.tangentConstraint2:setJacobianM({{
		-self.tangent2.x,
		-self.tangent2.y,
		-self.tangent2.z,
		aRot2.x,
		aRot2.y,
		aRot2.z,
		self.tangent2.x,
		self.tangent2.y,
		self.tangent2.z,
		bRot2.x,
		bRot2.y,
		bRot2.z
	}})
end

function fysiks.Contact:calculateContactConstraint(dtime)
	local aLever = vector.subtract(self.aPoint, self.bodyA.position)
	local invALever = vector.multiply(aLever, -1)
	local aRot = vector.cross(invALever, self.normal)
	local bLever = vector.subtract(self.bPoint, self.bodyB.position)
	local bRot = vector.cross(bLever, self.normal)
	self.normalConstraint:setJacobianM({{
		-self.normal.x,
		-self.normal.y,
		-self.normal.z,
		aRot.x,
		aRot.y,
		aRot.z,
		self.normal.x,
		self.normal.y,
		self.normal.z,
		bRot.x,
		bRot.y,
		bRot.z
	}})
	local bias = (-(self.baumgarte / dtime)) * math.max(self.depth - self.penSlop, 0)

	local aPointVel = vector.add(self.bodyA.velocity, vector.cross(self.bodyA.angularVelocity, aLever))
	local bPointVel = vector.add(vector.cross(self.bodyB.angularVelocity, bLever), self.bodyB.velocity)
	local restitutionCoeff = (self.bodyA.bounciness + self.bodyB.bounciness) / 2
	local restitutionBias = restitutionCoeff * math.max(0, vector.dot(vector.subtract(aPointVel, bPointVel), self.normal) - self.resSlop)
	self.normalConstraint.bias:set(1, 1, bias - restitutionBias)
end

function fysiks.Contact:recalculate(dtime)
	self.aPoint = self.bodyA:localToGlobal(self.localAPoint)
	self.bPoint = self.bodyB:localToGlobal(self.localBPoint)
	self:calculateDepth()
	self:calculateTangents()
	self:calculateContactConstraint(dtime)
	self:calculateTangentConstraints()
end

function fysiks.Contact:setTangentClamp(clamp)
	self.tangentConstraint1.clampTopVal = math.abs(clamp) * self.frictionCoeff
	self.tangentConstraint1.clampBottomVal = -math.abs(clamp) * self.frictionCoeff
	self.tangentConstraint2.clampTopVal = math.abs(clamp) * self.frictionCoeff
	self.tangentConstraint2.clampBottomVal = -math.abs(clamp) * self.frictionCoeff
end
