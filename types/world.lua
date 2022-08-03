local wf = require("lib/windfield")
local rube = require("lib/rube")

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
		end
	end

	function baseentity:remove()
		if self.valid then
			self.valid = false
			self.removing = true
			world.addents[self] = nil
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

world.backgroundimg = images["background.png"]
world.backgroundw = world.backgroundimg:getWidth()*0.5
world.backgroundh = world.backgroundimg:getHeight()*0.5
function world:initialize()
	self.t = 0
	self.dt = 1/winmode.refreshrate
	self.addents = {}
	self.rments = {}
	self.thinkents = {}
	self.drawents = {}
	self.drawCategories = {
		"background",
		"worldforeground",
		"foreground",
		"gui"
	}
	for k, v in ipairs(self.drawCategories) do
		self.drawents[k] = {}
		self.drawCategories[v] = k
	end

	self.physworld = wf.newWorld(0, 60, true)
	self.physworld:addCollisionClass("World", {ignores = {}})
	self.physworld:addCollisionClass("Player", {ignores = {"Player"}})
	self.physworld:addCollisionClass("Enemy", {ignores = {}})

	self.camera = types.camera:new()
	self.backcamera = types.camera:new()

	hook.add("render", self)
end

function world:loadLevel(level)
	local leveldata = love.filesystem.load(level)()
	local bodies = rube(self.physworld, leveldata)

	if leveldata.image then
		for id, v in pairs(leveldata.image) do
			if v.class == "world" then
				self.foregroundimg = images[v.file]
				self.foregroundw = self.foregroundimg:getWidth()*0.5
				self.foregroundh = self.foregroundimg:getHeight()*0.5
				self.foregroundscale = v.scale / self.foregroundimg:getHeight()
			elseif v.class then
				local meta = types[v.class]
				if meta then
					meta:new(v):spawn()
				else
					error("Invalid type: " .. v.class)
				end
			end
		end
	end
	if leveldata.body then
		for k, v in pairs(leveldata.body) do
			if v.class then
				if v.class == "world" then
					local body = bodies[k]
					body:setObject(self)
					body:setCollisionClass("World")
				else
					local meta = types[v.class]
					if meta then
						meta:new(bodies[k], v):spawn()
					else
						error("Invalid type: " .. v.class)
					end
				end
			end
		end
	end

	hook.call("worldloaded")
end

function world:clear()
	for ent in pairs(self.addents) do
		ent:remove()
	end
	for k, ent in ipairs(self.thinkents) do
		ent:remove()
		self.thinkents[k] = nil
	end
	for _, list in ipairs(self.drawents) do
		for k, ent in ipairs(list) do
			ent:remove()
			list[k] = nil
		end
	end
	for ent in pairs(self.rments) do
		self.rments[ent] = nil
		ent:onRemove()
	end
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
			for k, e in ipairs(self.thinkents) do if ent==e then table.remove(self.thinkents, k) break end end
		end
		if ent.draw then
			local drawtbl = self.drawents[ent.drawCategory]
			for k, e in ipairs(drawtbl) do if ent==e then table.remove(drawtbl, k) break end end
		end
		ent:onRemove()
	end
end

function world:render()
	-- Update game logic
	self.t = self.t + self.dt
	self.physworld:update(self.dt)
	flux.update(self.dt)
	scheduler:tick(self.t)
	for _, ent in ipairs(self.thinkents) do
		ent:think()
	end
	self:procEntities()

	-- Draw background entities
	self.backcamera.zoom = self.camera.zoom*0.1
	self.backcamera:setPos(self.camera.x, self.camera.y)
	self.backcamera:update()
	self.backcamera:push()
	-- love.graphics.draw(world.backgroundimg, 0, 0, 0, 0.25, 0.25, world.backgroundw, world.backgroundh)
	for _, ent in ipairs(self.drawents[1]) do
		ent:draw()
	end
	self.backcamera:pop()

	-- Draw foreground entities
	self.camera:push()
	-- love.graphics.draw(self.foregroundimg, 0, 0, 0, self.foregroundscale, self.foregroundscale, self.foregroundw, self.foregroundh)
	for _, ent in ipairs(self.drawents[2]) do
		ent:draw()
	end
	for _, ent in ipairs(self.drawents[3]) do
		ent:draw()
	end
	-- love.graphics.setLineWidth(0.01)
	-- self.physworld:draw()
	self.camera:pop()

	-- Draw screen entities
	for _, ent in ipairs(self.drawents[4]) do
		ent:draw()
	end
end

end)

hook.add("postload","world",function()
	world = types.world:new()
	types.mainmenu:new():spawn()
end)
