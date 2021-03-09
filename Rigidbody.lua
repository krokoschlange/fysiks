--make sure unpack works with all lua versions
local unpack = unpack or table.unpack

fysiks.nextID = 0

function fysiks.getNextID()
	fysiks.nextID = fysiks.nextID + 1
	return fysiks.nextID
end

fysiks.STATIC_MASS = 1000000000
fysiks.STATIC_I = Matrix:new({
	{fysiks.STATIC_MASS / 6, 0, 0},
	{0, fysiks.STATIC_MASS / 6, 0},
	{0, 0, fysiks.STATIC_MASS / 6}
})
fysiks.INV_STATIC_I = Matrix:new({
	{0, 0, 0},
	{0, 0, 0},
	{0, 0, 0}
})

fysiks.SLEEP_TIME = 10

fysiks.Rigidbody = {
	fysiks = true,
	fysiksID = 0,
	static = false,
	asleep = false,
	sleepTimer = 0,
	sleepForce = nil,
	sleepTorque = nil,
	mass = 1,
	bounciness = 0,
	friction = 0,
	inertiaTensor = Matrix:new({
		{2/12, 0, 0},
		{0, 2/12, 0},
		{0, 0, 2/12}
	}),
	invInertiaTensor = nil,
	position = {x = 0, y = 0, z = 0},
	velocity = {x = 0, y = 0, z = 0},
	resultantForce = {x = 0, y = 0, z = 0},
	rotation = Matrix:rotation({x = 0, y = 0, z = 0}),
	angularVelocity = {x = 0, y = 0, z = 0},
	resultantTorque = {x = 0, y = 0, z = 0},

	tmpConstraintVel = Matrix:new(6, 1),

	collisionBoxes = {},
	rigidbody_def = {},

	custom_step = nil,
	custom_staticdata = nil,
	custom_activate = nil,
	custom_deactivate = nil
}
fysiks.Rigidbody.__index = fysiks.Rigidbody

function fysiks.Rigidbody:new()
	local r = setmetatable({}, fysiks.Rigidbody)
	r.mass = 1
	self.inertiaTensor = Matrix:new({
		{2/12, 0, 0},
		{0, 2/12, 0},
		{0, 0, 2/12}
	})
	r.position = {x = 0, y = 0, z = 0}
	r.velocity = {x = 0, y = 0, z = 0}
	r.resultantForce = {x = 0, y = 0, z = 0}
	r.rotation = Matrix:rotation({x = 0, y = 0, z = 0})
	r.angularVelocity = {x = 0, y = 0, z = 0}
	r.resultantTorque = {x = 0, y = 0, z = 0}
	r.tmpConstraintVel = Matrix:new(6, 1)
	r.collisionBoxes = {}
	r.fysiksID = fysiks.getNextID()
	return r
end

function fysiks.Rigidbody:localToGlobal(point)
	return vector.add(vector.fromMatrix(self.rotation * vector.toMatrix(point)), self.position)
end

function fysiks.Rigidbody:globalToLocal(point)
	return vector.fromMatrix(self.rotation:inverse() * vector.toMatrix(vector.subtract(point, self.position)))
end

function fysiks.Rigidbody:applyForce(force, point)
	self.resultantForce = vector.add(self.resultantForce, force)
	self.resultantTorque = vector.add(self.resultantTorque, vector.cross(point, force))
end

function fysiks.Rigidbody:integrateVelocity(dtime)
	if self.sleepTimer > 0 and (vector.distance(self.resultantForce, self.sleepForce) > 0.01 or
			vector.distance(self.resultantTorque, self.sleepTorque) > 0.01) then
		self.sleepTimer = 0
		self.asleep = false
	end
	if not self.asleep then
		local acc = vector.divide(self.resultantForce, self.mass)
		if minetest.settings:get("fysiks_use_velocities") == "before" then
			print("pre")
			self.object:add_velocity(vector.subtract(self.velocity, self.object:get_velocity()))
		end
		self.velocity = vector.add(self.velocity, vector.multiply(acc, dtime))

		local angAcc = self.invInertiaTensor * vector.toMatrix(self.resultantTorque)
		self.angularVelocity = vector.add(self.angularVelocity, vector.multiply(vector.fromMatrix(angAcc), dtime))
		self.tmpConstraintVel = Matrix:new({
			{self.velocity.x},
			{self.velocity.y},
			{self.velocity.z},
			{self.angularVelocity.x},
			{self.angularVelocity.y},
			{self.angularVelocity.z},
		})
	end
end

function fysiks.Rigidbody:on_step(dtime, moveresult)
	if self.custom_step then
		self:custom_step(dtime, moveresult)
	end
end

function fysiks.Rigidbody:prepareStep(dtime)
	if not self.static then
		self:integrateVelocity(dtime)
	end
end

function fysiks.Rigidbody:sleep()
	self.asleep = true
	self.velocity = vector.new()
	self.angularVelocity = vector.new()
	self.tmpConstraintVel = Matrix:new({
		{self.velocity.x},
		{self.velocity.y},
		{self.velocity.z},
		{self.angularVelocity.x},
		{self.angularVelocity.y},
		{self.angularVelocity.z},
	})
