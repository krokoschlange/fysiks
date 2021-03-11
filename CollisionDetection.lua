fysiks.collisionPairs = {}
fysiks.constraintIslands = {}

function fysiks.addCollisionPair(a, b, collision)
	local smallerID = a.id
	local biggerID = b.id
	if smallerID > biggerID then
		smallerID = b.id
		biggerID = a.id
	end
	if not fysiks.collisionPairs[smallerID] then
		fysiks.collisionPairs[smallerID] = {}
	end
	if not fysiks.collisionPairs[smallerID][biggerID] then
		if a.on_collision then
			a:on_collision(collision)
		end
		if b.on_collision then
			b:on_collision(collision)
		end
	end
	fysiks.collisionPairs[smallerID][biggerID] = collision
end

function fysiks.getCollisionPair(a, b)
	local smallerID = a.id
	local biggerID = b.id
	if smallerID > biggerID then
		smallerID = b.id
		biggerID = a.id
	end
	if fysiks.collisionPairs[smallerID] then
		return fysiks.collisionPairs[smallerID][biggerID]
	end
	return nil
end

function fysiks.removeCollisionPair(a, b)
	local smallerID = a.id
	local biggerID = b.id
	if smallerID > biggerID then
		smallerID = b.id
		biggerID = a.id
	end
	if fysiks.collisionPairs[smallerID] then
		if not fysiks.collisionPairs[smallerID][biggerID] then
			if a.on_end_collision then
				a:on_end_collision(collision)
			end
			if b.on_end_collision then
				b:on_end_collision(collision)
			end
		end
		fysiks.collisionPairs[smallerID][biggerID] = nil
	end
end

function fysiks.considerCollision(objA, objB)
	if objA.forceCollisionCheck or objB.forceCollisionCheck then
		objA.forceCollisionCheck = false
		objB.forceCollisionCheck = false
		return true
	end
	if objA ~= objB and not ((objA.static or objA.asleep) and (objB.static or objB.asleep)) then
		return true
	end
	return false
end

function fysiks.detectCollisionsAlongAxis(markers)
	local ret = {}

	for keyStart, startMarker in ipairs(markers) do
		if startMarker.isMin then
			local keyEnd = keyStart + 1
			local endMarker = markers[keyEnd]
			while endMarker.aabb ~= startMarker.aabb do
				if fysiks.considerCollision(endMarker.obj, startMarker.obj) then
					local alreadyExists = false
					local coll = {endMarker.aabb, startMarker.aabb}
					for _, pair in ipairs(ret) do
						if (pair[1] == endMarker.aabb and pair[2] == startMarker.aabb) or (pair[2] == endMarker.aabb and pair[1] == startMarker.aabb) then
							alreadyExists = true
							break
						end
					end
					if not alreadyExists then
						table.insert(ret, coll)
					end
				end
				keyEnd = keyEnd + 1
				endMarker = markers[keyEnd]
			end
		end
	end
	return ret
end

function fysiks.broadPhase(volumes)
	local aabbs = {}
	for _, vol in pairs(volumes) do
		table.insert(aabbs, vol:getAABB())
	end

	local x = {}
	local y = {}
	local z = {}

	for _, aabb in pairs(aabbs) do
		local xvals = aabb:getXValues()
		local yvals = aabb:getYValues()
		local zvals = aabb:getZValues()
		local rigidbody = aabb.boundingVolume.object
		table.insert(x, {aabb = aabb, obj = rigidbody, val = xvals.min, isMin = true})
		table.insert(x, {aabb = aabb, obj = rigidbody, val = xvals.max, isMin = false})
		table.insert(y, {aabb = aabb, obj = rigidbody, val = yvals.min, isMin = true})
		table.insert(y, {aabb = aabb, obj = rigidbody, val = yvals.max, isMin = false})
		table.insert(z, {aabb = aabb, obj = rigidbody, val = zvals.min, isMin = true})
		table.insert(z, {aabb = aabb, obj = rigidbody, val = zvals.max, isMin = false})
	end

	--naturalMergeSort(x, function(a, b) return a.val < b.val end)
	--naturalMergeSort(y, function(a, b) return a.val < b.val end)
	--naturalMergeSort(z, function(a, b) return a.val < b.val end)
	table.sort(x, function(a, b) return a.val < b.val end)
	table.sort(y, function(a, b) return a.val < b.val end)
	table.sort(z, function(a, b) return a.val < b.val end)

	local collX = fysiks.detectCollisionsAlongAxis(x)
	local collY = fysiks.detectCollisionsAlongAxis(y)
	local collZ = fysiks.detectCollisionsAlongAxis(z)


	local coll = {}

	for _, vx in ipairs(collX) do
		for __, vy in ipairs(collY) do
			if ((vx[1] == vy[1] and vx[2] == vy[2]) or (vx[1] == vy[2] and vx[2] == vy[1])) then
				for ___, vz in ipairs(collZ) do
					if ((vx[1] == vz[1] and vx[2] == vz[2]) or (vx[1] == vz[2] and vx[2] == vz[1])) then
						table.insert(coll, vx)
					end
				end
			end
		end
	end
	return coll
