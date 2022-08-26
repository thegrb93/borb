addType("camera", nil, function()

local winW, winH = love.graphics.getPixelDimensions()
local camera = types.camera

function camera:initialize()
	self.x = 0
	self.y = 0
	self.zoom = 25
	self.transform = love.math.newTransform()
	self.shakeRk = util.rungeKutta(0, 0, 0, 0, 0, 0)
	self.shaking = false
end

function camera:push()
	love.graphics.push("transform")
	love.graphics.replaceTransform(self.transform)
end

function camera:pop()
	love.graphics.pop("transform")
end

function camera:think()
	if self.shaking then
		self.shakeRk(-self.shakeRk.x*3000 - self.shakeRk.dx*20,-self.shakeRk.y*3000 - self.shakeRk.dy*20,0)
		if math.abs(self.shakeRk.x)<1e-7 and math.abs(self.shakeRk.y)<1e-7 and math.abs(self.shakeRk.dx)<1e-7 and math.abs(self.shakeRk.dy)<1e-7 then
			self.shaking = false
		end
	end

	self.transform:reset()
	self.transform:translate(winW/2, winH/2)
	self.transform:scale(self.zoom, self.zoom)
	self.transform:translate(self.shakeRk.x-self.x, self.shakeRk.y-self.y)
end

function camera:setPos(x, y)
	self.x = x
	self.y = y
end

function camera:addZoom(zoom)
	self.zoom = math.max(self.zoom + zoom, 1)
end

function camera:shake(shakex, shakey)
	self.shaking = true
	self.shakeRk.dx = self.shakeRk.dx + shakex
	self.shakeRk.dy = self.shakeRk.dy + shakey
end

end)
