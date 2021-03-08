function vector.toMatrix(v)
	return Matrix:new({{v.x}, {v.y}, {v.z}})
end

function vector.fromMatrix(m)
	return {x = m:get(1, 1), y = m:get(2, 1), z = m:get(3, 1)}
end

function vector.deg(v)
	return {x = math.deg(v.x), y = math.deg(v.y), z = math.deg(v.z)}
end

function vector.rad(v)
	return {x = math.rad(v.x), y = math.rad(v.y), z = math.rad(v.z)}
end

function vector.round(v)
	return {x = math.floor(v.x + 0.5), y = math.floor(v.y + 0.5), z = math.floor(v.z + 0.5)}
end