end

function fysiks.minkowskiSupport(a, b, dir)
	local a, ai = a:getFurthestPointInDirection(dir)
	local b, bi = b:getFurthestPointInDirection(vector.multiply(dir, -1))
	return vector.subtract(a, b), {ai, bi}
end

function fysiks.GJK(a, b)
	local simplex = {}
	local pointIdx = {}
	local dir = {x = 1, y = 0, z = 0}
	local newPoint, idx = fysiks.minkowskiSupport(a, b, dir)
	table.insert(simplex, newPoint)
	table.insert(pointIdx, idx)
	dir = vector.multiply(newPoint, -1)
	newPoint, idx = fysiks.minkowskiSupport(a, b, dir)
	table.insert(simplex, newPoint)
	table.insert(pointIdx, idx)
	local lineDirNorm = vector.normalize(vector.subtract(newPoint, simplex[1]))
	local newPointToO = vector.multiply(newPoint, -1)
	dir = vector.subtract(newPointToO, vector.multiply(lineDirNorm, vector.dot(lineDirNorm, newPointToO)))
	dir = vector.normalize(dir)
	newPoint, idx = fysiks.minkowskiSupport(a, b, dir)
	table.insert(simplex, newPoint)
	table.insert(pointIdx, idx)

	for i = 0, 100, 1 do
		local faceNorm = vector.cross(vector.subtract(simplex[2], simplex[1]), vector.subtract(simplex[3], simplex[1]))
		if vector.dot(faceNorm, simplex[1]) < 0 then
			dir = faceNorm
		else
			dir = vector.multiply(faceNorm, -1)
		end
		newPoint, idx = fysiks.minkowskiSupport(a, b, dir)

		table.insert(simplex, newPoint)
		table.insert(pointIdx, idx)
		if vector.dot(newPoint, dir) <= 0 then
			return false
		end

		faceNorm = vector.cross(vector.subtract(simplex[1], simplex[2]), vector.subtract(simplex[1], simplex[3]))
		if (vector.dot(faceNorm, simplex[4]) >= 0) ~= (vector.dot(faceNorm, vector.multiply(simplex[1], -1)) >= 0) then
			table.remove(simplex, 4)
			table.remove(pointIdx, 4)
		else
			faceNorm = vector.cross(vector.subtract(simplex[1], simplex[2]), vector.subtract(simplex[1], simplex[4]))
			if (vector.dot(faceNorm, simplex[3]) >= 0) ~= (vector.dot(faceNorm, vector.multiply(simplex[1], -1)) >= 0) then
				table.remove(simplex, 3)
				table.remove(pointIdx, 3)
			else
				faceNorm = vector.cross(vector.subtract(simplex[1], simplex[3]), vector.subtract(simplex[1], simplex[4]))
				if (vector.dot(faceNorm, simplex[2]) >= 0) ~= (vector.dot(faceNorm, vector.multiply(simplex[1], -1)) >= 0) then
					table.remove(simplex, 2)
					table.remove(pointIdx, 2)
				else
					faceNorm = vector.cross(vector.subtract(simplex[2], simplex[3]), vector.subtract(simplex[2], simplex[4]))
					if (vector.dot(faceNorm, simplex[1]) >= 0) ~= (vector.dot(faceNorm, vector.multiply(simplex[2], -1)) >= 0) then
						table.remove(simplex, 1)
						table.remove(pointIdx, 1)
					else
						return true, simplex, pointIdx
					end
				end
			end
		end
	end
	return false
