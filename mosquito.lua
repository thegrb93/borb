local mosquito = types.mosquito
local bloodspray = types.bloodspray

function mosquito:initialize(x, y)
    self.drawCategory = world.drawCategories.foreground
    
    self.body = world.physworld:newCircleCollider(x, y, 1)
    self.body:setType("dynamic")
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(0)
    self.body:setBullet(true)
    self.body:setObject(self)
    self.body:setCollisionClass("Enemy")
    self.body:setGravityScale(0)
    
    local fixture = self.body.fixtures.Main
    fixture:setFriction(10)
    fixture:setRestitution(0.5)
end

function mosquito:explode(x, y, xn, yn)
    world:addEntity(bloodspray:new(x, y, xn, yn))
    self.body:setGravityScale(1)
end

function mosquito:destroy()
end

function mosquito:think()
end

function mosquito:draw()
end


bloodspray.drip = love.graphics.newMesh({{-0.1, -0.1}, {-0.1, 0.1}, {0.1, 0.1}, {0.1, -0.1}}, "fan", "static")
bloodspray.puddle = love.graphics.newMesh({{-0.4, -0.05}, {-0.4, 0.05}, {0.4, 0.05}, {0.4, -0.05}}, "fan", "static")
function bloodspray:initialize(x, y, dx, dy)
    self.drawCategory = world.drawCategories.foreground
    self.maxblood = 30

    self.bloodspray = {}
    for i=1, self.maxblood do
        local rx, ry = math.randVecSquare()
        local setKutta, getKutta, updateKutta = util.rungeKutta()
        setKutta(x+rx*0.2, y+ry*0.2, math.random()*2*math.pi, dx+rx*10, dy+ry*10, math.random()*4-2)
        local blood = {
            setKutta = setKutta,
            getKutta = getKutta,
            updateKutta = updateKutta,
            think = bloodspray.thinkDrip,
            mesh = bloodspray.drip,
        }
        blood.x, blood.y, blood.a = getKutta()
        blood.dt = world.dt
        blood.gx, blood.gy = world.physworld:getGravity()
        self.bloodspray[i] = blood
    end
    
    self.alpha = 1
    flux.to(self, 2, { alpha = 0 }):ease("linear"):delay(10):oncomplete(function() self:destroy() end)
end

function bloodspray:think()
    for k, blood in ipairs(self.bloodspray) do
        blood:think()
    end
end

function bloodspray.thinkDrip(blood)
    local x, y, a, dx, dy, da = blood.getKutta()
	local hit = false

    world.physworld.box2d_world:rayCast(x, y, x+dx*blood.dt*2, y+dy*blood.dt*2, function(fixture, x, y, xn, yn, fraction)
        local udata = fixture:getUserData()
        if udata and udata.collision_class and udata.collision_class == "World" then
            blood.x = x
            blood.y = y
            blood.a = math.vecToAng(xn, yn)
            blood.think = bloodspray.thinkPuddle
            blood.mesh = bloodspray.puddle
			hit = true
            return 0
        end
        return -1
    end)

	if not hit then
		blood.x, blood.y, blood.a = blood.updateKutta(dx*-0.05 + blood.gx, dy*-0.05 + blood.gy, 0)
	end
end

function bloodspray.thinkPuddle(blood)
end

function bloodspray:draw()
    love.graphics.setColor( 1, 0, 0, self.alpha )
    for k, blood in ipairs(self.bloodspray) do
        love.graphics.draw(blood.mesh, blood.x, blood.y, blood.a)
    end
    love.graphics.setColor( 1, 1, 1, 1 )
end

function bloodspray.drawDrip(blood)
    love.graphics.push("transform")
    love.graphics.rotate(blood.a)
    love.graphics.rectangle("fill", blood.x-0.1, blood.y-0.1, 0.2, 0.2)
    love.graphics.pop("transform")
end

function bloodspray:destroy()
    world:removeEntity(self)
end
