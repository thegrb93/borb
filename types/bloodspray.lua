addType("bloodspray", "baseentity", function(baseentity)
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
	baseentity.initialize(self)
	self.drawCategory = world.drawCategories.worldforeground
	self.maxblood = 30
	self.dt = dt
	self.gx, self.gy = world.physworld:getGravity()

	self.spray = {}
	for i=1, self.maxblood do
		local rx, ry = math.randVecSquare()
		local blood = {
			x = x+rx*0.2,
			y = y+ry*0.2,
			a = math.random()*2*math.pi,
			dx = dx+rx*10,
			dy = dy+ry*10,
			da = math.random()*4-2,
			think = bloodspray.thinkDrip,
			mesh = bloodspray.drip,
			draw = bloodspray.drawBlood,
		}
		self.spray[i] = blood
	end
	
	self.alpha = 1
	flux.to(self, 2, { alpha = 0 }):ease("linear"):delay(10):oncomplete(function() self:remove() end)
end

function bloodspray:think()
	for k, blood in ipairs(self.spray) do
		blood.think(self, blood)
	end
end

function bloodspray:thinkDrip(blood)
	local fixture, x, y, xn, yn, fraction = util.traceLine(blood.x, blood.y, blood.x+blood.dx*self.dt*2, blood.y+blood.dy*self.dt*2, bloodspray.collideFilter)
	if fixture then
		self:buildBlood(blood, x, y, xn, yn)
	else
		util.eulerIntegrate3D(blood, blood.dx*-0.05 + self.gx, blood.dy*-0.05 + self.gy, 0)
	end
end

function bloodspray:thinkPuddle()
end

function bloodspray:thinkCeilingDrip(blood)
	local fixture = util.traceLine(blood.drip.x, blood.drip.y, blood.drip.x+blood.drip.dx*self.dt*2, blood.drip.y+blood.drip.dy*self.dt*2, bloodspray.collideFilter)
	if fixture then
		blood.think = bloodspray.thinkPuddle
		blood.draw = bloodspray.drawBlood
	else
		util.eulerIntegrate2D(blood.drip, 0, blood.drip.dy*-0.05 + self.gy, 0)
	end
end

function bloodspray:buildBlood(blood, x, y, xn, yn)
	blood.x = x
	blood.y = y
	blood.a = math.vecToAng(xn, yn)+math.pi*0.5
	
	local custom, leftW, rightW = false, puddleW, puddleW
	local x2, y2 = x+xn*0.005, y+yn*0.005
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
		blood.drip = {x = x+xn2*offset, y = y+yn2*offset, dx = 0, dy = 0}
		if yn < -0.17364 then
			blood.h = 0
			flux.to(blood, 2, { h = math.random() + 0.1 }):ease("linear"):delay(math.random()*1)
			blood.draw = bloodspray.drawFloorDrip
		elseif yn > 0.17364 then
			flux.to(blood.drip, 1, { y = blood.drip.y + 0.1 }):ease("linear"):delay(math.random()*2):oncomplete(function()
				blood.think = bloodspray.thinkCeilingDrip
				blood.drip.dy = 0.05
			end)
			blood.draw = bloodspray.drawCeilingDrip
		end
	end
end

function bloodspray:findBloodEdge(x2, y2, xn, yn, xn2, yn2)
	local hit, _, _, _, _, frac = util.traceLine(x2, y2, x2+xn2*puddleW, y2+yn2*puddleW, bloodspray.collideFilter)
	if hit then
		return puddleW*util.binarySearch(0, frac, 6, function(t)
			local x4, y4 = x2+xn2*puddleW*t, y2+yn2*puddleW*t
			local hit2 = util.traceLine(x4, y4, x4-xn*0.006, y4-yn*0.006, bloodspray.collideFilter)
			return hit2~=nil
		end)
	else
		local x4, y4 = x2+xn2*puddleW, y2+yn2*puddleW
		local hit2 = util.traceLine(x4, y4, x4-xn*0.006, y4-yn*0.006, bloodspray.collideFilter)
		if hit2==nil then
			return puddleW*util.binarySearch(0, 1, 6, function(t)
				local x4, y4 = x2+xn2*puddleW*t, y2+yn2*puddleW*t
				local hit3 = util.traceLine(x4, y4, x4-xn*0.006, y4-yn*0.006, bloodspray.collideFilter)
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
	love.graphics.rectangle("fill", blood.drip.x-0.05, blood.drip.y, 0.1, blood.h)
end

function bloodspray.drawCeilingDrip(blood)
	bloodspray.drawBlood(blood)
	love.graphics.rectangle("fill", blood.drip.x-0.05, blood.drip.y-0.05, 0.1, 0.1)
end

function bloodspray:onRemove()
	for k, v in ipairs(self.spray) do
		if v.custommesh then
			v.mesh:release()
		end
	end
end

end)
