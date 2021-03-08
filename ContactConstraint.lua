fysiks.ContactConstraint = fysiks.Constraint:new()
fysiks.ContactConstraint.__index = fysiks.ContactConstraint

function fysiks.ContactConstraint:new(jacobian, bias, a, b, con)
	local c = setmetatable(fysiks.Constraint:new(jacobian, bias, a, b), self)
	c.clampTop = false
	c.clampTopVal = 0
	c.clampBottom = true
	c.clampBottomVal = 0

	c.contact = con

	return c
end

function fysiks.ContactConstraint:clampLagMult()
	fysiks.Constraint.clampLagMult(self)
	self.contact:setTangentClamp(self.lagMultSum:get(1, 1))
end
