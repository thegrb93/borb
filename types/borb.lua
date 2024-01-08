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
	self.bloopState = {x = 0, dx = 0}

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

	hook.add("keypressed", self)
	hook.add("mousepressed", self)
end

function borb:onRemove()
	if self.jumping then self:endJump() self.jumping = false end
	self.body:destroy()
	hook.remove("keypressed", self)
	hook.remove("mousepressed", self)
end

function borb:getState()
	return self.body:getState()
end

function borb:keypressed()
	-- self:explode(0,-40)
end

function borb:bloop(mag)
	self.bloopState.dx = self.bloopState.dx + mag
end

function borb:mousepressed(x, y, button)
	if button == 1 then
		local mx, my = world.camera.transform:inverseTransformPoint(love.mouse.getPosition())
		local diffx, diffy = math.normalizeVec(mx - self.x, my - self.y)
		types.featherProjectile:new(self, self.x, self.y, self.dx+diffx*50, self.dy+diffy*50):spawn()
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

		local shake = impulse*-0.3
		world.camera:addShake(xn*shake, yn*shake, 40)
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

	for _, v in ipairs(world.physworld:queryRectangleArea(self.x - self.radius*1.4, self.y - self.radius*1.4, self.radius*2.8, self.radius*2.8, {"Item"})) do
		v:getObject():use(self)
	end
	util.eulerIntegrate1D(self.bloopState, -self.bloopState.x*3000 - self.bloopState.dx*15)

	self.particles:setSpeed(math.length(self.dx, self.dy)*0.5)
	self.particles:setDirection(math.vecToAng(self.dx, self.dy))

	world.camera:setPos(self.x, self.y)
end

function borb:thinkDead()
end

function borb:drawAlive()
	local radius = self.bloopState.x + self.drawRadius
	love.graphics.push("transform")
	love.graphics.applyTransform(love.math.newTransform(self.x, self.y, self.a, radius/borb.originx, radius/borb.originy, borb.originx, borb.originy))
	love.graphics.draw(borb.graphic)
	if self.jumping then
		love.graphics.draw(borb.angryeye, 241, 83)
	end
	love.graphics.pop("transform")

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
featherProjectile.shape = love.physics.newCircleShape(0.2)
featherProjectile.featherOriginX = 12
featherProjectile.featherOriginY = 170
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
	love.graphics.draw(self.feather, x, y, self.body:getAngle()-2.5, 0.01, 0.01, self.featherOriginX, self.featherOriginY)
end

function featherProjectile:onRemove()
	self.body:destroy()
end

end)

addType("bread", "item", function(item)
local bread = types.bread

bread.graphic = images["bread.png"]
bread.shape = love.physics.newRectangleShape(1.7, 1.7)
bread.originx = bread.graphic:getWidth()*0.5
bread.originy = bread.graphic:getHeight()*0.5
function bread:initialize(x, y, a)
	item.initialize(self, x, y, a)
	self.drawCategory = world.drawCategories.foreground
	self.body = world.physworld:newCollider(x, y, 0)
	self.body:setType("dynamic")
	self.body:setBullet(true)
	self.body:setObject(self)
	self.body:setCollisionClass("Item")
	self.bodies = {self.body}

	local fixture = self.body:addFixture("Main", bread.shape)
	fixture:setFriction(10)

	self.crumbs = types.crumbs:new()
	self.crumbs:spawn()
	self.ncrumbs = 50
end

function bread:getState()
	return self.body:getState()
end

function bread:use(user)
	self.crumbs.targetent = user
	local ux, uy = user:getState()
	local x, y, a, mdx, mdy, mda = self:getState()
	local rx, ry = ux - x, uy - y
	local len = math.clamp(math.length(rx, ry), 0.2, 10)
	local trx, try = math.rotVecCCW(rx, ry)
	for i=1, 10 do
		if math.random() > 1-(1-len/10)*0.05 then
			local tvel = (math.random()-0.5)*10
			self.crumbs:addCrumb(x, y, math.random()*math.pi*2, mdx+tvel*trx, mdy+tvel*try, mda)
			self.body:applyAngularImpulse((math.random()-0.5)*50)
			self.ncrumbs = self.ncrumbs - 1
			if self.ncrumbs == 0 then
				self:remove()
			end
		end
	end
end

function bread:draw()
	local x, y, a = self:getState()
	love.graphics.draw(self.graphic, x, y, a, 0.002, 0.002, self.originx, self.originy)
end

function bread:onRemove()
	self.body:destroy()
end

function bread:serialize(buffer)
	local x, y, a = self:getState()
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
function crumbs:initialize()
	baseentity.initialize(self)
	self.drawCategory = world.drawCategories.foreground
	self.maxcrumbs = 100

	self.crumbs = {}
	for i=1, self.maxcrumbs do
		self.crumbs[i] = {active = false}
	end
end

function crumbs:addCrumb(x, y, a, dx, dy, da)
	for k, v in ipairs(self.crumbs) do
		if not v.active then
			v.active = true
			v.x, v.y, v.a, v.dx, v.dy, v.da = x, y, a, dx, dy, da
			break
		end
	end
end

function crumbs:crumbThink(crumb, tx, ty, tdx, tdy)
	local dirx, diry = tx - crumb.x, ty - crumb.y
	local dirlenSqr = math.lengthSqr(dirx, diry)
	if dirlenSqr < 1 then crumb.active = false self.targetent:bloop(3+math.random()*2) return end

	local dirlen = math.sqrt(dirlenSqr)
	local veldot = math.max(math.dot(dirx, diry, crumb.dx, crumb.dy) / dirlen, 0)
	local tanvelx, tanvely = crumb.dx - dirx/dirlen*veldot, crumb.dy - diry/dirlen*veldot
	util.eulerIntegrate3D(crumb, dirx*10 - tanvelx*5 + (tdx - crumb.dx)*0, diry*10 - tanvely*5 + (tdy - crumb.dy)*0, 0)
end

function crumbs:think()
	if not self.targetent then return end
	local tx, ty, ta, tdx, tdy = self.targetent:getState()
	for k, crumb in ipairs(self.crumbs) do
		if crumb.active then
			self:crumbThink(crumb, tx, ty, tdx, tdy)
		end
	end
end

function crumbs:draw()
	for k, crumb in ipairs(self.crumbs) do
		if crumb.active then
			love.graphics.draw(self.graphic, crumb.x, crumb.y, crumb.a, 0.005, 0.005, self.originx, self.originy)
		end
	end
end

end)