end

function fysiks.EPA(a, b, simplex, pointIdx)
	local faceData = {{1, 2, 3}, {1, 3, 4}, {1, 2, 4}, {2, 3, 4}}
	local polyhedron = fysiks.FacedPolyhedron:new(nil, simplex, faceData)

	local collNormal = nil
	local alreadyFound = false
	local iterations = 0
	local faceIdx = 0
	while not alreadyFound do
		local closestFaceIdx, normal = polyhedron:findClosestFace({x = 0, y = 0, z = 0})
		local closestFace = polyhedron.faces[closestFaceIdx]
		local relPos = vector.subtract(polyhedron.vertices[closestFace[1]], polyhedron.center)
		if vector.dot(normal, relPos) < 0 then
			normal = vector.multiply(normal, -1)
		end
		local nnormal = vector.normalize(normal)
		local newPoint, idx = fysiks.minkowskiSupport(a, b, nnormal)

		--[[for _, point in ipairs(closestFace) do
			local vert = polyhedron.vertices[point]
			if vector.length(vector.subtract(newPoint, vert)) < 0.05 then
				alreadyFound = true
			end
		end]]
		for _, face in ipairs(polyhedron.faces) do
			local tang1 = vector.subtract(polyhedron.vertices[face[2]], polyhedron.vertices[face[1]])
			local tang2 = vector.subtract(polyhedron.vertices[face[3]], polyhedron.vertices[face[1]])
			local fnormal = vector.normalize(vector.cross(tang1, tang2))
			local relPos = vector.subtract(polyhedron.vertices[face[1]], polyhedron.center)
			if vector.dot(fnormal, relPos) < 0 then
				fnormal = vector.multiply(fnormal, -1)
			end
			if vector.dot(fnormal, nnormal) > 0.95 then
				for __, point in ipairs(face) do
					local vert = polyhedron.vertices[point]
					if vector.length(vector.subtract(newPoint, vert)) < 0.05 then
						alreadyFound = true
					end
				end
			end
		end

		iterations = iterations + 1
		if iterations > 100 then
			--abort, we're probably close enough
			alreadyFound = true
		end

		if not alreadyFound then
			polyhedron:addVertex(newPoint)
			table.insert(pointIdx, idx)
		else
			collNormal = normal
			faceIdx = closestFaceIdx
		end
	end
	return collNormal, polyhedron, pointIdx, faceIdx
end

