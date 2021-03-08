
fysiks.register_rigidbody("fysiks:test", {
	hp_max = 10,
	physical = true,
	collide_with_objects = false,
	collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
	collisionBoxes = {},
	visual = "cube",
	visual_size = {x = 1, y = 1},
	textures = {"ignore.png","air.png","heart.png","air.png","unknown_item.png","air.png"},
	is_visible = true,
	makes_footstep_sound = false,
	automatic_rotate = false,

	anchorPoint = nil,
	--rotation,
	--timer = 0,

	custom_activate = function(self, staticdata)
		self.anchorPoint = self.object:get_pos()
		self.anchorPoint.y = self.anchorPoint.y + 1

		--self.rotation = Matrix:rotation({x = 0, y = 0, z = 0})
		--self.timer = 0
	end,

	custom_step = function(self, dtime)
		self:applyForce({x = 0, y = self.mass * -2, z = 0}, {x = 0, y = 0, z = 0})

		--[[self.timer = self.timer + dtime

		if self.timer > math.pi then


			self.timer = -math.pi
		end
		local rot = {x = 0, y = 0, z = 0}
		--rot.x = self.timer
		--rot.y = self.timer
		--rot.z = self.timer
		self.rotation = Matrix:rotation(rot)
		local euler = self.rotation:toEuler()
		self.object:set_rotation(euler)]]

		local p = {x = 0.5, y = 0.5, z = 0.5}

		p = vector.fromMatrix(self.rotation * vector.toMatrix(p))

		local globP = vector.add(p, self.object:get_pos())
		local diff = vector.subtract(self.anchorPoint, globP)

		minetest.add_particle({
			texture = "default_mese_crystal.png",
			pos = globP,
			expirationtime = 0.1,
		})

		minetest.add_particle({
			texture = "ignore.png",
			pos = self.anchorPoint,
			expirationtime = 0.1,
		})
		self.velocity = vector.multiply(self.velocity, 0.99)
		self.angularVelocity = vector.multiply(self.angularVelocity, 0.99)
		local force = vector.length(diff) --.max((vector.length(diff) - 2) * 0.5, 0)
		--print(self.angularVelocity.x, self.angularVelocity.y, self.angularVelocity.z)

		local forceV = vector.multiply(vector.normalize(diff), force)
		self:applyForce(forceV, p)
	end,
})
