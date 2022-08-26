local util = {}

function util.inBox(x, y, bx, by, bw, bh)
	return x>=bx and y>=by and x<=bx+bw and y<=by+bh
end

function util.newPDController(body, pgain, dgain)
	local mass, inertia = body:getMass(), body:getInertia()
	local dgain = dgain or math.sqrt(pgain)*2
	return function(dx, dy, da, ddx, ddy, dda)
		body:applyForce((dx*pgain + ddx*dgain)*mass, (dy*pgain + ddy*dgain)*mass)
		body:applyTorque((da*pgain + dda*dgain)*inertia)
	end
end

local dt = dt
local rkmeta = {__call = function(self, fx, fy, fa)
	self.dx = self.dx + fx*dt
	self.dy = self.dy + fy*dt
	self.da = self.da + fa*dt
	self.x = self.x + self.dx*dt
	self.y = self.y + self.dy*dt
	self.a = self.a + self.da*dt
end}
function util.rungeKutta(x, y, a, dx, dy, da)
	return setmetatable({
		x = x, y = y, a = a, dx = dx, dy = dy, da = da
	}, rkmeta)
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
	if x1==x2 and y1==y2 then return end
	if filter==nil then filter = function() return true end end
	local fixture, x, y, xn, yn
	local fraction = math.huge
	world.physworld.box2d_world:rayCast(x1, y1, x2, y2, function(fixture_, x_, y_, xn_, yn_, fraction_)
		if filter(fixture_) and fraction_ < fraction then
			fixture, x, y, xn, yn, fraction = fixture_, x_, y_, xn_, yn_, fraction_
		end
		return 1
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
			if types[name] then error("Multiple type definition: "..name) end
			if v.basetype then
				local base = types[v.basetype]
				if base then
					local t = class(name, base)
					types[name] = t
					typesToCreate[name] = nil
					typesToInit[#typesToInit+1] = {type = t, basetype = base, func = v.func}
					created = created + 1
				end
			else
				local t = class(name)
				types[name] = t
				typesToCreate[name] = nil
				typesToInit[#typesToInit+1] = {type = t, func = v.func}
				created = created + 1
			end
		end
		if created==0 then
			local badType = next(typesToCreate)
			error("Failed to create type \""..badType.."\", missing basetype \""..typesToCreate[badType].basetype.."\"")
		end
	end
	for _, v in ipairs(typesToInit) do v.func(v.basetype) end
	for _, v in ipairs(typesToInit) do if v.type.staticinit then v.type.staticinit() end end
	function addType(name, basetype, func)
		local base = basetype and (types[basetype] or error("Couldn't find basetype: "..basetype))
		types[name] = class(name, base)
		func(base)
	end
end

function util.pcall(func, ...)
	local ok, err = xpcall(func, debug.traceback, ...)
	if not ok then print(err) end
	return ok, err
end

function commands.reload()
	love.filesystem.load("lib/util.lua")()
	util.loadTypes()
	-- for ent in pairs(world.allEntities) do
		-- setmetatable(ent, types[getmetatable(ent).name])
	-- end
end

function commands.lua(str)
	loadstring(str)()
end

function util.serializeArray(buffer, tbl, func)
	buffer[#buffer+1] = love.data.pack("string", "<L", #tbl)
	for k, v in ipairs(tbl) do
		func(buffer, v)
	end
end

function util.deserializeArray(buffer, pos, func)
	local tbl = {}
	local size
	size, pos = love.data.unpack("<L", buffer, pos)
	for i=1, size do
		tbl[i], pos = func(buffer, pos)
	end
	return tbl, pos
end

function util.contactNormal(obj, contact)
	local f1, f2 = contact:getFixtures()
	f1, f2 = f1:getUserData():getObject(), f2:getUserData():getObject()
	local nx, ny = contact:getNormal()
	if obj==f2 then nx = -nx ny = -ny end
	return nx, ny
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

function math.round(x)
	if x >= 0 then
		return math.floor(x+0.5)
	else
		return math.ceil(x-0.5)
	end
end

function math.roundBy(x, interval)
	return math.round(x / interval)*interval
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

function table.removeByValue(t, val)
	for k, v in ipairs(t) do
		if v==val then table.remove(t, k) break end
	end
end

function string.split(str, match)
	local tbl = {}
	local i = 1
	while true do
		local start, stop = string.find(str, match, i)
		if start then
			tbl[#tbl+1] = string.sub(str, i, start-1)
			i = stop + 1
		else
			break
		end
	end
	tbl[#tbl+1] = string.sub(str, i)
	return tbl
end

return util