function fysiks.polyhedronVSPolyhedron(a, b, normal, facingB)
	local nnormal = vector.normalize(normal)
	local anormal = nnormal
	local bnormal = nnormal
	if facingB then
		bnormal = vector.multiply(bnormal, -1)
	else
		anormal = vector.multiply(anormal, -1)
	end

	local faceNormalsA = {}
	local bestA = 0
	local bestADot = 0
	for i, face in ipairs(a.faces) do
		local v1 = vector.subtract(a.vertices[face[2]], a.vertices[face[1]])
		local v2 = vector.subtract(a.vertices[face[3]], a.vertices[face[1]])
		local fnormal = vector.normalize(vector.cross(v1, v2))
		if vector.dot(fnormal, vector.subtract(a.vertices[face[1]], a.center)) < 0 then
			fnormal = vector.multiply(fnormal , -1)
		end
		table.insert(faceNormalsA, fnormal)
		local dot = vector.dot(anormal, fnormal)
		if dot > bestADot then
			bestADot = dot
			bestA = i
		end
	end
	local faceNormalsB = {}
	local bestB = 0
	local bestBDot = 0
	for i, face in ipairs(b.faces) do
		local v1 = vector.subtract(b.vertices[face[2]], b.vertices[face[1]])
		local v2 = vector.subtract(b.vertices[face[3]], b.vertices[face[1]])
		local fnormal = vector.normalize(vector.cross(v1, v2))
		if vector.dot(fnormal, vector.subtract(b.vertices[face[1]], b.center)) < 0 then
			fnormal = vector.multiply(fnormal , -1)
		end
		table.insert(faceNormalsB, fnormal)

		local dot = vector.dot(bnormal, fnormal)
		if dot > bestBDot then
			bestBDot = dot
			bestB = i
		end
	end
	local better = a
	local betterFace = bestA
	local betterFaceNormals = faceNormalsA
	local betterNormal = anormal
	local worse = b
	if bestBDot > bestADot then
		better = b
		betterFace = bestB
		betterFaceNormals = faceNormalsB
		betterNormal = bnormal
		worse = a
	end

	better:calculateNeighbors()
	local clippingFaces = better.neighbors[betterFace]
	local clipped = worse
	for _, face in ipairs(clippingFaces) do
		clipped = clipped:clip(better.vertices[better.faces[face][1]], betterFaceNormals[face], false)
	end

	local worseContacts = clipped:clip(better.vertices[better.faces[betterFace][1]], betterFaceNormals[betterFace], true)
	local betterContacts = {}
	for _, p in ipairs(worseContacts) do
		local depth = vector.dot(vector.subtract(better.vertices[better.faces[betterFace][1]], p), betterFaceNormals[betterFace])
		if depth - vector.length(normal) < 0.01 then
			table.insert(betterContacts, vector.add(p, vector.multiply(betterFaceNormals[betterFace], depth)))
		else
			table.insert(betterContacts, false)
		end
	end

	local aContacts = worseContacts
	local bContacts = betterContacts
	if bestBDot < bestADot then
		aContacts = betterContacts
		bContacts = worseContacts
	end
	return aContacts, bContacts
end

function fysiks.singlePolyVSPoly(aV, bV, normal, epaPoly, epaFace, pointIdx)
	local face = epaPoly.faces[epaFace]
	local a = epaPoly.vertices[face[1]]
	local b = epaPoly.vertices[face[2]]
	local c = epaPoly.vertices[face[3]]
	local p = normal

	local v0 = vector.subtract(b, a)
	local v1 = vector.subtract(c, a)
	local v2 = vector.subtract(p, a)
	local d00 = vector.dot(v0, v0)
	local d01 = vector.dot(v0, v1)
	local d11 = vector.dot(v1, v1)
	local d20 = vector.dot(v2, v0)
	local d21 = vector.dot(v2, v1)
	local denom = d00 * d11 - d01 * d01
	local v = (d11 * d20 - d01 * d21) / denom
	local w = (d00 * d21 - d01 * d20) / denom
	local u = 1 - w - v

	local aA = aV.vertices[pointIdx[face[1]][1]]
	local bA = aV.vertices[pointIdx[face[2]][1]]
	local cA = aV.vertices[pointIdx[face[3]][1]]

	local aB = bV.vertices[pointIdx[face[1]][2]]
	local bB = bV.vertices[pointIdx[face[2]][2]]
	local cB = bV.vertices[pointIdx[face[3]][2]]

	local xa = u * aA.x + v * bA.x + w * cA.x
	local ya = u * aA.y + v * bA.y + w * cA.y
	local za = u * aA.z + v * bA.z + w * cA.z

	local xb = u * aB.x + v * bB.x + w * cB.x
	local yb = u * aB.y + v * bB.y + w * cB.y
	local zb = u * aB.z + v * bB.z + w * cB.z

	local a = {x = xa, y = ya, z = za}
	local b = {x = xb, y = yb, z = zb}
	return {a}, {b}
end

