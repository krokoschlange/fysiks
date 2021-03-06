fysiks.Constraint = {
	jacobian = nil,
	jacobianT = nil,
	bias = nil,
	bodyA = nil,
	bodyB = nil,
	maInv = nil,
	mbInv = nil,
	IaInv = nil,
	IbInv = nil,
	JxMIxJT_I = nil,
	MIxJT = nil,
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
		c.IaInv = a:getInvInertiaTensor()
		c.IbInv = b:getInvInertiaTensor()
		c.maInv = a:getInvMass()
		c.mbInv = b:getInvMass()
	end
	if jacobian then
		c:setJacobianM(jacobian.M)
		c.lagMultSum = Matrix:new(jacobian:height(), 1)
		c.tmpLagMul = Matrix:new(jacobian:height(), 1)
	end

	return c
end

function fysiks.Constraint:setJacobianM(jacobianM)
	self.jacobian.M = jacobianM
	self.jacobianT = self.jacobian:transposed()
	if #self.jacobian.M == 1 then
		self.MIxJT = Matrix:newCheap({
			{self.maInv * self.jacobianT.M[1][1]},
			{self.maInv * self.jacobianT.M[2][1]},
			{self.maInv * self.jacobianT.M[3][1]},
			{self.IaInv.M[1][1] * self.jacobianT.M[4][1] + self.IaInv.M[1][2] * self.jacobianT.M[5][1] + self.IaInv.M[1][3] * self.jacobianT.M[6][1]},
			{self.IaInv.M[2][1] * self.jacobianT.M[4][1] + self.IaInv.M[2][2] * self.jacobianT.M[5][1] + self.IaInv.M[2][3] * self.jacobianT.M[6][1]},
			{self.IaInv.M[3][1] * self.jacobianT.M[4][1] + self.IaInv.M[3][2] * self.jacobianT.M[5][1] + self.IaInv.M[3][3] * self.jacobianT.M[6][1]},
			{self.mbInv * self.jacobianT.M[7][1]},
			{self.mbInv * self.jacobianT.M[8][1]},
			{self.mbInv * self.jacobianT.M[9][1]},
			{self.IbInv.M[1][1] * self.jacobianT.M[10][1] + self.IbInv.M[1][2] * self.jacobianT.M[11][1] + self.IbInv.M[1][3] * self.jacobianT.M[12][1]},
			{self.IbInv.M[2][1] * self.jacobianT.M[10][1] + self.IbInv.M[2][2] * self.jacobianT.M[11][1] + self.IbInv.M[2][3] * self.jacobianT.M[12][1]},
			{self.IbInv.M[3][1] * self.jacobianT.M[10][1] + self.IbInv.M[3][2] * self.jacobianT.M[11][1] + self.IbInv.M[3][3] * self.jacobianT.M[12][1]},
		})
	else
		local massInv = Matrix:newCheap({
			{self.maInv, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			{0, self.maInv, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			{0, 0, self.maInv, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			{0, 0, 0, self.IaInv.M[1][1], self.IaInv.M[1][2], self.IaInv.M[1][3]},
			{0, 0, 0, self.IaInv.M[2][1], self.IaInv.M[2][2], self.IaInv.M[2][3]},
			{0, 0, 0, self.IaInv.M[3][1], self.IaInv.M[3][2], self.IaInv.M[3][3]},
			{0, 0, 0, 0, 0, 0, self.mbInv, 0, 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0, self.mbInv, 0, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0, 0, self.mbInv, 0, 0, 0},
			{0, 0, 0, 0, 0, 0, 0, 0, 0, self.IbInv.M[1][1], self.IbInv.M[1][2], self.IbInv.M[1][3]},
			{0, 0, 0, 0, 0, 0, 0, 0, 0, self.IbInv.M[2][1], self.IbInv.M[2][2], self.IbInv.M[2][3]},
			{0, 0, 0, 0, 0, 0, 0, 0, 0, self.IbInv.M[3][1], self.IbInv.M[3][2], self.IbInv.M[3][3]}
		})
		self.MIxJT = massInv * self.jacobianT
	end
	self.JxMIxJT_I = (self.jacobian * self.MIxJT):inverse()
end

function fysiks.Constraint:calculateLagMul()
	local vel = Matrix:new({
		{self.bodyA.tmpConstraintVel.M[1][1]},
		{self.bodyA.tmpConstraintVel.M[2][1]},
		{self.bodyA.tmpConstraintVel.M[3][1]},
		{self.bodyA.tmpConstraintVel.M[4][1]},
		{self.bodyA.tmpConstraintVel.M[5][1]},
		{self.bodyA.tmpConstraintVel.M[6][1]},
		{self.bodyB.tmpConstraintVel.M[1][1]},
		{self.bodyB.tmpConstraintVel.M[2][1]},
		{self.bodyB.tmpConstraintVel.M[3][1]},
		{self.bodyB.tmpConstraintVel.M[4][1]},
		{self.bodyB.tmpConstraintVel.M[5][1]},
		{self.bodyB.tmpConstraintVel.M[6][1]}
	})
	local num = (self.jacobian * vel) * -1 - self.bias
	self.tmpLagMul = self.JxMIxJT_I * num
end

function fysiks.Constraint:applyTmpLagMul()
	local deltaVel = self.MIxJT * self.tmpLagMul

	local aTmpVel = self.bodyA.tmpConstraintVel
	local bTmpVel = self.bodyB.tmpConstraintVel

	self.bodyA.tmpConstraintVel.M = {
		{aTmpVel.M[1][1] + deltaVel.M[1][1]},
		{aTmpVel.M[2][1] + deltaVel.M[2][1]},
		{aTmpVel.M[3][1] + deltaVel.M[3][1]},
		{aTmpVel.M[4][1] + deltaVel.M[4][1]},
		{aTmpVel.M[5][1] + deltaVel.M[5][1]},
		{aTmpVel.M[6][1] + deltaVel.M[6][1]},
	}
	self.bodyB.tmpConstraintVel.M = {
		{bTmpVel.M[1][1] + deltaVel.M[7][1]},
		{bTmpVel.M[2][1] + deltaVel.M[8][1]},
		{bTmpVel.M[3][1] + deltaVel.M[9][1]},
		{bTmpVel.M[4][1] + deltaVel.M[10][1]},
		{bTmpVel.M[5][1] + deltaVel.M[11][1]},
		{bTmpVel.M[6][1] + deltaVel.M[12][1]},
	}
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
