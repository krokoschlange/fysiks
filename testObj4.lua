minetest.register_entity("fysiks:test4", {
	hp_max = 10,
	physical = true,
	collide_with_objects = false,
	collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
	visual = "cube",
	visual_size = {x = 1, y = 1},
	textures = {"air.png", "air.png", "air.png", "air.png", "air.png", "air.png"},--{"ignore.png","air.png","heart.png","air.png","unknown_item.png","air.png"},
	is_visible = true,
	makes_footstep_sound = false,
	timer = 0,
	coll = false,

	on_activate = function(self, staticdata)
		self.rot = {x = 0, y = 0, z = 0}
		self.rotd = "x"
		self.timer = 0
	end,

	on_step = function(self, dtime)
		self.rot[self.rotd] = self.rot[self.rotd] + dtime
		self.timer = self.timer + dtime
		if self.timer > 1.5 then
			if self.rotd == "x" then
				self.rotd = "y"
			elseif self.rotd == "y" then
				self.rotd = "z"
			elseif self.rotd == "z" then
				self.rotd = "x"
			end
			self.timer = 0
		end
		self.object:set_rotation(self.rot)
		local rotM = Matrix:rotation(self.rot)
		local vs = {
			{x = 1, y = -1, z = -1},
			{x = 1, y = 1, z = -1},
			{x = 1, y = -1, z = 1},
			{x = 1, y = 1, z = 1},
			{x = -1, y = -1, z = -1},
			{x = -1, y = 1, z = -1},
			{x = -1, y = -1, z = 1},
			{x = -1, y = 1, z = 1},
		}
		for k, v in ipairs(vs) do
			local p = vector.add(vector.fromMatrix(rotM * vector.toMatrix(v) * 0.5), self.object:get_pos())
			minetest.add_particle({
				pos = p,
				velocity = {x = 0, y = 0, z = 0},
				acceleration = {x = 0, y = 0, z = 0},
				expirationtime = dtime,
				size = 1,
				collisiondetection = false,
				vertical = false,
				glow = 0,
				texture = "bubble.png",
			})
		end
	end,

})