function fysiks.polyhedronVSSphere(polyhedron, sphere, normal, facingSphere)
	local vectorToPolyhedron = vector.normalize(normal)
	if facingSphere then
		vectorToPolyhedron = vector.multiply(vectorToPolyhedron, -1)
	end
	local contactRadius = sphere.radius - vector.length(normal)
	local sphereContact = {vector.add(sphere.position, vector.multiply(vectorToPolyhedron, sphere.radius))}
	local polyhedronContact = {vector.add(sphere.position, vector.multiply(vectorToPolyhedron, contactRadius))}
	return polyhedronContact, sphereContact
end

function fysiks.polyhedronVSCylinder(polyhedron, cylinder, normal, facingCylinder)
	--TODO
end

function fysiks.sphereVSSphere(a, b, normal, facingB)
	local aToB = vector.normalize(vector.subtract(b.position, a.position))

	return {vector.add(a.position, vector.multiply(aToB, a.radius))}, {vector.add(b.position, vector.multiply(aToB, -b.radius))}
end

function fysiks.sphereVSCylinder(sphere, cylinder, normal, facingCylinder)
	--TODO
end

function fysiks.cylinderVSCylinder(a, b, normal, facingB)
	--TODO
end

function fysiks.createContacts(a, b, normal, epaPoly, epaFace, pointIdx, oneshot)
	if a.type == "polyhedron" and b.type == "polyhedron" then
		if oneshot then
			return fysiks.polyhedronVSPolyhedron(a, b, normal, true)
		else
			return fysiks.singlePolyVSPoly(a, b, normal, epaPoly, epaFace, pointIdx)
		end
	elseif a.type == "polyhedron" and b.type == "sphere" then
		return fysiks.polyhedronVSSphere(a, b, normal, true)
	elseif a.type == "sphere" and b.type == "polyhedron" then
		local cb, ca = fysiks.polyhedronVSSphere(b, a, normal, false)
		return ca, cb
	elseif a.type == "sphere" and b.type == "sphere" then
		return fysiks.sphereVSSphere(a, b, normal)
	else
		return {}
	end
end

function fysiks.closestPointInTriangle(a, b, c, p)
	local ab = vector.subtract(b, a)
	local bc = vector.subtract(c, b)
	local prab = vector.dot(vector.subtract(p, a), ab) / (vector.dot(ab, ab))
	local prbc = vector.dot(vector.subtract(p, b), bc) / (vector.dot(bc, bc))

	if prab > 1 and prbc < 0 then
		return b
	end
	local ca = vector.subtract(a, c)
	local prca = vector.dot(vector.subtract(p, c), ca) / (vector.dot(ca, ca))

	if prca > 1 and prab < 0 then
		return a
	end

	if prbc > 1 and prca < 0 then
		return c
	end

	local n = vector.cross(ab, bc)
	local nab = vector.cross(ab, n)
	local ap = vector.subtract(p, a)
	if prab > 0 and prab < 1 and (vector.dot(nab, ap) > 0) == (vector.dot(nab, ca) > 0) then
		return vector.add(a, vector.multiply(ab, prab))
	end
	local nbc = vector.cross(bc, n)
	local bp = vector.subtract(p, b)
	if prbc > 0 and prbc < 1 and (vector.dot(nbc, bp) > 0) == (vector.dot(nbc, ab) > 0) then
		return vector.add(b, vector.multiply(bc, prbc))
	end
	local nca = vector.cross(ca, n)
	if prca > 0 and prca < 1 and (vector.dot(nca, ap) > 0) == (vector.dot(nca, bc) > 0) then
		return vector.add(c, vector.multiply(ca, prca))
	end

	return vector.add(p, vector.multiply(n, -vector.dot(ap, n) / vector.dot(n, n)))
end

