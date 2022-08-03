addType("spawn", "baseentity", function(baseentity)
local spawn = types.spawn

function spawn:initialize(data)
	baseentity.initialize(self)
	self.spawnpoint = {x = data.center.x, y = -data.center.y}
	hook.add("worldloaded", self)
end

function spawn:destroy()
	hook.remove("worldloaded", self)
end

function spawn:worldloaded()
	world.player = types.borb:new(self.spawnpoint.x, self.spawnpoint.y, 1.5)
	world.player:spawn()
end

end)

addType("spike", "baseentity", function(baseentity)
local spike = types.spike

function spike:initialize(body, data)
	baseentity.initialize(self)
	self.drawCategory = world.drawCategories.foreground
	self.body = body
	self.body:setObject(self)
	self.x, self.y = data.center.x, -data.center.y
end

function spike:draw(data)
	
end

end)

addType("animatedSprite", nil, function()
local animatedSprite = types.animatedSprite

function animatedSprite:initialize(img, map)
	self.map = map
	self.meshes = {}
	self.maxt = map.maxt
	for k, v in ipairs(map) do
		local mesh = love.graphics.newMesh({{-0.5, -0.5, v.u1, v.v1}, {0.5, -0.5, v.u2, v.v1}, {0.5, 0.5, v.u2, v.v2}, {-0.5, 0.5, v.u1, v.v2}}, "fan", "static")
		mesh:setTexture(img)
		self.meshes[k] = mesh
	end
end

function animatedSprite:destroy()
	for k, v in ipairs(self.meshes) do
		v:release()
	end
end

function animatedSprite:findMesh(t)
	t = t % self.maxt
	for k, v in ipairs(self.map) do
		if t < v.t then
			return self.meshes[k-1]
		end
	end
	return self.meshes[#self.meshes]
end

function animatedSprite:draw(t, ...)
	love.graphics.draw(self:findMesh(t), ...)
end

end)

addType("animatedSpriteBlurred", "animatedSprite", function()
local animatedSpriteBlurred = types.animatedSpriteBlurred

function animatedSpriteBlurred:findMeshes(t, tlen)
	t = t % self.maxt
	local tleft = tlen
	local weights = {}
	local pos = #self.map
	for k, v in ipairs(self.map) do
		if t < v.t then
			pos = ((k-2) % #self.map) + 1
			break
		end
	end
	do
		local nextp = (pos % #self.map) + 1
		local dt = math.min((self.map[nextp].t - t) % self.maxt, tleft)
		weights[pos] = dt
		tleft = tleft - dt
		pos = nextp
	end

	while tleft>0 do
		local nextp = (pos % #self.map) + 1
		local dt = math.min((self.map[nextp].t - self.map[pos].t) % self.maxt, tleft)
		weights[pos] = (weights[pos] or 0) + dt
		tleft = tleft - dt
		pos = nextp
	end

	local meshes = {}
	for k, v in pairs(weights) do
		meshes[#meshes+1] = {mesh = self.meshes[k], weight = v}
	end
	local alpha = 1
	for i=#meshes, 2, -1 do
		local val = (meshes[i].weight / tlen) * alpha
		meshes[i].alpha = val
		alpha = alpha / (1 - val)
	end
	meshes[1].alpha = 1
	return meshes
end

function animatedSpriteBlurred:draw(t, tlen, ...)
	for k, v in ipairs(self:findMeshes(t, tlen)) do
		love.graphics.setColor( 1, 1, 1, v.alpha )
		love.graphics.draw(v.mesh, ...)
	end
	love.graphics.setColor( 1, 1, 1, 1 )
end

end)

addType("model", nil, function()
local model = types.model

model.store = {}
function model:initialize(name, x, y)
	if name then
		self.data = model.store[name] or model.loadFromFile(name)
	else
		self.data = {
			images = {},
			meshes = {},
			shapes = {}
		}
	end
end

function model.loadFromFile(name)
	local data = model.deserialize(love.filesystem.read(name))
	model.store[name] = data
	return data
end

function model.saveToFile(name)
	love.filesystem.write(name, model.serialize(model.store[name]))
end

function model.serialize(data)
	local buffer = {}
	buffer[#buffer+1] = util.serializeArray(data.images, model.serializeImgPath)
	buffer[#buffer+1] = util.serializeArray(data.meshes, model.serializeMesh)
	buffer[#buffer+1] = util.serializeArray(data.shapes, model.serializeShape)
	return table.concat(buffer)
end

function model.deserialize(buffer)
	local data = {}
	local pos = 1
	data.images, pos = util.deserializeArray(buffer, pos, model.deserializeImgPath)
	data.meshes, pos = util.deserializeArray(buffer, pos, model.deserializeMesh)
	data.shapes, pos = util.deserializeArray(buffer, pos, model.deserializeShape)
	return data
end

function model.serializeImgPath(img)
	return love.data.pack("<s", img.filename)
end

function model.serializeMesh(mesh)
	local count = mesh:getVertexCount()
	local buffer = {love.data.pack("<L", count)}
	for i=1, count do
		buffer[#buffer+1] = love.data.pack("<dddd", mesh:getVertex(i))
	end
	return table.concat(buffer)
end

function model.serializeShape(shape)
	local buffer = {}
	local verts = {shape:getPoints()}
	buffer[#buffer+1] = love.data.pack("<L"..string.rep("d",#verts), #verts, unpack(verts))
end

function model.deserializeImgPath(buffer, pos)
	local path = love.data.unpack("<s", buffer, pos)
	local tbl = {
		filename = path,
		image = images[path]
	}
	return tbl, pos+4+#path
end

function model.deserializeMesh(buffer, pos)
	local verts
	pos, verts = util.deserializeArray(buffer, pos, function(buffer, pos)
		return pos+4*8, {love.data.unpack("<dddd", buffer, pos)}
	end)
	return love.graphics.newMesh(verts, "triangles", "static"), pos
end

function model.deserializeShape(buffer, pos)
	local count = love.data.unpack("<L", buffer, pos)
	pos = pos + 4
	return love.physics.newPolygonShape(love.data.unpack("<"..string.rep("d",count), buffer, pos)), pos+count*8
end

end)
