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
			if types[name] then error("Multiple type definition: "..name) end
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
		local base = basetype and (types[basetype] or error("Couldn't find basetype: "..basetype))
		types[name] = class(name, base)
		func(base)
	end
end

function commands.reload()
	love.filesystem.load("lib/util.lua")()
end

function commands.lua(str)
	loadstring(str)()
end

function commands.model(name)
	local script = love.filesystem.load("rawmdl/"..name..".lua")
	local env = {}
	function env.mesh(data)
		local groups, vertices = util.loadPly(data.path)
		if #groups ~= #data.materials then error("Number of meshs doesn't match number of defined materials!") end
		data.path = nil
		data.groups = groups
		data.vertices = vertices
		return data
	end
	function env.body(data)
		return data
	end
	function env.shape(data)
		return data
	end
	function env.fixture(data)
		return data
	end
	function env.model(data)
		util.saveModel(data)
		print("Saved model: "..data.name)
	end
	setfenv(script, env)
	script()
end

function util.loadPly(name)
	local path = "rawmdl/"..name
	local data = love.filesystem.read(path)
	local map = {}
	local propertyidx = 1
	for line in string.gmatch(data, "[^\n]+") do
		local property = string.match(line, "property float (%w+)")
		if property then
			map[property] = propertyidx
			propertyidx = propertyidx + 1
		elseif line=="end_header" then break end
	end
	local fmt = "<"..string.rep("f",propertyidx-1)

	local groups = setmetatable({},{__index=function(t,k) local r={} t[k] = r return r end})
	local vertices = {}
	local nverts = string.match(data, "element vertex (%d+)") or error("Couldn't find vertex count in ply: "..path)
	local nfaces = string.match(data, "element face (%d+)") or error("Couldn't find face count in ply: "..path)
	local _, _, index = string.find(data, "end_header\n()")
	for i=1, nverts do
		local args = {love.data.unpack(fmt, data, index)}
		vertices[#vertices+1] = {args[map.x], args[map.y], args[map.s], args[map.t], map.r and args[map.r] or 1, map.g and args[map.g] or 1, map.b and args[map.b] or 1, map.a and args[map.a] or 1}
		index = args[#args]
	end
	local count, mat, a, b, c, d
	for i=1, nfaces do
		count, mat, a, b, c, d, index = love.data.unpack("<BLLLLL", data, index)
		local faces = groups[mat+1]
		faces[#faces+1] = {a, b, c, d}
	end
	return setmetatable(groups, nil), vertices
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

function util.saveModel(data)
	local buffer = {}
	buffer[#buffer+1] = love.data.pack("string", "<s", data.name)
	util.serializeArray(buffer, data.models, function(buffer, mesh)
		util.serializeArray(buffer, mesh.groups, function(buffer, faces)
			util.serializeArray(buffer, faces, function(buffer, face)
				buffer[#buffer+1] = love.data.pack("string", "<LLLL", unpack(face))
			end)
		end)
		util.serializeArray(buffer, mesh.vertices, function(buffer, vert)
			buffer[#buffer+1] = love.data.pack("string", "<ffffffff", unpack(vert))
		end)
		util.serializeArray(buffer, mesh.materials, function(buffer, str)
			buffer[#buffer+1] = love.data.pack("string", "<s", str)
		end)
	end)
	util.serializeArray(buffer, data.bodies, function(buffer, body)
		buffer[#buffer+1] = love.data.pack("string", "<B", body.static and 1 or 0)
	end)
	util.serializeArray(buffer, data.shapes, function(buffer, shape)
		buffer[#buffer+1] = love.data.pack("string", "<s", shape.type)
		if shape.type=="polygonList" then
			buffer[#buffer+1] = love.data.pack("string", "<L", shape.mesh)
		else
			error("Unsupported shape type: "..shape.type)
		end
	end)
	util.serializeArray(buffer, data.fixtures, function(buffer, fixture)
		buffer[#buffer+1] = love.data.pack("string", "<LL", fixture.body, fixture.shape)
	end)
	local path = "mdls/"..data.name..".mdl"
	love.filesystem.write(path, table.concat(buffer))
end

function util.loadModel(name)
	local buffer = love.filesystem.read("mdls/"..name..".mdl")
	local data = {}
	local pos = 1
	data.name, pos = love.data.unpack("<s", buffer, pos)
	data.models, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
		local mesh = {}
		mesh.groups, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
			return util.deserializeArray(buffer, pos, function(buffer, pos)
				local a, b, c, d
				a, b, c, d, pos = love.data.unpack("<LLLL", buffer, pos)
				return {a, b, c, d}, pos
			end)
		end)
		mesh.vertices, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
			local x, y, u, v, r, g, b, a
			x, y, u, v, r, g, b, a, pos = love.data.unpack("<ffffffff", buffer, pos)
			return {x, y, u, v, r, g, b, a}, pos
		end)
		mesh.materials, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
			return love.data.unpack("<s", buffer, pos)
		end)
		return mesh, pos
	end)
	data.bodies, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
		local body = {}
		body.static, pos = love.data.unpack("<B", buffer, pos)
		return body, pos
	end)
	data.shapes, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
		local shape = {}
		shape.type, pos = love.data.unpack("<s", buffer, pos)
		if shape.type == "polygonList" then
			shape.mesh, pos = love.data.unpack("<L", buffer, pos)
		else
			error("Unsupported shape type: "..shape.type)
		end
		return shape, pos
	end)
	data.fixtures, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
		local fixture = {}
		fixture.body, fixture.shape, pos = love.data.unpack("<LL", buffer, pos)
		return fixture, pos
	end)

	for _, model in ipairs(data.models) do
		model.meshes = {}
		for id, group in ipairs(model.groups) do
			local vertices = {}
			for _, face in ipairs(group) do
				vertices[#vertices+1] = model.vertices[face[1]]
				vertices[#vertices+1] = model.vertices[face[2]]
				vertices[#vertices+1] = model.vertices[face[3]]
				vertices[#vertices+1] = model.vertices[face[1]]
				vertices[#vertices+1] = model.vertices[face[3]]
				vertices[#vertices+1] = model.vertices[face[4]]
			end
			local mesh = love.graphics.newMesh(vertices, "triangles", "static")
			mesh:setTexture(images[model.materials[id]])
			model.meshes[id] = mesh
		end
	end
	for _, shape in ipairs(data.shapes) do
		if shape.type=="polygonList" then
			local shapes = {}
			for _, group in ipairs(data.models[shape.mesh]) do
				for _, face in ipairs(group) do
					local a = model.vertices[face[1]]
					local b = model.vertices[face[2]]
					local c = model.vertices[face[3]]
					local d = model.vertices[face[4]]
					shapes[#shapes+1] = love.physics.newPolygonShape(a[1], a[2], b[1], b[2], c[1], c[2], d[1], d[2])
				end
			end
			shape.shapes = shapes
		end
	end

	return data
end

function commands.test() util.loadModel("branch") end

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
