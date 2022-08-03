addType("snake", "baseentity", function(baseentity)
local snake = types.snake

function snake:initialize()
	baseentity.initialize(self)
	self.drawCategory = world.drawCategories.foreground
end

function snake:destroy()
end

function snake:think()
end

function snake:draw()
end

end)
