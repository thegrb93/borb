local wf = require("lib/windfield")

addType("baseentity", nil, function()
	local baseentity = types.baseentity

	function baseentity:initialize()
		self.valid = false
		self.removing = false
	end

	function baseentity:spawn()
		if not self.removing then
			self.valid = true
			world.addents[self] = true
			world.allEntities[self] = true
		end
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
	self.dt = 1/winmode.refreshrate
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
	self.basegui = types.basegui:new()
	self.basegui:addChild(console)
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

	self.basegui:close()
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
	self.t = self.t + self.dt
	self.physworld:update(self.dt)
	flux.update(self.dt)
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
	self.backcamera:update()
	self.backcamera:push()
	for _, ent in ipairs(self.drawents[1]) do
		ent:draw()
	end
	self.backcamera:pop()

	-- Draw foreground entities
	self.camera:push()
	for _, ent in ipairs(self.drawents[2]) do
		ent:draw()
	end
	for _, ent in ipairs(self.drawents[3]) do
		ent:draw()
	end

	-- draw physics meshes
	-- love.graphics.setLineWidth(0.01)
	-- self.physworld:draw()

	self.camera:pop()

	-- Draw screen entities
	self.basegui:draw()
end

function world:loadLevel(level)
	local leveldata = world.deserializeLevel(love.filesystem.read(level))


	hook.call("worldloaded")
end

function world:serializeLevel(data)
	local buffer = {}
	local ents = {}
	for ent in pairs(self.allEntities) do
		if ent.serialize then
			ents[#ents+1] = ent
		end
	end
	util.serializeArray(buffer, ents, function(buffer, v)
		if not v.serialize then error("Type "..v.." is not serializable!") end
		v:serialize(buffer)
	end)
	return table.concat(buffer)
end

function world.deserializeLevel(buffer)
	local ents = util.deserializeArray(buffer, 1, function(buffer, pos)
		local tname
		tname, pos = love.data.unpack("<s", buffer, pos)
		local t = types[tname]
		if not t then error("Type \""..tname.."\" not found!") end
		if not t.deserialize then error("Type \""..tname.."\" is not deserializable!") end
		return t.deserialize(buffer, pos)
	end)
	return {
		ents = ents
	}
end

end)

hook.add("postload","world",function()
	world = types.world:new()
	types.mainmenu:new()
end)
