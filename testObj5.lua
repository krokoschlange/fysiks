fysiks.register_rigidbody("fysiks:test5", {
	hp_max = 10,
	physical = true,
	--static = true,
	collide_with_objects = false,
	collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
	collisionBoxes = {},
	visual = "cube",
	visual_size = {x = 1, y = 1},
	textures = {"air.png", "air.png", "air.png", "air.png", "air.png", "air.png"},--{"ignore.png","air.png","heart.png","air.png","unknown_item.png","air.png"},
	is_visible = true,
	makes_footstep_sound = false,

	custom_activate = function(self, staticdata)
		--local cube = fysiks.Cuboid:new(self, {x = -1, y = -1, z = -1}, {x = 1, y = 1, z = 1})
	--	cube:setPosition(self.object:get_pos())
	--	table.insert(self.collisionBoxes, cube)
		self.velocity = {x = 1, y = 0, z = 0}
	end,

	custom_step = function(self, dtime)
		self:applyForce({x = 0, y = -9.81, z = 0}, {x = 0, y = 0, z = 0})
	end,
	},
	{
		collisionBoxes = {{type = fysiks.Cuboid, args = {{x = -0.5, y = -0.5, z = -0.5}, {x = 0.5, y = 0.5, z = 0.5}}}},
		friction = 1,
		bounciness = 0
	}
)
