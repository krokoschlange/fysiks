fysiks.Constraint = {
	jacobian = nil,
	bias = nil,
	bodyA = nil,
	bodyB = nil,
	mass = nil,
	massInv = nil,
	lagMultSum = nil,
	tmpLagMul = nil,
	clampTop = false,
	clampTopVal = 0,
	clampBottom = false,
	clampBottomVal = 0,
}
fysiks.Constraint.__index = fysiks.Constraint

function fysiks.Constraint:new(jacobian, bias, a, b)
	local c = setmetatable({}, self)
	c.jacobian = jacobian
	c.bias = bias
	c.bodyA = a
	c.bodyB = b

	if a and b then
		--local Ia = a:getInertiaTensor()
		--local Ib = b:getInertiaTensor()
		local IaInv = a:getInvInertiaTensor()
		local IbInv = b:getInvInertiaTensor()
		--[[c.mass = Matrix:new({
			{a:getMass(), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			{0, a:getMass(), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			{0, 0, a:getMass(), 0, 0, 0, 0, 0, 0, 0, 0, 0},
			{0, 0, 0, Ia:get(1, 1), Ia:get(1, 2), Ia:get(1, 3), 0, 0, 0, 0, 0, 0},
			{0, 0, 0, Ia:get(2, 1), Ia:get(2, 2), Ia:get(2, 3), 0, 0, 0, 0, 0, 0},
			{0, 0, 0, Ia:get(3, 1), Ia:get(3, 2), Ia:get(3, 3), 0, 0, 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, b:getMass(), 0, 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0, b:getMass(), 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0, 0, b:getMass(), 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0, 0, 0, Ib:get(1, 1), Ib:get(1, 2), Ib:get(1, 3)},
			{0, 0, 0, 0, 0, 0, 0, 0, 0, Ib:get(2, 1), Ib:get(2, 2), Ib:get(2, 3)},
			{0, 0, 0, 0, 0, 0, 0, 0, 0, Ib:get(3, 1), Ib:get(3, 2), Ib:get(3, 3)}
		})]]
		--c.massInv = c.mass:inverse() --don't do this, it takes ages
		--do this instead
		local maInv = a:getInvMass()
		local mbInv = b:getInvMass()
		c.massInv = Matrix:new({
			{maInv, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			{0, maInv, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			{0, 0, maInv, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			{0, 0, 0, IaInv:get(1, 1), IaInv:get(1, 2), IaInv:get(1, 3), 0, 0, 0, 0, 0, 0},
			{0, 0, 0, IaInv:get(2, 1), IaInv:get(2, 2), IaInv:get(2, 3), 0, 0, 0, 0, 0, 0},
			{0, 0, 0, IaInv:get(3, 1), IaInv:get(3, 2), IaInv:get(3, 3), 0, 0, 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, mbInv, 0, 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0, mbInv, 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0, 0, mbInv, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0, 0, 0, IbInv:get(1, 1), IbInv:get(1, 2), IbInv:get(1, 3)},
			{0, 0, 0, 0, 0, 0, 0, 0, 0, IbInv:get(2, 1), IbInv:get(2, 2), IbInv:get(2, 3)},
			{0, 0, 0, 0, 0, 0, 0, 0, 0, IbInv:get(3, 1), IbInv:get(3, 2), IbInv:get(3, 3)}
		})
	end
	if jacobian then
		c.lagMultSum = Matrix:new(jacobian:height(), 1)
		c.tmpLagMul = Matrix:new(jacobian:height(), 1)
	end

	return c
end


function fysiks.Constraint:calculateLagMul()
	local vel = Matrix:new({
		{self.bodyA.tmpConstraintVel:get(1, 1)},
		{self.bodyA.tmpConstraintVel:get(2, 1)},
		{self.bodyA.tmpConstraintVel:get(3, 1)},
		{self.bodyA.tmpConstraintVel:get(4, 1)},
		{self.bodyA.tmpConstraintVel:get(5, 1)},
		{self.bodyA.tmpConstraintVel:get(6, 1)},
		{self.bodyB.tmpConstraintVel:get(1, 1)},
		{self.bodyB.tmpConstraintVel:get(2, 1)},
		{self.bodyB.tmpConstraintVel:get(3, 1)},
		{self.bodyB.tmpConstraintVel:get(4, 1)},
		{self.bodyB.tmpConstraintVel:get(5, 1)},
		{self.bodyB.tmpConstraintVel:get(6, 1)}
	})
	local num = ((self.jacobian * -1) * vel - self.bias)
	local den = (self.jacobian * self.massInv) * self.jacobian:transposed()
	local deninv = (den):inverse()
	self.tmpLagMul = deninv * num
end

function fysiks.Constraint:applyTmpLagMul()
	local deltaVel = self.massInv * self.jacobian:transposed() * self.tmpLagMul

	local aTmpVel = self.bodyA.tmpConstraintVel
	local bTmpVel = self.bodyB.tmpConstraintVel

	self.bodyA.tmpConstraintVel = Matrix:new({
		{aTmpVel:get(1, 1) + deltaVel:get(1, 1)},
		{aTmpVel:get(2, 1) + deltaVel:get(2, 1)},
		{aTmpVel:get(3, 1) + deltaVel:get(3, 1)},
		{aTmpVel:get(4, 1) + deltaVel:get(4, 1)},
		{aTmpVel:get(5, 1) + deltaVel:get(5, 1)},
		{aTmpVel:get(6, 1) + deltaVel:get(6, 1)},
	})
	self.bodyB.tmpConstraintVel = Matrix:new({
		{bTmpVel:get(1, 1) + deltaVel:get(7, 1)},
		{bTmpVel:get(2, 1) + deltaVel:get(8, 1)},
		{bTmpVel:get(3, 1) + deltaVel:get(9, 1)},
		{bTmpVel:get(4, 1) + deltaVel:get(10, 1)},
		{bTmpVel:get(5, 1) + deltaVel:get(11, 1)},
		{bTmpVel:get(6, 1) + deltaVel:get(12, 1)},
	})
end

function fysiks.Constraint:apply()
	local aTmpVel = self.bodyA.tmpConstraintVel
	local bTmpVel = self.bodyB.tmpConstraintVel

	if aTmpVel:get(1, 1) ~= aTmpVel:get(1, 1) or aTmpVel:get(2, 1) ~= aTmpVel:get(2, 1) or aTmpVel:get(3, 1) ~= aTmpVel:get(3, 1) then
		return
	end
	self.bodyA:setVelocity({x = aTmpVel:get(1, 1), y = aTmpVel:get(2, 1), z = aTmpVel:get(3, 1)})
	self.bodyA:setAngularVelocity({x = aTmpVel:get(4, 1), y = aTmpVel:get(5, 1), z = aTmpVel:get(6, 1)})
	self.bodyB:setVelocity({x = bTmpVel:get(1, 1), y = bTmpVel:get(2, 1), z = bTmpVel:get(3, 1)})
	self.bodyB:setAngularVelocity({x = bTmpVel:get(4, 1), y = bTmpVel:get(5, 1), z = bTmpVel:get(6, 1)})
end

function fysiks.Constraint:clampLagMult()
	local lagMultSum2 = Matrix:new(self.tmpLagMul:height(), 1)
	for i = 1, self.tmpLagMul:height(), 1 do
		lagMultSum2:set(i, 1, self.lagMultSum:get(i, 1))
	end
	self.lagMultSum = self.lagMultSum + self.tmpLagMul
	for i = 1, self.tmpLagMul:height(), 1 do
		if self.clampTop then
			self.lagMultSum:set(i, 1, math.min(self.lagMultSum:get(i, 1), self.clampTopVal))
		end
		if self.clampBottom then
			self.lagMultSum:set(i, 1, math.max(self.lagMultSum:get(i, 1), self.clampBottomVal))
		end
	end
	self.tmpLagMul = self.lagMultSum - lagMultSum2
end

function fysiks.Constraint:initWarmStart()
	self.tmpLagMul = self.lagMultSum * 1
	--self.lagMultSum = self.lagMultSum * 0
end
