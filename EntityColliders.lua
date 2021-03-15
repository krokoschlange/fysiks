fysiks.entitycolliders = {}
fysiks.registered_entities = {}
fysiks.player_properties = {}

function fysiks.updateEntityCollider(k, entity)
	if entity and entity:get_attach() then
		fysiks.entitycolliders[k] = nil
		return
	end

	if not fysiks.entitycolliders[k] then
		if entity:is_player() or (entity:get_luaentity() and entity:get_luaentity().physical and entity:get_luaentity().collide_with_objects) then
			local box = entity:get_properties().collisionbox
			if box and #box >= 6 then
				local body = fysiks.Rigidbody:new()
				body.static = false
				local def = {}
				if entity:is_player() then
					def = fysiks.player_properties
				elseif fysiks.registered_entities[entity:get_luaentity().name] then
					def = fysiks.registered_entities[entity:get_luaentity().name]
				end

				body.mass = def.mass or 1/0
				body.invInertiaTensor = Matrix:new(3, 3)
				body.friction = def.friction or 1
				body.bounciness = def.bounciness or 0


				local xMin = math.min(box[1], box[4])
				local xMax = math.max(box[1], box[4])
				local yMin = math.min(box[2], box[5])
				local yMax = math.max(box[2], box[5])
				local zMin = math.min(box[3], box[6])
				local zMax = math.max(box[3], box[6])
				local coll = fysiks.Cuboid:new(body, {x = xMin, y = yMin, z = zMin}, {x = xMax, y = yMax, z = zMax})
				fysiks.entitycolliders[k] = {coll = coll, body = body}
			end
		end
	end

	local coll = fysiks.entitycolliders[k]
	if coll then
		coll.body.position = entity:get_pos()
		coll.body.velocity = entity:get_velocity()
		coll.body.tmpConstraintVel = Matrix:new({
			{coll.body.velocity.x},
			{coll.body.velocity.y},
			{coll.body.velocity.z},
			{coll.body.angularVelocity.x},
			{coll.body.angularVelocity.y},
			{coll.body.angularVelocity.z},
		})
		coll.coll:setPosition(entity:get_pos())
	end
end

function fysiks.applyConstraintImpulsesToEntity(k, entity)
	local coll = fysiks.entitycolliders[k]
	if coll then
		local oldVel = entity:get_velocity()
		local newVel = coll.body.velocity
		--no idea why but somehow it needs to be multiplied by .5 I believe
		entity:add_velocity(vector.multiply(vector.subtract(newVel, oldVel), 0.5))
	end
end

function fysiks.checkEntityColliders(entities)
	for k, coll in pairs(fysiks.entitycolliders) do
		if not entities[k] or entities[k]:get_attach() then
			fysiks.entitycolliders[k] = nil
		end
	end
end

function fysiks.register_entity_as_fysikal(name, def)
	fysiks.registered_entities[name] = def
end
