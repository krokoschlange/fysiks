Matrix = {
	M = {}
}
Matrix.__index = Matrix

function Matrix:new(m, n, x)
	local o = setmetatable({}, self)
	if (m == nil or type(m) == "number") then
		m = m or 3
		n = n or 3
		x = x or 0
		if m <= 12 then
			o.M = fysiks.createTable[m]()
		else
			o.M = {}
		end
		if false and n <= 12 then
			for i = 1, m do
				o.M[i] = fysiks.createTable[n]()
				for j = 1, n do
					o.M[i][j] = x
				end
			end
		else
			for i = 1, m do
				o.M[i] = {}
				for j = 1, n do
					o.M[i][j] = x
				end
			end
		end
	elseif m.M ~= nil then
		o.M = {}
		for i = 1, #m.M do
			table.insert(o.M, {})
			for j = 1, #m.M[1] do
				table.insert(o.M[i], m.M[i][j])
			end
		end
	else
		o.M = m
	end
	return o
end

function Matrix:newCheap(m)
	local o = setmetatable({}, self)
	o.M = m
	return o
end

function Matrix:rotationX(angle)
	return Matrix:newCheap({
		{1,					0,					 0},
		{0,   math.cos(angle),     math.sin(angle)},
		{0, - math.sin(angle),     math.cos(angle)}
	})
end

function Matrix:rotationY(angle)
	return Matrix:newCheap({
		{ math.cos(angle), 0, - math.sin(angle)},
		{				0, 1,				 0},
		{ math.sin(angle), 0,   math.cos(angle)}
	})
end

function Matrix:rotationZ(angle)
	return Matrix:newCheap({
		{     math.cos(angle),    math.sin(angle), 0},
		{   - math.sin(angle),    math.cos(angle), 0},
		{					0,					0, 1}
	})
end

function Matrix:rotation(angles)
	local mX = self:rotationX(angles.x)
	local mY = self:rotationY(angles.y)
	local mZ = self:rotationZ(angles.z)

	return mY * mX * mZ;
end

function Matrix:axisAngle(vec)
	local nvec = vector.normalize(vec)
	local x = nvec.x
	local y = nvec.y
	local z = nvec.z
	local a = vector.length(vec)
	local c = math.cos(a)
	local s = math.sin(a)
	local ci = 1 - c
	return Matrix:newCheap({
		{x * x * ci + c, x * y * ci - z * s, x * z * ci + y * s},
		{y * x * ci + z * s, y * y * ci + c, y * z * ci - x * s},
		{z * x * ci - y * s, z * y * ci + x * s, z * z * ci + c}
	})
end

function Matrix:toEuler()
	local singular = 1 - math.abs(self.M[2][3]) < 1e-6

	if not singular then
		local x = math.asin(self.M[2][3])
		local y = math.atan2(self.M[1][3] / math.cos(x), self.M[3][3] / math.cos(x))
		local z = math.atan2(self.M[2][1] / math.cos(x), self.M[2][2] / math.cos(x))
		return {x = x, y = -y, z = -z}
	else
		local y = 0
		local x = 0
		local z = 0
		if self.M[2][3] < 0 then
			x = -math.pi / 2
			z = math.atan2(self.M[1][2], self.M[1][1])
		else
			x = math.pi / 2
			z = - math.atan2(self.M[3][1], self.M[3][2])
		end
		return {x = x, y = y, z = -z}
	end
end

function Matrix:height()
	return #self.M
end

function Matrix:width()
	return #self.M[1]
end

function Matrix:get(i, j)
	return self.M[i][j]
end

function Matrix:set(i, j, x)
	self.M[i][j] = x
end

function Matrix:__add(other)
	if self:height() ~= other:height() or self:width() ~= other:width() then
		return nil
	end
	local m = Matrix:new(self:height(), self:width())
	for i = 1, self:height() do
		for j = 1, self:width() do
			m.M[i][j] = self.M[i][j] + other.M[i][j]
		end
	end
	return m
end

function Matrix:__sub(other)
	if self:height() ~= other:height() or self:width() ~= other:width() then
		return nil
	end
	local m = Matrix:new(self:height(), self:width())
	for i = 1, self:height() do
		for j = 1, self:width() do
			m.M[i][j] = self.M[i][j] - other.M[i][j]
		end
	end
	return m
end

