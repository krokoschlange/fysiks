Units
=====

For everyone that uses some kind of weird measurement system:
All values in this engine are meant to be in SI units.

Settings
========

There are various settings that control how the engine behaves. They can be set
directly in the game and are documented there.

Rigidbodies
===========

A rigidbody entity can be registered with

`fysiks.register_rigidbody(name, def, rigidbody_def)`

* `name` is the name of the entity, same as with minetest.register_entity
* `def` is the entity definition, same as with minetest.register_entity
* `rigidbody_def` is the rigidbody definition, see below

Within def the normal minetest entity functions can be implemented,
like on_step, on_activate etc.

Please do not use `self.object:set_position()` and other movement related functions.
Set the variables `self.position`, `self.velocity`, `self.rotation` (a matrix) and
`self.angularVelocity` instead.

Additionally there is `self:applyForce(force, point)` where `force` is a force vector
and `point` is a point relative to the object (but not in local space) that
represents the point where the force acts.

Rigidbody Definition
--------------------

The rigidbody definition is a table of the following format
, all items are optional

```lua
rigidbody_def = {
	mass = 1, --mass of the object, default 1
	inertiaTensor = Matrix:new({
		{2 / 12, 0, 0},
		{0, 2 / 12, 0},
		{0, 0, 2 / 12},
	}), --the inertia tensor of the object, defaults to the shown matrix
		--which is the inertia tensor of a cube with side length 1 and mass 1
	collisionBoxes = {{type = fysiks.Cuboid, args = {{x = -0.5, y = -0.5, z = -0.5}, {x = 0.5, y = 0.5, z = 0.5}}}},
	--a list of collisionbox definitions, see below for details, defaults to {}
	bounciness = 0, --the bounciness of the object, defaults to 0
	friction = 0, --the friction coefficient of the object, defaults to 0
}
```

Collisionbox Definition
-----------------------

A collisionbox can be defined using its type and the arguments for its
constructor. Currently there are the usable types:

* `fysiks.Sphere`, a sphere
Arguments:

```lua
radius -- the radius of the sphere
```

Example of a definition:
```lua
{type = fysiks.Sphere, args = {1}} --Sphere with radius 1
```

* `fysiks.Cuboid`, a cuboid
Arguments:

```lua
min, max	--same as with the entity collisionbox these are two opposing
			--corners on a cuboid
```

Example of a definition:

```lua
{type = fysiks.Cuboid, args = {{x = -0.5, y = -0.5, z = -0.5}, {x = 0.5, y = 0.5, z = 0.5}}}
--cube with side length 1
```

* `fysiks.FullPolyhedron`, any convex polyhedron

```lua
verts, edges, faces -- verts is a list of vectors (vertices)
-- edges is a list of pairs of indexes pointing to vertices from verts
-- faces is a list of lists of indexes pointing to vertices from verts
```

Example (taken from Cuboid.lua):

```lua
verts = {
	{x = min.x, y = min.y, z = min.z},
	{x = min.x, y = min.y, z = max.z},
	{x = min.x, y = max.y, z = min.z},
	{x = min.x, y = max.y, z = max.z},
	{x = max.x, y = min.y, z = min.z},
	{x = max.x, y = min.y, z = max.z},
	{x = max.x, y = max.y, z = min.z},
	{x = max.x, y = max.y, z = max.z},
}
edges = {
	{1, 2},
	{2, 4},
	{4, 3},
	{3, 1},
	{5, 6},
	{6, 8},
	{8, 7},
	{7, 5},
	{1, 5},
	{2, 6},
	{3, 7},
	{4, 8},
}
faces = {
	{1, 2, 3, 4},
	{1, 2, 5, 6},
	{1, 3, 5, 7},
	{2, 4, 6, 8},
	{3, 4, 7, 8},
	{5, 6, 7, 8},
}
```

As you can see, this gets very messy just for a simple cube

Friction and Bounciness Functions
---------------------------------

The Contact creation mechanism uses the functions `Rigidbody:getFriction(point, normal)`
and `Rigidbody:getBounciness(point, normal)` to get the friction and bounciness
of a rigidbody. By default they only return `friction` and `bounciness` but they
can be overridden to make friction and bounciness depend on the impact point.

To do this set `self.getFriction` or `self.getBounciness` somewhere from within
the entity definition, e.g.:

```lua
on_activate = function(self, staticdata, dtime_s)
	--the actual calculation in this example is nonsense
	self.getFriction = function(point, normal) return vector.dot(point, normal) end
end
```

For both of those functions is `point` the collision point in local space of the
body and `normal` the collision normal in global space.

Normal Entity Feedback
----------------------

Collision Feedback for normal entities (without rotation) can be added by calling
`fysiks.register_entity_as_fysikal(name, def)` where
* `name` is the entity name, e.g `"mod:myentity"`
* `def` is a table with the following format:

```lua
{
	mass = 100, -- the mass of the entity, defaults to 1/0 (infinity) which causes
				-- the object to not respond to collisions
	friction = 0.3, -- friction, defaults to 1
	bounciness = 5, -- bounciness, defaults to 0
}
```

`fysiks.player_properties` is a similar table that can be modified to allow
collision response for players. Example:

```lua
-- a really overweight, slippery and bouncy player
fysiks.player_properties = {
	mass = 300,
	friction = 0,
	bounciness = 3
}
```

Node Properties
---------------

`fysiks.register_node_properties(name, def)` can be used to overwrite physical
properties of nodes.
* `name` is the name of the node, e.g `"mymod:mynode"`
* `def` is a definition table with the following format:

```lua
{
	--ice
	friction = 0,
	bounciness = 0
}
```

Raycasts
--------

Since `minetest.raycast` (obviously) can't detect collisionboxes from this mod
there is `fysiks.raycast`. Unlike `minetest.raycast` it only returns the closest
hit, so its return value is `nil` or a `pointed_thing` (see mintest doc on how
to use that).

Matrices
========

fysiks comes with a simple matrix class, `Matrix`

Create a new matrix with `Matrix:new()`

It can take a table, e.g.:

```lua
{
	{1, 2, 3},
	{4, 5, 6},
	{7, 8, 9}
}
```

or up to three arguments: `height`, `width` and `number`.
This will create a `height`x`width` matrix filled with `number`.

A faster way to create a matrix from a table is to call `Matrix:newCheap(table)`.
However, this does not copy the contents of the table but uses the table itself,
which means you must not change it afterwards.

There is also `Matrix:rotation(euler)` to create a rotation matrix from euler angles,
as well as `Matrix:axisAngle(vec)` to create a rotation matrix from an axis-angle
representation.

`m:height()` and `m:width()` return the height and width of a Matrix `m`.
`m:set(i, j, x)` sets the element at row `i` and column `j` in matrix `m` to `x`.
`m:get(i, j, x)` returns the element at row `i` and column `j` in matrix `m`.

Calculating
-----------

Calculations can be done like they are done with numbers:

```lua
local x = a * b -- matrix product, nil if not possible
local y = a + b -- sum, nil if not possible
local z = a - b -- difference, nil if not possible
```

`m:transpose()` transposes a matrix `m`
`m:transposed()` returns the transpose of `m` but leaves `m` as it is

`m:determinant` returns the determinant of `m` or `0` if `m` is not square

`m:inverse()` returns the inverse of `m` or `nil` if not possible
