local wf = require("lib/windfield")

addType("baseentity", nil, function()
	local baseentity = types.baseentity

	function baseentity:initialize(x, y, a)
		self.x, self.y, self.a = x, y, a
		self.valid = false
		self.removing = false
	end

	function baseentity:getPos()
		return self.x, self.y
	end

	function baseentity:spawn()
		if not self.removing then
			self.valid = true
			world.addents[self] = true
			world.allEntities[self] = true
		end
		return self
	end

	function baseentity:remove()
		if self.valid then
			self.valid = false
			self.removing = true
			world.addents[self] = nil
			world.allEntities[self] = nil
			world.rments[self] = true
		end
	end

	function baseentity:onRemove()
	end

	function baseentity:isValid()
		return self.valid
	end

end)

addType("world", nil, function()
local world = types.world

function world:initialize()
	self.think = self.thinkGame
	self.debug = false
	self.allEntities = {}
	self.addents = {}
	self.rments = {}
	self.thinkents = {}
	self.drawents = {}
	self.drawCategories = {
		"background",
		"worldforeground",
		"foreground",
	}
	for k, v in ipairs(self.drawCategories) do
		self.drawents[k] = {}
		self.drawCategories[v] = k
	end
	worldgui = types.worldgui:new()

	self:setupWorld()

	hook.add("render", self)
end

function world:setupWorld()
	self.t = 0

	self.physworld = wf.newWorld(0, 60, true)
	self.physworld:addCollisionClass("World", {ignores = {}})
	self.physworld:addCollisionClass("Player", {ignores = {"Player"}})
	self.physworld:addCollisionClass("Enemy", {ignores = {}})

	self.camera = types.camera:new()
	self.backcamera = types.camera:new()
end

function world:clear()
	for ent in pairs(self.allEntities) do
		ent:remove()
	end
	for k, ent in ipairs(self.thinkents) do
		self.thinkents[k] = nil
	end
	for _, list in ipairs(self.drawents) do
		for k, ent in ipairs(list) do
			list[k] = nil
		end
	end
	for ent in pairs(self.rments) do
		self.rments[ent] = nil
		ent:onRemove()
	end

	worldgui:close()
	self.physworld:destroy()
	self:setupWorld()
	for k, _ in ipairs(flux.tweens) do
		flux.tweens[k] = nil
	end
	scheduler = require("lib/scheduler")()
end

function world:procEntities()
	for ent in pairs(self.addents) do
		self.addents[ent] = nil
		if ent.think then
			self.thinkents[#self.thinkents+1] = ent
		end
		if ent.draw then
			local drawtbl = self.drawents[ent.drawCategory]
			drawtbl[#drawtbl+1] = ent
		end
	end
	for ent in pairs(self.rments) do
		self.rments[ent] = nil
		if ent.think then
			table.removeByValue(self.thinkents, ent)
		end
		if ent.draw then
			table.removeByValue(self.drawents[ent.drawCategory], ent)
		end
		ent:onRemove()
	end
end

function world:thinkGame()
	-- Update game logic
	self.t = self.t + dt
	self.physworld:update(dt)
	flux.update(dt)
	scheduler:tick(self.t)
	for _, ent in ipairs(self.thinkents) do
		ent:think()
	end
end

function world:thinkNone()
end

function world:render()
	self:think()
	self:procEntities()

	-- Draw background entities
	self.backcamera.zoom = self.camera.zoom*0.1
	self.backcamera:setPos(self.camera.x, self.camera.y)
	self.backcamera:think()
	self.backcamera:push()
	for _, ent in ipairs(self.drawents[1]) do
		ent:draw()
	end
	self.backcamera:pop()

	-- Draw foreground entities
	self.camera:think()
	self.camera:push()
	for _, ent in ipairs(self.drawents[2]) do
		ent:draw()
	end
	for _, ent in ipairs(self.drawents[3]) do
		ent:draw()
	end

	if self.debug then
		-- draw physics meshes
		love.graphics.setLineWidth(0.01)
		self.physworld:draw()
	end

	self.camera:pop()

	-- Draw gui
	worldgui:draw()
end

function world:screenToWorld(x, y)
	return self.camera.transform:inverseTransformPoint(x, y)
end

function world:worldToScreen(x, y)
	return self.camera.transform:transformPoint(x, y)
end

function world:loadLevel(level, nostart)
	self:deserialize(love.filesystem.read("lvls/"..level..".lvl") or error("Couldn't read level: "..level))
	if not nostart then
		hook.call("worldloaded")
	end
end

function world:serialize(buffer)
	local ents = {}
	for ent in pairs(self.allEntities) do
		if ent.serialize then
			ents[#ents+1] = ent
		end
	end
	util.serializeArray(buffer, ents, function(buffer, v)
		if not v.serialize then error("Type "..v.." is not serializable!") end
		buffer[#buffer+1] = love.data.pack("string", "<s", v.class.name)
		v:serialize(buffer)
	end)
	return table.concat(buffer)
end

function world:deserialize(buffer)
	util.deserializeArray(buffer, 1, function(buffer, pos)
		local tname
		tname, pos = love.data.unpack("<s", buffer, pos)
		local t = types[tname]
		if not t then error("Type \""..tname.."\" not found!") end
		if not t.deserialize then error("Type \""..tname.."\" is not deserializable!") end
		local e
		e, pos = t.deserialize(buffer, pos)
		e:spawn()
		return e, pos
	end)
end

end)

hook.add("postload","world",function()
	world = types.world:new()
	types.mainmenu:new()
end)

function commands.debug()
	world.debug = not world.debug
	print("Debug " .. (world.debug and "on" or "off"))
end
