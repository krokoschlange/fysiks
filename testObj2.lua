fysiks.register_rigidbody("fysiks:test2", {
	hp_max = 10,
	physical = true,
	collide_with_objects = false,
	collisionbox = {0.2, 0.2, 0.2, -0.2, -0.2, -0.2},
	collisionBoxes = {},
	visual = "cube",
	visual_size = {x = 1, y = 1},
	textures = {"air.png", "air.png", "air.png", "air.png", "air.png", "air.png"},--{"ignore.png","air.png","heart.png","air.png","unknown_item.png","air.png"},
	is_visible = true,
	makes_footstep_sound = false,

	custom_activate = function(self, staticdata)
		local cube = fysiks.Sphere:new(self, 0.5)--fysiks.Cuboid:new(self, {x = -0.5, y = -0.5, z = -0.5}, {x = 0.5, y = 0.5, z = 0.5})
		cube:setPosition(self.object:get_pos())
		table.insert(self.collisionBoxes, cube)
		--[[self.inertiaTensor = Matrix:new({
			{2 / 5 * 0.25, 0, 0},
			{0, 2 / 5 * 0.25, 0},
			{0, 0, 2 / 5 * 0.25}
		})]]
		--self.rotation = Matrix:rotation({x = math.pi / 4, y = math.rad(35.3), z = 0})
		self.bounciness = 0
		self.friction = 1
		self.velocity = {x = 3, y = 0, z = 0}
	end,

	custom_step = function(self, dtime)
		self:applyForce({x = 0, y = -9.81, z = 0}, {x = 0, y = 0, z = 0})


		--[[for k, v in ipairs(self.collisionBoxes[1].vertices) do
			minetest.add_particle({
				pos = v,
				velocity = {x = 0, y = 0, z = 0},
				acceleration = {x = 0, y = 0, z = 0},
				expirationtime = dtime,
				size = 1,
				collisiondetection = false,
				vertical = false,
				glow = 0,
				texture = "default_mese_crystal.png",
			})
		end]]
	end,
})
