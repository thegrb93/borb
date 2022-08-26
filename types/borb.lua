addType("borb", "baseentity", function(baseentity)
local borb = types.borb
local featherProjectile = types.featherProjectile

borb.radius = 1.5
borb.shape = love.physics.newCircleShape(borb.radius*0.8)
borb.jumpShape = love.physics.newCircleShape(borb.radius*0.79)
borb.floofshape = love.physics.newRectangleShape(borb.radius*1.5, borb.radius*0.5)
borb.graphic = images["borb.png"]
borb.angryeye = images["borb_angryeye.png"]
borb.feather = images["feather.png"]
borb.originx = borb.graphic:getWidth()*0.5
borb.originy = borb.graphic:getHeight()*0.5
borb.featherOriginX = borb.feather:getWidth()*0.5
borb.featherOriginY = borb.feather:getWidth()*0.5
borb.particles = love.graphics.newParticleSystem(borb.feather, 100)
borb.particles:setLinearDamping(2, 2)
borb.particles:setParticleLifetime(2, 5)
borb.particles:setSizeVariation(1)
borb.particles:setSizes(0.005, 0.005)
borb.particles:setSpin(-3, 3)
borb.particles:setRotation(-math.pi, math.pi)
borb.particles:setColors(1, 1, 1, 1, 1, 1, 1, 0)
borb.particles:setLinearAcceleration(0, 0, 0, 10)
borb.particles:setEmissionArea("ellipse", 1, 0.5, 0, false)
borb.particles:setSpread(0.6)
function borb:initialize(x, y, a)
	baseentity.initialize(self, x, y, a)
	self.drawCategory = world.drawCategories.foreground
	self.radius = borb.radius
	self.drawRadius = self.radius
	self.jumpSize = self.radius*0.5
	self.jumpNum = 8
	self.jumpSpeed = 100
	self.floofNum = 20

	self.body = world.physworld:newCollider(x, y, a)
	local fixture = self.body:addFixture("Main", borb.shape)
	fixture:setFriction(10)
	fixture:setRestitution(0.5)
	self.body:setType("dynamic")
	self.body:setLinearDamping(0)
	self.body:setAngularDamping(0)
	self.body:setBullet(true)
	self.body:setObject(self)
	self.body:setCollisionClass("Player")
	self.bodies = {self.body}
	self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()

	self.body:setPostSolve(function(collider_1, collider_2, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
		self:postSolve(collider_2:getObject(), contact, normal_impulse1)
	end)
	self.mass = self.body:getMass()
	self.inertia = self.body:getInertia()

	self.think = self.thinkAlive
	self.draw = self.drawAlive

	self.crumbs = types.crumbs:new(self.body)
	self.crumbs:spawn()

	hook.add("keypressed", self)
	hook.add("mousepressed", self)
end

function borb:onRemove()
	if self.jumping then self:endJump() self.jumping = false end
	self.body:destroy()
	hook.remove("keypressed", self)
	hook.remove("mousepressed", self)
end

function borb:keypressed()
	-- self:explode(0,-40)
end

function borb:mousepressed(x, y, button)
	if button == 1 then
		local mx, my = world.camera.transform:inverseTransformPoint(love.mouse.getPosition())
		local diffx, diffy = math.normalizeVec(mx - self.x, my - self.y)
		if diffx~=diffx then diffx, diffy = 0, 1 end
		types.featherProjectile:new(self, self.x, self.y, diffx*50, diffy*50):spawn()
	elseif button == 2 then
		local mx, my = world:screenToWorld(love.mouse.getPosition())
		types.mosquito:new(mx, my):spawn()
	end
end

function borb:postSolve(other,contact,impulse)
	if impulse>50 then
		local x, y = contact:getPositions()
		local xn, yn = util.contactNormal(self, contact)
		self.particles:setPosition(x, y)
		self.particles:emit(math.floor((impulse-50)*50))

		local shake = impulse*-0.2
		world.camera:shake(xn*shake, yn*shake, 40)
	end
	if other and other:isInstanceOf(types.spike) then
		local x, y = contact:getPositions()
		self:explode(self.x - x, self.y - y)
	end
end

function borb:thinkAlive()
	self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()
	if love.keyboard.isDown("space") then
		if not self.jumping then
			self:jump()
			self.jumping = true
		end
	else
		if self.jumping then
			self:endJump()
			self.jumping = false
		end
	end
	self:jumpThink()

	if love.keyboard.isDown("a") then
		self.body:applyForce(math.min(-500 - self.dx*40, -50), 0)
	elseif love.keyboard.isDown("d") then
		self.body:applyForce(math.max(500 - self.dx*40, 50), 0)
	end

	self.particles:setSpeed(math.length(self.dx, self.dy)*0.5)
	self.particles:setDirection(math.atan2(self.dy, self.dx))

	world.camera:setPos(self.x, self.y)
end

function borb:thinkDead()
end

function borb:drawAlive()
	love.graphics.push()
	love.graphics.applyTransform(love.math.newTransform(self.x, self.y, self.a, self.drawRadius/borb.originx, self.drawRadius/borb.originy, borb.originx, borb.originy))
	love.graphics.draw(borb.graphic)
	if self.jumping then
		love.graphics.draw(borb.angryeye, 241, 83)
	end
	love.graphics.pop()

	self.particles:update(dt)
	love.graphics.draw(self.particles)
end

function borb:drawDead()
	for _, floof in ipairs(self.floofs) do
		local x, y = floof:getWorldCenter()
		local dx, dy = floof:getLinearVelocity()
		local angle = floof:getAngle()
		love.graphics.draw(borb.feather, x, y, angle, 0.01, 0.01, borb.featherOriginX, borb.featherOriginY)
		-- util.drawBody(floof.body, self.floof.shape)
	end
end

function borb:jump()
	local mass = self.mass/(1+self.jumpNum)
	local inertia = self.inertia/(1+self.jumpNum)
	self.body:setMass(mass)
	self.body:setInertia(inertia)
	self.jumpEnts = {}
	for i=1, self.jumpNum do
		local body = world.physworld:newCollider(self.x, self.y, 0)
		local fixture = body:addFixture("Main", borb.jumpShape)
		fixture:setFriction(10)
		fixture:setRestitution(0.2)
		body:setMass(mass)
		body:setInertia(inertia)
		body:setInertia(0.5)
		body:setType("dynamic")
		body:setLinearDamping(0)
		body:setAngularDamping(0)
		body:setLinearVelocity(self.dx, self.dy)
		body:setAngularVelocity(self.da)
		body:setCollisionClass("Player")
		body:setObject(self)

		local ang = 2*math.pi*i/self.jumpNum
		local joint = love.physics.newPrismaticJoint(self.body.body, body.body, self.x, self.y, self.x, self.y, math.cos(ang), math.sin(ang), false)
		joint:setLimitsEnabled(true)
		joint:setLimits(0, self.jumpSize)
		joint:setMotorEnabled(true)
		joint:setMotorSpeed(self.jumpSpeed*10)
		joint:setMaxMotorForce(200)

		self.jumpEnts[i] = {body = body, joint = joint}
	end
end

function borb:jumpThink()
	if self.jumping then
		local maxR = 0
		for i, jump in ipairs(self.jumpEnts) do
			local x, y = jump.body:getWorldCenter()
			local R = math.lengthSqr(self.x - x, self.y - y)
			jump.joint:setMaxMotorForce((self.jumpSize^2 - R)*3000)
			if R>maxR then maxR = R end
		end
		self.drawRadius = self.radius+math.sqrt(maxR)
	else
		self.drawRadius = self.radius
	end
end

function borb:endJump()
	for i, jump in ipairs(self.jumpEnts) do
		jump.body:destroy()
	end
	self.body:setMass(self.mass)
	self.body:setInertia(self.inertia)
end

function borb:explode(velx, vely)
	if self.think == self.thinkDead then return end
	if self.jumping then self:endJump() self.jumping = false end
	self.body:setActive(false)

	local variance = 20
	self.floofs = {}
	for i=1, self.floofNum do
		local floof = world.physworld:newRectangleCollider(self.x, self.y, math.random()*math.pi*2)
		floof:setType("dynamic")
		floof:setLinearDamping(1)
		floof:setAngularDamping(0.1)
		floof:setLinearVelocity(self.dx + velx + math.random()*variance, self.dy + vely + math.random()*variance)
		floof:setAngularVelocity((math.random()-0.5)*variance*5)
		floof:setCollisionClass("Player")

		local fixture = floof:addFixture("Main", borb.floofshape)
		fixture:setFriction(1)
		fixture:setRestitution(0.5)

		self.floofs[i] = floof
	end
	self.think = self.thinkDead
	self.draw = self.drawDead
end

function borb:serialize(buffer)
	buffer[#buffer+1] = love.data.pack("string", "<ddd", self.x, self.y, self.radius)
end

function borb.deserialize(buffer, pos)
	local x, y, radius
	x, y, radius, pos = love.data.unpack("<ddd", buffer, pos)
	return borb:new(x, y, radius), pos
end

end)

addType("featherProjectile", "baseentity", function(baseentity)
local borb = types.borb
local featherProjectile = types.featherProjectile

featherProjectile.feather = images["feather.png"]
featherProjectile.shape = love.physics.newCircleShape(0.5)
featherProjectile.featherOriginX = featherProjectile.feather:getWidth()*0.5
featherProjectile.featherOriginY = featherProjectile.feather:getWidth()*0.5
function featherProjectile:initialize(borb, x, y, dx, dy)
	baseentity.initialize(self, x, y, math.vecToAng(dx, dy))
	self.borb = borb
	self.drawCategory = world.drawCategories.foreground
	self.body = world.physworld:newCollider(x, y, self.a)
	self.body:setType("dynamic")
	self.body:setLinearVelocity(dx, dy)
	self.body:setLinearDamping(0)
	self.body:setAngularDamping(0)
	self.body:setBullet(true)
	self.body:setObject(self)
	self.body:setCollisionClass("Player")
	self.body:setPostSolve(function(collider_1, collider_2, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
		self:postSolve(collider_2:getObject(), contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
	end)
	self.bodies = {self.body}

	local fixture = self.body:addFixture("Main", featherProjectile.shape)
	fixture:setFriction(10)
	fixture:setRestitution(1)

	self.pd = util.newPDController(self.body, 300)
end

function featherProjectile:postSolve(other, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
	if other and other.onDamage then
		local x, y = contact:getPositions()
		local xn, yn = util.contactNormal(self, contact)
		other:onDamage(x, y, xn, yn)
	end
	self:remove()
end

function featherProjectile:getPos()
	return self.body:getPosition()
end

function featherProjectile:think()
	self.pd(0, 0, math.angnorm(math.vecToAng(self.body:getLinearVelocity()) - self.body:getAngle()), 0, 0, -self.body:getAngularVelocity())
end

function featherProjectile:draw()
	local x, y = self.body:getPosition()
	love.graphics.draw(self.feather, x, y, self.body:getAngle()+2.3, 0.01, 0.01, self.featherOriginX-50, self.featherOriginY+30)
end

function featherProjectile:onRemove()
	self.body:destroy()
end

end)

addType("bread", "baseentity", function(baseentity)
local bread = types.bread

bread.graphic = images["bread.png"]
bread.shape = love.physics.newRectangleShape(1.7, 1.7)
bread.originx = bread.graphic:getWidth()*0.5
bread.originy = bread.graphic:getHeight()*0.5
function bread:initialize(x, y, a)
	baseentity.initialize(self, x, y, a)
	self.drawCategory = world.drawCategories.foreground
	self.body = world.physworld:newCollider(x, y, 0)
	self.body:setType("dynamic")
	self.body:setBullet(true)
	self.body:setObject(self)
	self.body:setCollisionClass("Player")
	self.bodies = {self.body}

	local fixture = self.body:addFixture("Main", bread.shape)
	fixture:setFriction(10)
end

function bread:getPos()
	return self.body:getState()
end

function bread:think()
	local x, y = self:getPos()

	-- local mx, my = self.bread:getPos()
	-- local rx, ry = mx - self.x, my - self.y
	-- local mag = math.max(math.lengthSqr(rx, ry), 4)
	-- if mag<64 then
		-- self.body:applyForce(rx/mag*500, ry/mag*500)
		-- local mdx, mdy = self.bread.body:getLinearVelocity()
		-- local trx, try = ry, -rx
		-- for i=1, 10 do
			-- if math.random() > 1-(1-math.sqrt(mag)/8)*0.25 then
				-- self.crumbs:addCrumb(mx, my, math.random()*math.pi*2, mdx+(math.random()-0.5)*trx*10, mdy+(math.random()-0.5)*try*10, self.bread.body:getAngularVelocity())
			-- end
		-- end
	-- end
end

function bread:draw()
	local x, y, a = self:getPos()
	love.graphics.draw(self.graphic, x, y, a, 0.002, 0.002, self.originx, self.originy)
end

function bread:serialize(buffer)
	local x, y, a = self:getPos()
	buffer[#buffer+1] = love.data.pack("string", "<ddd", x, y, a)
end

function bread.deserialize(buffer, pos)
	local x, y, a
	x, y, a, pos = love.data.unpack("<ddd", buffer, pos)
	return bread:new(x, y, a), pos
end
end)

addType("crumbs", "baseentity", function(baseentity)
local crumbs = types.crumbs

crumbs.graphic = images["crumb.png"]
crumbs.originx = crumbs.graphic:getWidth()*0.5
crumbs.originy = crumbs.graphic:getHeight()*0.5
function crumbs:initialize(target)
	baseentity.initialize(self)
	self.target = target
	self.drawCategory = world.drawCategories.foreground
	self.maxcrumbs = 100

	self.crumbs = {}
	for i=1, self.maxcrumbs do
		local crumb = {
			active = false,
			kutta = util.rungeKutta(0,0,0,0,0,0)
		}
		self.crumbs[i] = crumb
	end
end

function crumbs:addCrumb(x, y, a, dx, dy, da)
	for k, v in ipairs(self.crumbs) do
		if not v.active then
			v.active = true
			v.kutta.x, v.kutta.y, v.kutta.a, v.kutta.dx, v.kutta.dy, v.kutta.da = x, y, a, dx, dy, da
			break
		end
	end
end

function crumbs.crumbThink(crumb, tx, ty, tdx, tdy)
	local x, y, a, dx, dy, da = crumb.kutta.x, crumb.kutta.y, crumb.kutta.a, crumb.kutta.dx, crumb.kutta.dy, crumb.kutta.da
	local dirx, diry = tx - x, ty - y
	local dirlenSqr = math.lengthSqr(dirx, diry)
	if dirlenSqr < 1 then crumb.active = false return end

	local dirlen = math.sqrt(dirlenSqr)
	local veldot = math.max(math.dot(dirx, diry, dx, dy) / dirlen, 0)
	local tanvelx, tanvely = dx - dirx/dirlen*veldot, dy - diry/dirlen*veldot
	crumb.kutta(dirx*10 - tanvelx*5 + (tdx - dx)*0, diry*10 - tanvely*5 + (tdy - dy)*0, 0)
end

function crumbs:think()
	if self.target:isDestroyed() then self:remove() return end
	local tx, ty = self.target:getPosition()
	local tdx, tdy = self.target:getLinearVelocity()
	for k, crumb in ipairs(self.crumbs) do
		if crumb.active then
			self.crumbThink(crumb, tx, ty, tdx, tdy)
		end
	end
end

function crumbs:draw()
	for k, crumb in ipairs(self.crumbs) do
		if crumb.active then
			love.graphics.draw(self.graphic, crumb.kutta.x, crumb.kutta.y, crumb.kutta.a, 0.005, 0.005, self.originx, self.originy)
		end
	end
end

end)

