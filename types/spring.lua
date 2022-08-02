addType("spring", nil, function()
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
    love.graphics.setColor(0.7, 0.1, 0.1, 1)
    love.graphics.polygon("fill", self.body:getWorldPoints(self.body.shapes.fixture1:getPoints()))
    love.graphics.setColor(1, 1, 1, 1)
end

end)
