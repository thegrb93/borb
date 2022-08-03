local util = {}

function util.newPDController(body, pgain, dgain)
	local mass, inertia = body:getMass(), body:getInertia()
	local dgain = dgain or math.sqrt(pgain)*2
	return function(dx, dy, da, ddx, ddy, dda)
		body:applyForce((dx*pgain + ddx*dgain)*mass, (dy*pgain + ddy*dgain)*mass)
		body:applyTorque((da*pgain + dda*dgain)*inertia)
	end
end

function util.rungeKutta(x, y, a, dx, dy, da)
	local dt = world.dt
	return
		function(x_, y_, a_, dx_, dy_, da_)
			x, y, a, dx, dy, da = x_, y_, a_, dx_, dy_, da_
		end,
		function()
			return x, y, a, dx, dy, da
		end,
		function(fx, fy, fa)
			dx = dx + fx*dt
			dy = dy + fy*dt
			da = da + fa*dt
			x = x + dx*dt
			y = y + dy*dt
			a = a + da*dt
			return x, y, a, dx, dy, da
		end
end

function util.binarySearch(xmin, xmax, iter, func)
	local size = (xmax - xmin)*0.5
	xmin = xmin + size
	for i=1, iter do
		local val = func(xmin)
		size = size * 0.5
		if val then
			xmin = xmin + size
		else
			xmin = xmin - size
		end
	end
	return xmin
end

function util.traceLine(x1, y1, x2, y2, filter)
	if filter==nil then filter = function() return true end end
	local fixture, x, y, xn, yn, fraction
	world.physworld.box2d_world:rayCast(x1, y1, x2, y2, function(fixture_, x_, y_, xn_, yn_, fraction_)
		if filter(fixture_) then
			fixture, x, y, xn, yn, fraction = fixture_, x_, y_, xn_, yn_, fraction_
			return 0
		end
		return -1
	end)
	return fixture, x, y, xn, yn, fraction
end

local beamMesh = love.graphics.newMesh(4)
function util.drawBeam(x1, y1, x2, y2, u1, v1, u2, v2, width, texture)
	local tx, ty = math.normalizeVec(math.rotVecCCW(x2 - x1, y2 - y1))
	width = width * 0.5
	tx = tx * width
	ty = ty * width
	beamMesh:setVertices({{x1 + tx, y1 + ty, u1, v1}, {x2 + tx, y2 + ty, u2, v1}, {x2 - tx, y2 - ty, u2, v2}, {x1 - tx, y1 - ty, u1, v2}})
	beamMesh:setTexture(texture)
	love.graphics.draw(beamMesh)
end

function util.loadTypes()
	types = {}
	local types = types
	local typesToCreate = {}
	local typesToInit = {}
	function addType(name, basetype, func)
		typesToCreate[name] = {basetype = basetype, func = func}
	end
	for k, v in ipairs(love.filesystem.getDirectoryItems("types")) do
		local n = string.match(v, "^(.-)%.lua$")
		require("types/"..n)
	end
	while next(typesToCreate)~=nil do
		local created = 0
		for name, v in pairs(typesToCreate) do
			if v.basetype then
				local base = types[v.basetype]
				if base then
					types[name] = class(name, base)
					typesToCreate[name] = nil
					typesToInit[#typesToInit+1] = {basetype = base, func = v.func}
					created = created + 1
				end
			else
				types[name] = class(name)
				typesToCreate[name] = nil
				typesToInit[#typesToInit+1] = {func = v.func}
				created = created + 1
			end
		end
		if created==0 then
			local badType = next(typesToCreate)
			error("Failed to create type \""..badType.."\", missing basetype \""..typesToCreate[badType].basetype.."\"")
		end
	end
	for _, v in ipairs(typesToInit) do v.func(v.basetype) end
	function addType(name, basetype, func)
		types[name] = class(name, basetype and (types[basetype] or error("Couldn't find basetype: "..basetype)))
	end
end

function util.serializeArray(tbl, func)
	local buff = {love.data.pack("<L", #tbl)}
	for k, v in ipairs(tbl) do
		buff[#buff+1] = func(v)
	end
	return table.concat(buff)
end

function util.deserializeArray(buff, pos, func)
	local tbl = {}
	local size = love.data.unpack("<L", buff, pos)
	pos = pos + 4
	for i=1, size do
		tbl[i], pos = func(buff, pos)
	end
	return tbl, pos
end

function math.normalizeVec(x, y)
	local l = math.sqrt(x^2+y^2)
	return x/l, y/l
end

function math.length(x, y)
	return math.sqrt(x^2+y^2)
end

function math.lengthSqr(x, y)
	return x^2+y^2
end

function math.dot(x1, y1, x2, y2)
	return x1*x2 + y1*y2
end

function math.clamp(x, min, max)
	return math.max(math.min(x, max), min)
end

function math.angnorm(x)
	return (x + math.pi) % (math.pi*2) - math.pi
end

function math.vecToAng(x, y)
	return math.atan2(x, -y)
end

function math.randVecNorm()
	local t = math.random()*(2*math.pi)
	return math.cos(t), math.sin(t)
end

function math.randVecSquare()
	return math.random()*2-1, math.random()*2-1
end

function math.rotVecCW(x, y)
	return -y, x
end

function math.rotVecCCW(x, y)
	return y, -x
end

function math.rotVec(x, y, a)
	local c, s = math.cos(a), math.sin(a)
	return c*x + s*y, c*y - s*x
end

return util
