fysiks.constraints = {}

fysiks.constraintAccuracy = minetest.settings:get("fysiks_constraint_accuracy") or 0.001
fysiks.maxIterations = minetest.settings:get("fysiks_max_constraint_iterations") or 30

function fysiks.solveIslands(dtime)
	for _, const in ipairs(fysiks.constraints) do
		const:initWarmStart()
		const:applyTmpLagMul()
	end
	local requiredAccuracy = fysiks.constraintAccuracy * math.pow(10, -dtime)

	local islands = fysiks.calculateConstraintIslands()

	fysiks.constraints = {}
	for _, island in ipairs(islands) do
		local sendToSleep = true
		for __, body in ipairs(island.bodies) do
			if body.sleepTimer < fysiks.SLEEP_TIME or body.removed then
				sendToSleep = false
				break
			end
		end
		if not sendToSleep then
			for __, body in ipairs(island.bodies) do
				body.asleep = false
			end

			local maxLagMul = 100
			local iterations = 0
			while iterations < fysiks.maxIterations and maxLagMul > requiredAccuracy do
				maxLagMul = -1
				for _, const in ipairs(island.constraints) do
					const:calculateLagMul()
					const:clampLagMult()
					const:applyTmpLagMul()
					local lagMul = const.tmpLagMul
					for i = 1, lagMul:height(), 1 do
						if math.abs(lagMul:get(i, 1)) > maxLagMul then
							maxLagMul = math.abs(lagMul:get(i, 1))
						end
					end
				end
				iterations = iterations + 1
			end
			for _, const in ipairs(island.constraints) do
				const:apply()
				--local lagMultSum = const.lagMultSum
				--[[if const.clampTop then
					for __, v in ipairs(lagMultSum) do
						if math.abs(constv[1] - 0.001) > const.clampTopVal then
							--constraint broke
							--uncomment this when this event causes any kind of functionality
						end
					end
				end]]
			end
		else
			for __, body in ipairs(island.bodies) do
				body:sleep()
			end
			--keep constraints in an undead state
			for __, const in ipairs(island.constraints) do
				table.insert(fysiks.constraints, const)
			end
		end
	end
end

function fysiks.constraintDFS(groupID, adjacent, visited, body, result)
	if body.static then
		visited[body.fysiksID] = groupID
	else
		visited[body.fysiksID] = true
	end
	table.insert(result, body)
	if not body.static then
		for _, neighbour in ipairs(adjacent[body.fysiksID]) do
			local neighbourVisited = visited[neighbour.fysiksID]
			if not neighbourVisited or (neighbourVisited ~= true and neighbourVisited ~= groupID) then
				fysiks.constraintDFS(groupID, adjacent, visited, neighbour, result)
			end
		end
	end
end

function fysiks.calculateConstraintIslands()
	local adj_list = {}
	for _, const in ipairs(fysiks.constraints) do
		local aID = const.bodyA.fysiksID
		local bID = const.bodyB.fysiksID
		if not adj_list[aID] then
			adj_list[aID] = {}
		end
		if not adj_list[bID] then
			adj_list[bID] = {}
		end
		table.insert(adj_list[aID], const.bodyB)
		table.insert(adj_list[bID], const.bodyA)
	end
	local visited = {}
	local groups = {}
	local bodyGroups = {}

	for _, const in ipairs(fysiks.constraints) do
		if not visited[const.bodyA.fysiksID] and not const.bodyA.static then
			local result = {}
			fysiks.constraintDFS(#groups, adj_list, visited, const.bodyA, result)
			local group = {bodies = result, constraints = {}}
			table.insert(groups, group)
			for __, body in ipairs(result) do
				if not bodyGroups[body.fysiksID] then
					bodyGroups[body.fysiksID] = {}
				end
				table.insert(bodyGroups[body.fysiksID], #groups)
			end
		end
		if not visited[const.bodyB.fysiksID] and not const.bodyB.static then
			local result = {}
			fysiks.constraintDFS(#groups, adj_list, visited, const.bodyB, result)
			local group = {bodies = result, constraints = {}}
			table.insert(groups, group)
			for __, body in ipairs(result) do
				if not bodyGroups[body.fysiksID] then
					bodyGroups[body.fysiksID] = {}
				end
				table.insert(bodyGroups[body.fysiksID], #groups)
			end
		end
	end
	for _, const in ipairs(fysiks.constraints) do
		if not const.bodyA.removed and not const.bodyB.removed then
			if not const.bodyA.static then
				for __, group in ipairs(bodyGroups[const.bodyA.fysiksID]) do
					table.insert(groups[group].constraints, const)
				end
			elseif not const.bodyB.static then
				for __, group in ipairs(bodyGroups[const.bodyB.fysiksID]) do
					table.insert(groups[group].constraints, const)
				end
			end
		end
	end
	return groups
end