function fysiks.narrowPhase(aabbPairs, dtime)
	for _, aabbPair in ipairs(aabbPairs) do
		local boundingVolume1 = aabbPair[1].boundingVolume
		local boundingVolume2 = aabbPair[2].boundingVolume
		local coll, simplex, pointIdx = fysiks.GJK(boundingVolume1, boundingVolume2)
		if coll then
			local normal, epaPoly, pointIdx, epaFace = fysiks.EPA(boundingVolume1, boundingVolume2, simplex, pointIdx)
			local objA = boundingVolume1.object
			local objB = boundingVolume2.object
			local collisionPair = fysiks.getCollisionPair(boundingVolume1, boundingVolume2)
			local pairInvalid = false
			if collisionPair then
				for _, contact in ipairs(collisionPair.contacts) do
					if contact:isValid() then
						contact:recalculate(dtime)
					else
						pairInvalid = true
					end
				end
			end

			local oneshot = (collisionPair == nil) or pairInvalid
			if oneshot and collisionPair then
				collisionPair.contactRemovedSinceLastOneshot = false
			end
			local contacts1, contacts2 = fysiks.createContacts(boundingVolume1, boundingVolume2, normal, epaPoly, epaFace, pointIdx, oneshot)
			local nnormal = vector.normalize(normal)
			local contacts = {}
			for i = 1, #contacts1, 1 do
				if i <= # contacts2 and contacts1[i] and contacts2[i] then
					table.insert(contacts, fysiks.Contact:new(objA, objB, contacts1[i], contacts2[i], nnormal, dtime))
				end
			end
			--table.sort(contacts, function(a, b) return a.depth < b.depth end)
			--TODO: dont make pairs of bodies, use colliders instead
			if collisionPair == nil or oneshot then
				collisionPair = {
					a = objA,
					b = objB,
					collA = boundingVolume1,
					collB = boundingVolume2,
					contacts = contacts,
					currentStep = true,
					contactRemovedSinceLastOneshot = false
				}
				fysiks.addCollisionPair(boundingVolume1, boundingVolume2, collisionPair)
			else
				collisionPair.currentStep = true
				local newContact = contacts[1]
				local newContacts = collisionPair.contacts
				local double = false
				for _, contact in ipairs(collisionPair.contacts) do
					if contact:isSimilar(newContact) then
						double = true
					end
				end
				if not double then
					table.insert(newContacts, newContact)
				end
				if #newContacts > 4 then
					local deepest = nil
					local pen = nil
					for _, contact in ipairs(newContacts) do
						if pen == nil or contact.depth > pen then
							pen = contact.depth
							deepest = contact
						end
					end
					local furthest1 = nil
					local dist1 = nil
					for _, contact in ipairs(newContacts) do
						local dist = vector.length(vector.subtract(contact.aPoint, deepest.aPoint))
						if dist1 == nil or dist > dist1 then
							dist1 = dist
							furthest1 = contact
						end
					end
					local furthest2 = nil
					local dist2 = nil
					local d = vector.normalize(vector.subtract(deepest.aPoint, furthest1.aPoint))
					for _, contact in ipairs(newContacts) do
						local v = vector.subtract(contact.aPoint, furthest1.aPoint)
						local dist = vector.length(vector.subtract(contact.aPoint, vector.add(furthest1.aPoint, vector.multiply(d, vector.dot(v, d)))))
						if dist2 == nil or dist > dist2 then
							dist2 = dist
							furthest2 = contact
						end
					end
					local furthest3 = nil
					local dist3 = nil
					local d = vector.normalize(vector.subtract(deepest.aPoint, furthest1.aPoint))
					for _, contact in ipairs(newContacts) do
						local dist = vector.distance(fysiks.closestPointInTriangle(deepest.aPoint, furthest1.aPoint, furthest2.aPoint, contact.aPoint), contact.aPoint)
						if dist3 == nil or dist > dist3 then
							dist3 = dist
							furthest3 = contact
						end
					end
					collisionPair.contacts = {deepest, furthest1, furthest2}
					if dist3 > 0 then
						table.insert(collisionPair.contacts, furthest3)
					end
				else
					collisionPair.contacts = newContacts
				end
			end
			for _, v in ipairs(collisionPair.contacts) do
				v:addConstraints()
			end
		end
	end
end

function fysiks.nodeCollisions(volume, dtime)
	local aabb = volume:getAABB()
	local min = vector.round(aabb.minimum)
	local max = vector.round(aabb.maximum)

	local colliders = fysiks.getBlockColliders(min, max)
	table.insert(colliders, volume)
	local pairs = fysiks.broadPhase(colliders)
	fysiks.narrowPhase(pairs, dtime)
