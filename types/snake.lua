addType("snake", nil, function()
local snake = types.snake

function snake:initialize()
    self.drawCategory = world.drawCategories.foreground
end

function snake:destroy()
end

function snake:think()
end

function snake:draw()
end

end)
