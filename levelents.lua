
local spawn = types.spawn
function spawn:initialize(data)
    world.spawnpoint = {x = data.center.x, y = -data.center.y}
end

local spike = types.spike
function spike:initialize(data)
    self.x, self.y = data.center.x, -data.center.y
    world.ents:insert(self)
end

function spike:draw(data)
    
end