end

function fysiks.detectCollisions(dtime)
	for _, a in pairs(fysiks.collisionPairs) do
		for _, pair in pairs(a) do
			if pair.a.asleep and pair.b.asleep then
				pair.currentStep = true
			else
				pair.currentStep = false
			end
		end
	end

	local allObjs = minetest.object_refs
	local boundingVolumes = {}
	local entities
	for k, obj in pairs(allObjs) do
		if obj:get_luaentity() and obj:get_luaentity().fysiks then
			obj:get_luaentity():prepareStep(dtime)
			if obj:get_luaentity().collisionBoxes then
				for __, collbox in pairs(obj:get_luaentity().collisionBoxes) do
					table.insert(boundingVolumes, collbox)
					if not obj.static then
						fysiks.nodeCollisions(collbox, dtime)
					end
				end
			end
		else
			fysiks.updateEntityCollider(k, obj)
			if fysiks.entitycolliders[k] then
				table.insert(boundingVolumes, fysiks.entitycolliders[k].coll)
			end
		end
	end

	fysiks.checkEntityColliders(allObjs)

	local aabbPairs = fysiks.broadPhase(boundingVolumes)

	fysiks.narrowPhase(aabbPairs, dtime)

	for _, a in pairs(fysiks.collisionPairs) do
		for _, pair in pairs(a) do
			if not pair.currentStep or pair.collA.removed or pair.collB.removed then
				fysiks.removeCollisionPair(pair.collA, pair.collB)
			end
		end
	end

	fysiks.solveIslands(dtime)

	for _, obj in pairs(allObjs) do
		if obj:get_luaentity() and obj:get_luaentity().fysiks then
			obj:get_luaentity():finishStep(dtime)
		end
	end

	fysiks.handleUpdatedBlockColliders()
end


minetest.register_globalstep(fysiks.detectCollisions)

minetest.register_on_placenode(function(pos, newnode, place, oldnode, itemstack, pointed_thing)
	fysiks.updateBlockCollider(fysiks.getBlockPos(pos), false)
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
	fysiks.updateBlockCollider(fysiks.getBlockPos(pos), false)
end)

function fysiks.raycast(pos1, pos2, exclude)
	local mtRay = minetest.raycast(pos1, pos2)
	local closest_pointed_thing = nil
	local mt_pointed_thing = mtRay:next()
	while mt_pointed_thing do
		mt_pointed_thing.distance = vector.distance(pos1, mt_pointed_thing.intersection_point)
		if mt_pointed_thing.type == "node" then
			local node = minetest.get_node(mt_pointed_thing.under)
			local nodeDef = minetest.registered_nodes[node.name]
			local drawtype = nodeDef.drawtype
			if drawtype ~= "plantlike" then
				closest_pointed_thing = mt_pointed_thing
				break
			end
		elseif mt_pointed_thing.type == "object" and not mt_pointed_thing.ref:get_luaentity().fysiks then
			local ignore = false
			if exclude then
				for __, ex in ipairs(exclude) do
					if ex == mt.pointed_thing.ref:get_luaentity() then
						ignore = true
					end
				end
			end
			if not ignore then
				closest_pointed_thing = mt_pointed_thing
				break
			end
		end
		mt_pointed_thing = mtRay:next()
	end

	local allObjs = minetest.object_refs
	local dir = vector.direction(pos1, pos2)
	local dir_inv = {x = 1 / dir.x, y = 1 / dir.y, z = 1 / dir.z}
	local dist = vector.distance(pos1, pos2)
	for _, obj in pairs(allObjs) do
		if obj:get_luaentity() and obj:get_luaentity().fysiks then
			local body = obj:get_luaentity()
			local ignore = false
			if exclude then
				for __, ex in ipairs(exclude) do
					if ex == body then
						ignore = true
					end
				end
			end
			if not ignore then
				for __, vol in ipairs(body.collisionBoxes) do
					local pointed_thing = vol:intersectRay(pos1, dir, dir_inv, dist)
					if pointed_thing and (not closest_pointed_thing or
							pointed_thing.distance < closest_pointed_thing.distance) then
						closest_pointed_thing = pointed_thing
					end
				end
			end
		end
	end
	return closest_pointed_thing
