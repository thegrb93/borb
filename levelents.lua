
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
    self.drawCategory = world.drawCategories.foreground
    self.x, self.y = data.center.x, -data.center.y
    world:addEntity(self)
end

function spike:draw(data)
    
end

local spring = types.spring
function spring:initialize(body, data)
    self.drawCategory = world.drawCategories.foreground
    self.body = body
    self.power = data.power
    self.ready = true
    world:addEntity(self)
    self.body:setGravityScale(0)

    local slider
    for k, v in ipairs(body:getJoints()) do
        if v:getType()=="prismatic" then slider = v break end
    end
    if not slider then error("Spring entity without a slider joint!") end
    self.dirx, self.diry = slider:getAxis()

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
        scheduler:timer(0.5, function() self.ready = true end)
        
        local velx, vely = other.body:getLinearVelocity()
        local dot = velx*self.dirx + vely*self.diry
        
        local otherAmount = other.body:getMass()*(self.power - dot + 5)
        other.body:applyLinearImpulse(self.dirx * otherAmount, self.diry * otherAmount)

        local selfAmount = self.body:getMass()*self.power
        self.body:applyLinearImpulse(self.dirx * selfAmount, self.diry * selfAmount)
    end
end

function spike:draw(data)
    
end
