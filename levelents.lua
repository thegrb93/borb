
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
function spike:initialize(body, data)
    self.drawCategory = world.drawCategories.foreground
    self.body = body
    self.body:setObject(self)
    self.x, self.y = data.center.x, -data.center.y
    world:addEntity(self)
end

function spike:draw(data)
    
end

local spring = types.spring
spring.graphic = love.graphics.newImage( "img/spring.png" )
function spring:initialize(body, data)
    self.drawCategory = world.drawCategories.foreground
    self.body = body
    self.body:setObject(self)
    self.power = data.power
    self.ready = true
    world:addEntity(self)
    self.body:setGravityScale(0)

    local slider, distance
    for k, v in ipairs(body:getJoints()) do
        if v:getType()=="prismatic" then slider = v end
        if v:getType()=="distance" then distance = v end
    end
    if not slider then error("Spring entity without a slider joint!") end
    if not distance then error("Spring entity without a distance joint!") end
    self.dirx, self.diry = slider:getAxis()
    self.distance = distance

    body:setPostSolve(function(collider_1, ...)
        self:postSolve(...)
    end)
end

function spring:postSolve(other, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
    if self.ready then
        self.ready = false
        scheduler:timer(0.5, function() self.ready = true end)
        
        local velx, vely = other:getLinearVelocity()
        local dot = velx*self.dirx + vely*self.diry
        
        local otherAmount = other:getMass()*(self.power - dot + 5)
        other:applyLinearImpulse(self.dirx * otherAmount, self.diry * otherAmount)

        local selfAmount = self.body:getMass()*self.power
        self.body:applyLinearImpulse(self.dirx * selfAmount, self.diry * selfAmount)
    end
end

function spring:draw()
    local x1, y1, x2, y2 = self.distance:getAnchors()
    util.drawBeam(x1, y1, x2, y2, 0, 0, 1, 1, 1.5, spring.graphic)
    love.graphics.setColor(0.8, 0.06, 0.06, 1)
    love.graphics.polygon("fill", self.body:getWorldPoints(self.body.shapes.fixture1:getPoints()))
    love.graphics.setColor(1, 1, 1, 1)
end
