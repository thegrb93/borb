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

addType("background", "baseentity", function(baseentity)
local background = types.background

background.img = images["background.png"]
background.w = background.img:getWidth()*0.5
background.h = background.img:getHeight()*0.5
function background:initialize()
	baseentity.initialize(self)
	self.drawCategory = world.drawCategories.background
end

function background:draw()
	love.graphics.draw(background.img, 0, 0, 0, 0.25, 0.25, background.w, background.h)
end

end)

addType("prop", "baseentity", function(baseentity)
local prop = types.prop

function prop:initialize(model, x, y, a)
	baseentity.initialize(self)
	self.x, self.y, self.a = x, y, a
	self.model = models[model]
end

function prop:serialize(buffer)
	buffer[#buffer+1] = love.data.pack("string", "<sddd", self.model, self.x, self.y, self.a)
end

function prop.deserialize(buffer, pos)
	local model, x, y, a
	model, x, y, a, pos = love.data.unpack("<sddd", buffer, pos)
	return prop:new(model, x, y, a), pos
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
