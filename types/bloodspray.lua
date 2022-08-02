addType("bloodspray", nil, function()
local bloodspray = types.bloodspray

local dripSize = 0.1
local puddleW = 0.6
local puddleH = 0.1
bloodspray.drip = love.graphics.newMesh({{-dripSize, -dripSize}, {-dripSize, dripSize}, {dripSize, dripSize}, {dripSize, -dripSize}}, "fan", "static")
bloodspray.puddle = love.graphics.newMesh({{-puddleW, -puddleH}, {-puddleW, puddleH}, {puddleW, puddleH}, {puddleW, -puddleH}}, "fan", "static")
bloodspray.collideFilter = function(fixture)
    local udata = fixture:getUserData()
    return udata and udata.collision_class and udata.collision_class == "World"
end

function bloodspray:initialize(x, y, dx, dy)
    self.drawCategory = world.drawCategories.worldforeground
    self.maxblood = 30
    self.dt = world.dt
    self.gx, self.gy = world.physworld:getGravity()

    self.spray = {}
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
            draw = bloodspray.drawBlood,
        }
        blood.x, blood.y, blood.a = getKutta()
        self.spray[i] = blood
    end
    
    self.alpha = 1
    flux.to(self, 2, { alpha = 0 }):ease("linear"):delay(10):oncomplete(function() self:destroy() end)
end

function bloodspray:think()
    for k, blood in ipairs(self.spray) do
        blood.think(self, blood)
    end
end

function bloodspray:thinkDrip(blood)
    local x, y, a, dx, dy, da = blood.getKutta()

    local fixture, x, y, xn, yn, fraction = util.traceLine(x, y, x+dx*self.dt*2, y+dy*self.dt*2, bloodspray.collideFilter)
    if fixture then
        self:buildBlood(blood, x, y, xn, yn)
    else
        blood.x, blood.y, blood.a = blood.updateKutta(dx*-0.05 + self.gx, dy*-0.05 + self.gy, 0)
    end
end

function bloodspray:thinkPuddle()
end

function bloodspray:thinkCeilingDrip(blood)
    if blood.dripped then
        local x, y, a, dx, dy, da = blood.getKutta()
        local fixture = util.traceLine(x, y, x+dx*self.dt*2, y+dy*self.dt*2, bloodspray.collideFilter)
        if fixture then
            blood.think = bloodspray.thinkPuddle
            blood.draw = bloodspray.drawBlood
        else
            local _1, _2
            _1, blood.oy, _2 = blood.updateKutta(0, dy*-0.05 + self.gy, 0)
        end
    end
end

function bloodspray:buildBlood(blood, x, y, xn, yn)
    blood.x = x
    blood.y = y
    blood.a = math.vecToAng(xn, yn)
    
    local custom, leftW, rightW = false, puddleW, puddleW
    local x2, y2 = x+xn*0.005, y+xn*0.005
    do
        local xn2, yn2 = math.rotVecCCW(xn, yn)
        local W = self:findBloodEdge(x2, y2, xn, yn, xn2, yn2)
        if W then
            custom = true
            leftW = W
        end
    end
    do
        local xn2, yn2 = math.rotVecCW(xn, yn)
        local W = self:findBloodEdge(x2, y2, xn, yn, xn2, yn2)
        if W then
            custom = true
            rightW = W
        end
    end

    if custom then
        blood.mesh = love.graphics.newMesh({{-leftW, -puddleH}, {-leftW, puddleH}, {rightW, puddleH}, {rightW, -puddleH}}, "fan", "static")
        blood.custommesh = true
    else
        blood.mesh = bloodspray.puddle
    end
    
    blood.think = bloodspray.thinkPuddle
    -- Drip
    if math.random()>0.5 then
        local xn2, yn2 = math.rotVecCCW(xn, yn)
        local offset = math.random()*(rightW+leftW)-rightW
        blood.ox, blood.oy = x+xn2*offset, y+yn2*offset
        if yn < -0.17364 then
            blood.h = 0
            flux.to(blood, 2, { h = math.random() + 0.1 }):ease("linear"):delay(math.random()*1)
            blood.draw = bloodspray.drawFloorDrip
        elseif yn > 0.17364 then
            flux.to(blood, 1, { oy = y + 0.1 }):ease("linear"):delay(math.random()*2):oncomplete(function() blood.dripped = true end)
            blood.think = bloodspray.thinkCeilingDrip
            blood.draw = bloodspray.drawCeilingDrip
            blood.setKutta(blood.ox, y + 0.1, 0, 0, 0.05, 0)
        end
    end
end

function bloodspray:findBloodEdge(x2, y2, xn, yn, xn2, yn2)
    local hit, x3, y3, xn3, yn3, frac = util.traceLine(x2, y2, x2+xn2*puddleW, y2+yn2*puddleW, bloodspray.collideFilter)
    if hit then
        return puddleW*util.binarySearch(0, frac, 6, function(t)
            local x4, y4 = x2+xn2*puddleW*t, y2+yn2*puddleW*t
            local hit2 = util.traceLine(x4, y4, x4-xn*0.006, y4-xn*0.006, bloodspray.collideFilter)
            return hit2~=nil
        end)
    else
        local x4, y4 = x2+xn2*puddleW, y2+yn2*puddleW
        local hit2 = util.traceLine(x4, y4, x4-xn*0.006, y4-xn*0.006, bloodspray.collideFilter)
        if hit2==nil then
            return puddleW*util.binarySearch(0, 1, 6, function(t)
                local x4, y4 = x2+xn2*puddleW*t, y2+yn2*puddleW*t
                local hit3 = util.traceLine(x4, y4, x4-xn*0.006, y4-xn*0.006, bloodspray.collideFilter)
                return hit3~=nil
            end)
        end
    end
end

function bloodspray:draw()
    love.graphics.setColor( 1, 0, 0, self.alpha )
    for k, blood in ipairs(self.spray) do
        blood:draw()
    end
    love.graphics.setColor( 1, 1, 1, 1 )
end

function bloodspray.drawBlood(blood)
    love.graphics.draw(blood.mesh, blood.x, blood.y, blood.a)
end

function bloodspray.drawFloorDrip(blood)
    bloodspray.drawBlood(blood)
    love.graphics.rectangle("fill", blood.ox-0.05, blood.oy, 0.1, blood.h)
end

function bloodspray.drawCeilingDrip(blood)
    bloodspray.drawBlood(blood)
    love.graphics.rectangle("fill", blood.ox, blood.oy, 0.1, 0.1)
end

function bloodspray:destroy()
    world:removeEntity(self)
    for k, v in ipairs(self.spray) do
        if v.custommesh then
            v.mesh:release()
        end
    end
end

end)
