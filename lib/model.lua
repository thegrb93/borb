local model = class("model")

function model:initialize(name)
	local path = "mdls/"..name..".mdl"
	local buffer = love.filesystem.read(path)
	if not buffer then error("Couldn't load model: "..path) end
	self:deserialize(buffer, 1)

	for _, meshgroup in ipairs(self.meshgroups) do
		for id, quads in ipairs(meshgroup.meshes) do
			local vertices = {}
			for _, quad in ipairs(quads) do
				vertices[#vertices+1] = meshgroup.vertices[quad[1]]
				vertices[#vertices+1] = meshgroup.vertices[quad[2]]
				vertices[#vertices+1] = meshgroup.vertices[quad[3]]
				vertices[#vertices+1] = meshgroup.vertices[quad[1]]
				vertices[#vertices+1] = meshgroup.vertices[quad[3]]
				vertices[#vertices+1] = meshgroup.vertices[quad[4]]
			end
			local mesh = love.graphics.newMesh(vertices, "triangles", "static")
			local tex = images[meshgroup.materials[id]]
			tex:setWrap("repeat","repeat")
			mesh:setTexture(tex)
			quads.mesh = mesh
		end
	end
	for _, shape in ipairs(self.shapes) do
		if shape.type=="quadmesh" then
			local shapes = {}
			local meshgroup = self.meshgroups[shape.meshgroup]
			for _, quads in ipairs(meshgroup.meshes) do
				for _, quad in ipairs(quads) do
					local a = meshgroup.vertices[quad[1]]
					local b = meshgroup.vertices[quad[2]]
					local c = meshgroup.vertices[quad[3]]
					local d = meshgroup.vertices[quad[4]]
					shapes[#shapes+1] = love.physics.newPolygonShape(a[1], a[2], b[1], b[2], c[1], c[2], d[1], d[2])
				end
			end
			shape.shapes = shapes
		else
			error("Invalid shape: "..shape.type)
		end
	end
end

function model:createBodies(ent, x, y, a)
	local bodies = {}
	for k, v in ipairs(self.bodies) do
		local body = world.physworld:newCollider(x, y, a)
		body:setObject(ent)
		body:setType(v.type)
		body.meshgroup = self.meshgroups[v.meshgroup]
		for _, fixtureInd in ipairs(v.fixtures) do
			self:attachFixture(body, self.fixtures[fixtureInd])
		end
		bodies[k] = body
	end
	ent.bodies = bodies
end

function model:attachFixture(body, fixture)
	local shape = self.shapes[fixture.shape]
	if shape.type == "quadmesh" then
		for k, v in ipairs(shape.shapes) do
			local f = body:addFixture(k, v)
		end
	end
end

function model:draw(body)
	local x, y = body:getPosition()
	local a = body:getAngle()
	for k, v in ipairs(body.meshgroup.meshes) do
		love.graphics.draw(v.mesh, x, y, a)
	end
end

function model:serialize(buffer)
	buffer[#buffer+1] = love.data.pack("string", "<s", self.name)
	util.serializeArray(buffer, self.meshgroups, function(buffer, meshgroup)
		util.serializeArray(buffer, meshgroup.meshes, function(buffer, faces)
			util.serializeArray(buffer, faces, function(buffer, face)
				buffer[#buffer+1] = love.data.pack("string", "<LLLL", unpack(face))
			end)
		end)
		util.serializeArray(buffer, meshgroup.vertices, function(buffer, vert)
			buffer[#buffer+1] = love.data.pack("string", "<ffffffff", unpack(vert))
		end)
		util.serializeArray(buffer, meshgroup.materials, function(buffer, str)
			buffer[#buffer+1] = love.data.pack("string", "<s", str)
		end)
	end)
	util.serializeArray(buffer, self.bodies, function(buffer, body)
		buffer[#buffer+1] = love.data.pack("string", "<sL", body.type, body.meshgroup)
		util.serializeArray(buffer, body.fixtures, function(buffer, fixture)
			buffer[#buffer+1] = love.data.pack("string", "<L", fixture)
		end)
	end)
	util.serializeArray(buffer, self.shapes, function(buffer, shape)
		buffer[#buffer+1] = love.data.pack("string", "<s", shape.type)
		if shape.type=="quadmesh" then
			buffer[#buffer+1] = love.data.pack("string", "<L", shape.meshgroup)
		else
			error("Unsupported shape type: "..shape.type)
		end
	end)
	util.serializeArray(buffer, self.fixtures, function(buffer, fixture)
		buffer[#buffer+1] = love.data.pack("string", "<L", fixture.shape)
	end)
end

function model:deserialize(buffer, pos)
	self.name, pos = love.data.unpack("<s", buffer, pos)
	self.meshgroups, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
		local mesh = {}
		mesh.meshes, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
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
	self.bodies, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
		local body = {}
		body.type, body.meshgroup, pos = love.data.unpack("<sL", buffer, pos)
		body.fixtures, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
			return love.data.unpack("<L", buffer, pos)
		end)
		return body, pos
	end)
	self.shapes, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
		local shape = {}
		shape.type, pos = love.data.unpack("<s", buffer, pos)
		if shape.type == "quadmesh" then
			shape.meshgroup, pos = love.data.unpack("<L", buffer, pos)
		else
			error("Unsupported shape type: "..shape.type)
		end
		return shape, pos
	end)
	self.fixtures, pos = util.deserializeArray(buffer, pos, function(buffer, pos)
		local fixture = {}
		fixture.shape, pos = love.data.unpack("<L", buffer, pos)
		return fixture, pos
	end)
end

function model.loadPly(name)
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

	local meshes = setmetatable({},{__index=function(t,k) local r={} t[k] = r return r end})
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
		local quads = meshes[mat+1]
		quads[#quads+1] = {a+1, b+1, c+1, d+1}
	end
	return setmetatable(meshes, nil), vertices
end

function commands.model(name)
	local script = love.filesystem.load("rawmdl/"..name..".lua")
	local env = {}
	function env.meshgroup(data)
		local meshes, vertices = model.loadPly(data.path)
		if #meshes ~= #data.materials then error("Number of meshs doesn't match number of defined materials!") end
		data.path = nil
		data.meshes = meshes
		data.vertices = vertices
		return data
	end
	function env.body(data)
		if data.type == nil then error("Body missing type!") end
		return data
	end
	function env.shape(data)
		if data.type == nil then error("Shape missing type!") end
		return data
	end
	function env.fixture(data)
		if data.density == nil then data.density = 1 end
		return data
	end
	function env.model(data)
		local buffer = {}
		model.serialize(data, buffer)
		love.filesystem.write("mdls/"..data.name..".mdl", table.concat(buffer))
		print("Saved model: "..data.name)
	end
	setfenv(script, env)
	script()
end

return model