end

function fysiks.Rigidbody:finishStep(dtime)

	if not self.static and not self.asleep then
		self.position = vector.add(self.position, vector.multiply(self.velocity, dtime))
		if vector.distance(self.object:get_pos(), self.position) > 0.05 then
			self.object:set_pos(self.position)
		end

		self.rotation = Matrix:axisAngle(vector.multiply(self.angularVelocity, dtime)) * self.rotation
		if minetest.settings:get("fysiks_use_velocities") == "after" then
			print("post")
			self.object:add_velocity(vector.subtract(self.velocity, self.object:get_velocity()))
		end
	else
		self.object:set_velocity(vector.new())
	end
	local euler = self.rotation:toEuler()

	self.object:set_rotation(euler)

	for k, v in pairs(self.collisionBoxes) do
		v:setRotation(self.rotation)
		v:setPosition(self.position)
	end

	if vector.length(self.velocity) < 0.1 and vector.length(self.angularVelocity) < 0.1 then
		self.sleepTimer = self.sleepTimer + 1
		self.sleepForce = self.resultantForce
		self.sleepTorque = self.resultantTorque
	else
		self.sleepTimer = 0
		self.asleep = false
	end

	self.resultantForce = {x = 0, y = 0, z = 0}
	self.resultantTorque = {x = 0, y = 0, z = 0}
end

function fysiks.Rigidbody:setVelocity(v)
	if not self.static then
		self.velocity = v
	end
end

function fysiks.Rigidbody:setAngularVelocity(v)
	if not self.static then
		self.angularVelocity = v
	end
end

function fysiks.Rigidbody:getMass()
	if self.static then
		return fysiks.STATIC_MASS
	else
		return self.mass
	end
end

function fysiks.Rigidbody:getInvMass()
	if self.static then
		return 0
	else
		return 1 / self.mass
	end
end

function fysiks.Rigidbody:getInertiaTensor()
	if self.static then
		return fysiks.STATIC_I
	else
		return self.inertiaTensor
	end
end

function fysiks.Rigidbody:getInvInertiaTensor()
	if self.static then
		return fysiks.INV_STATIC_I
	else
		return self.invInertiaTensor
	end
end

function fysiks.Rigidbody:on_activate(staticdata, dtime_s)
	self.mass = self.rigidbody_def.mass or self.mass
	self.inertiaTensor = Matrix:new(self.rigidbody_def.inertiaTensor or self.inertiaTensor)
	self.position = self.object:get_pos()
	self.velocity = self.object:get_velocity()
	self.resultantForce = {x = 0, y = 0, z = 0}
	self.rotation = Matrix:rotation(self.object:get_rotation())
	self.angularVelocity = {x = 0, y = 0, z = 0}
	self.resultantTorque = {x = 0, y = 0, z = 0}
	self.tmpConstraintVel = Matrix:new(6, 1)
	self.collisionBoxes = {}
	self.invInertiaTensor = self.inertiaTensor:inverse()
	self.bounciness = self.rigidbody_def.bounciness or self.bounciness
	self.friction = self.rigidbody_def.friction or self.friction
	self.static = self.rigidbody_def.static or self.static
	self.fysiksID = fysiks.getNextID()
	local collbox_def = self.rigidbody_def.collisionBoxes or {}
	for _, collbox in ipairs(collbox_def) do
		local volume = collbox.type:new(self, unpack(collbox.args))
		table.insert(self.collisionBoxes, volume)
		volume:setPosition(self.position)
		volume:setRotation(self.rotation)
	end
	if self.custom_activate then
		--TODO in the future, when we save something ourselves, separate it from this
		self:custom_activate(staticdata, dtime_s)
	end
end

function fysiks.Rigidbody:on_deactivate()
	self:prepareRemove()
	if self.custom_deactivate then
		self:custom_deactivate()
	end
end

function fysiks.Rigidbody:prepareRemove()
	for _, coll in ipairs(self.collisionBoxes) do
		coll.removed = true
	end
	self.removed = true
end

function fysiks.register_rigidbody(name, def, rigidbody_def)
	local fullDef = {}
	for k, v in pairs(def) do
		fullDef[k] = v
	end
	fullDef.custom_activate = fullDef.on_activate or def.custom_activate
	fullDef.custom_step = fullDef.on_step or def.custom_step
	fullDef.custom_staticdata = fullDef.get_staticdata or def.custom_staticdata
	fullDef.custom_deactivate = fullDef.on_deactivate or def.on_deactivate
	fullDef.on_activate = nil
	fullDef.on_step = nil
	fullDef.get_staticdata = nil
	fullDef.on_deactivate = nil
	setmetatable(fullDef, fysiks.Rigidbody)
	fullDef.fysiks = true
	fullDef.rigidbody_def = rigidbody_def or {}


	minetest.register_entity(name, fullDef)
end