end

function fysiks.raycast_smooth(pos1, pos2, exclude)
	local pointed_thing = fysiks.raycast(pos1, pos2, exclude)
	if not pointed_thing or pointed_thing.type ~= "node" then
		return pointed_thing
	end

	local pos = pointed_thing.under
	if not fysiks.getBlockCollider(pos):getNode(pos) then
		return pointed_thing
	end
	local relPoint = vector.subtract(pointed_thing.intersection_point, pos)
	local n = pointed_thing.intersection_normal
	local t1 = 0
	local t1Dir = nil
	local t2 = 0
	local t2Dir = nil
	if math.abs(n.x) > 0.5 then
		t1 = math.abs(relPoint.y) * 2
		t1Dir = {x = 0, y = math.sign(relPoint.y), z = 0}
		t2 = math.abs(relPoint.z) * 2
		t2Dir = {x = 0, y = 0, z = math.sign(relPoint.z)}
	elseif math.abs(n.y) > 0.5 then
		t1 = math.abs(relPoint.x) * 2
		t1Dir = {x = math.sign(relPoint.x), y = 0, z = 0}
		t2 = math.abs(relPoint.z) * 2
		t2Dir = {x = 0, y = 0, z = math.sign(relPoint.z)}
	else
		t1 = math.abs(relPoint.x) * 2
		t1Dir = {x = math.sign(relPoint.x), y = 0, z = 0}
		t2 = math.abs(relPoint.y) * 2
		t2Dir = {x = 0, y = math.sign(relPoint.y), z = 0}
	end

	local t1H = 1
	local t2H = 1
	local t3H = 1

	local searchPos = vector.add(pos, vector.add(n, t1Dir))
	if not fysiks.getBlockCollider(searchPos):getNode(searchPos) then
		t1H = 0
	end
	searchPos = vector.add(pos, t1Dir)
	if t1H == 0 and not fysiks.getBlockCollider(searchPos):getNode(searchPos) then
		t1H = -1
	end
	searchPos = vector.add(pos, vector.add(n, t2Dir))
	if not fysiks.getBlockCollider(searchPos):getNode(searchPos) then
		t2H = 0
	end
	searchPos = vector.add(pos, t2Dir)
	if t2H == 0 and not fysiks.getBlockCollider(searchPos):getNode(searchPos) then
		t2H = -1
	end
	searchPos = vector.add(pos, vector.add(n, vector.add(t1Dir, t2Dir)))
	if not fysiks.getBlockCollider(searchPos):getNode(searchPos) then
		t3H = 0
	end
	searchPos = vector.add(pos, vector.add(t1Dir, t2Dir))
	if t3H == 0 and (t1H < 0 or t2H < 0 or not fysiks.getBlockCollider(searchPos):getNode(searchPos)) then
		t3H = -1
	end

	local t1m = 0
	local t2m = 0

	if t1 > t2 then
		t1m = t1H
		t2m = t3H
	else
		t1m = t3H
		t2m = t2H
	end

	t1m = t1m / 4
	t2m = t2m / 4

	local dir = vector.direction(pos2, pos1)
	local v1 = vector.dot(dir, t1Dir)
	local v2 = vector.dot(dir, t2Dir)
	local v3 = vector.dot(dir, n)
	local v = {x = v1, y = v2, z = v3}
	v = vector.multiply(v, 1 / vector.dot(v, {x = 0, y = 0, z = 1}))

	local height = (-t1m * t1 - t2m * t2) / (t1m * v.x + t2m * v.y - 1)

	local t1i = (t1 / 2 + v.x * height)
	local t2i = (t2 / 2 + v.y * height)
	local p = vector.add(vector.multiply(t1Dir, t1i), vector.add(vector.multiply(t2Dir, t2i), vector.multiply(n, 0.5 + height)))

	pointed_thing.intersection_point = vector.add(pos, p)
	return pointed_thing
end
