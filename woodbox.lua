fysiks.register_rigidbody("fysiks:woodbox", {
	hp_max = 10,
	physical = true,
	--static = true,
	collide_with_objects = false,
	collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2},
	collisionBoxes = {},
	visual = "cube",
	visual_size = {x = 1, y = 1},
	textures = {"default_wood.png", "default_wood.png", "default_wood.png", "default_wood.png", "default_wood.png", "default_wood.png"},
	is_visible = true,
	makes_footstep_sound = false,

	on_step = function(self, dtime)
		self:applyForce({x = 0, y = -9.81, z = 0}, {x = 0, y = 0, z = 0})
	end,
	},
	{
		collisionBoxes = {{type = fysiks.Cuboid, args = {{x = -0.5, y = -0.5, z = -0.5}, {x = 0.5, y = 0.5, z = 0.5}}}},
		friction = 1,
		bounciness = 0
	}
)
