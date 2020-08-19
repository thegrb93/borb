
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

local spike = types.spike
function spike:initialize(data)
    self.x, self.y = data.center.x, -data.center.y
    world:addEntity(self)
end

function spike:draw(data)
    
end

local spring = types.spring
function spring:initialize(body, data)
    self.body = body
    self.power = data.power
    self.ready = true
    world:addEntity(self)

    local slider
    for k, v in ipairs(body:getJoints()) do
        if v:getType()=="prismatic" then slider = v break end
    end
    if not slider then error("Spring entity without a slider joint!") end
    local ax, ay = slider:getAxis()
    self.dirx = ax * self.power
    self.diry = ay * self.power

    body:setPostSolve(function(collider_1, collider_2, ...)
        local other = collider_2:getObject()
        if other then
            self:postSolve(other, ...)
        end
    end)
end

function spring:postSolve(other, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
    if self.ready then
        self.ready = false
        scheduler:timer(1, function() self.ready = true end)
        
        local othermass = other.body:getMass()
        other.body:applyLinearImpulse(self.dirx * othermass, self.diry * othermass)
        local selfmass = self.body:getMass()
        self.body:applyLinearImpulse(self.dirx * selfmass, self.diry * selfmass)
    end
end

function spike:draw(data)
    
end
