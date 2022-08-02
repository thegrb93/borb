addType("spawn", nil, function()
local spawn = types.spawn

function spawn:initialize(data)
    self.spawnpoint = {x = data.center.x, y = -data.center.y}
    hook.add("worldloaded", self)
end

function spawn:destroy()
    hook.remove("worldloaded", self)
end

function spawn:worldloaded()
    world.player = types.borb:new(self.spawnpoint.x, self.spawnpoint.y, 1.5)
    world:addEntity(world.player)
end

end)

addType("spike", nil, function()
local spike = types.spike

function spike:initialize(body, data)
    self.drawCategory = world.drawCategories.foreground
    self.body = body
    self.body:setObject(self)
    self.x, self.y = data.center.x, -data.center.y
    world:addEntity(self)
end

function spike:draw(data)
    
end

end)