function Matrix:__mul(other)
	if type(other) == "table" then
		if self:width() ~= other:height() then
			return nil
		end

		if self:height() == 1 and self:width() == 1 then
			return other * self.M[1][1]
		elseif other:height() == 1 and other:width() == 1 then
			return self * other.M[1][1]
		elseif self:width() == 3 and self:height() == 3 and other:width() == 1 and other:height() == 3 then
			local m = Matrix:new(3, 1, 0)
			for i = 1, 3, 1 do
				local x = 0
				for k = 1, 3, 1 do
					x = x + self.M[i][k] * other.M[k][1]
				end
				m.M[i][1] = x
			end
			return m
		elseif self:width() == 3 and self:height() == 1 and other:width() == 3 and other:height() == 3 then
			local m = Matrix:new(1, 3, 0)
			for j = 1, 3, 1 do
				local x = 0
				for k = 1, 3, 1 do
					x = x + self.M[1][k] * other.M[k][j]
				end
				m.M[1][j] = x
			end
			return m
		else
			local m = Matrix:new(self:height(), other:width())
			for i = 1, self:height() do
				for j = 1, other:width() do
					local elem = 0
					for k = 1, self:width() do
						elem = elem + self.M[i][k] * other.M[k][j]
					end
					m.M[i][j] = elem
				end
			end
			return m
		end
	else
		local m = Matrix:new(self:height(), self:width())
		for i = 1, self:height() do
			for j = 1, self:width() do
				m.M[i][j] = self.M[i][j] * other
			end
		end
		return m
	end
end

function Matrix:transpose()
	local newM = {}
	for i = 1, self:width() do
		table.insert(newM, {})
		for j = 1, self:height() do
			table.insert(newM[i], self.M[j][i])
		end
	end
	self.M = newM
end

function Matrix:transposed()
	local ret = Matrix:newCheap(self.M)
	ret:transpose()
	return ret
end

function Matrix:submatrix(i, j)
	local sub = Matrix:new(self:height() - 1, self:width() - 1)
	for k = 1, self:height() do
		if k ~= i then
			for l = 1, self:width() do
				if l ~= j then
					local y = 0
					if k < i then
						y = k
					else
						y = k -1
					end

					local x = 0
					if l < j then
						x = l
					else
						x = l - 1
					end
					sub.M[y][x] = self.M[k][l]
				end
			end
		end
	end
	return sub
end

function Matrix:getBlock(i, j, h, w)
	local ret = Matrix:new(h, w)
	for k = 1, h, 1 do
		for l = 1, w, 1 do
			ret.M[k][l] = self.M[i + k - 1][j + l - 1]
		end
	end
	return ret
end

function Matrix:determinant()
	if self:height() ~= self:width() then
		return 0
	end
	local tmp = Matrix:new(self)
	local det = 1
	for i = 1, tmp:width() do
		if tmp.M[i][i] == 0 then
			local solved = false
			for k = i + 1, tmp:height() do
				if tmp.M[k][i] ~= 0 then
					tmp:swapRows(i, k)
					solved = true
					det = det * -1
					break
				end
			end
			if not solved then
				return 0
			end
		end
		for j = i + 1, tmp:height() do
			if tmp.M[j][i] ~= 0 then
				local fac = -tmp.M[i][i] / tmp.M[j][i]
				det = det * (1 / fac)
				tmp:multiplyRow(j, fac)
				tmp:addRows(i, j)
			end
		end
	end
	for i = 1, self:height() do
		det = det * tmp.M[i][i]
	end
	return det
end

function Matrix:multiplyRow(row, x)
	for i = 1, self:width() do
		self.M[row][i] = self.M[row][i] * x
	end
end

--add row1 to row2
function Matrix:addRows(row1, row2)
	for i = 1, self:width() do
		self.M[row2][i] = self.M[row1][i] + self.M[row2][i]
	end
end

function Matrix:swapRows(row1, row2)
	local tmp = self.M[row1]
	self.M[row1] = self.M[row2]
	self.M[row2] = tmp
end

function Matrix:minor(i, j)
	return self:submatrix(i, j):determinant()
end

function Matrix:cofactor(i, j)
	return math.pow(-1, i + j) * self:minor(i, j)
end

function Matrix:inverse()
	if self:width() == 1 and self:height() == 1 then
		return Matrix:new(1, 1, 1 / self.M[1][1])
	end
	local det = self:determinant()
	if det == 0 then
		return nil
	end
	local inv = self:adjugate()
	inv = inv * (1 / det)
	return inv
end

function Matrix:adjugate()
	local adj = Matrix:new(self:height(), self:width())
	for i = 1, self:height() do
		for j = 1, self:width() do
			adj.M[i][j] = self:cofactor(i, j)
		end
	end
	adj:transpose()
	return adj
end

function Matrix:__tostring()
	local str = ""
	for k, v in ipairs(self.M) do
		str = str .. "|"
		for k2, v2 in ipairs(v) do
			local num = tostring(v2)
			while string.len(num) < 10 do
				num = " " .. num
			end
			str = str .. " " .. num
		end
		str = str .. "|\n"
	end
	return str
end
