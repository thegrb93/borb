addType("borb", "baseentity", function(baseentity)
local borb = types.borb
local bread = types.bread
local crumbs = types.crumbs
local featherProjectile = types.featherProjectile

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
function borb:initialize(x, y, radius)
	baseentity.initialize(self)
	self.drawCategory = world.drawCategories.foreground
	self.radius = radius
	self.drawRadius = radius
	self.jumpRadius = self.radius*0.79
	self.jumpSize = self.radius*0.5
	self.jumpNum = 8
	self.jumpSpeed = 100
	self.floofNum = 20

	self.body = world.physworld:newCircleCollider(x, y, self.radius*0.8)
	self.body:setType("dynamic")
	self.body:setLinearDamping(0)
	self.body:setAngularDamping(0)
	self.body:setBullet(true)
	self.body:setObject(self)
	self.body:setCollisionClass("Player")
	self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()

	local fixture = self.body.fixtures.Main
	fixture:setFriction(10)
	fixture:setRestitution(0.5)
	self.body:setPostSolve(function(collider_1, collider_2, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
		self:postSolve(collider_2:getObject(), contact, normal_impulse1)
	end)
	self.mass = self.body:getMass()
	self.inertia = self.body:getInertia()

	self.bread = bread:new(self, x, y-1)
	self.bread:spawn()
	self.crumbs = crumbs:new(self.body)
	self.crumbs:spawn()

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
		local mx, my = world.camera.transform:inverseTransformPoint(love.mouse.getPosition())
		types.mosquito:new(mx, my):spawn()
	end
end

function borb:postSolve(other,contact,impulse)
	if impulse>50 then
		local x, y = contact:getPositions()
		self.particles:setPosition(x, y)
		self.particles:emit(math.floor((impulse-50)*50))
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

	self.particles:setSpeed(math.length(self.dx, self.dy)*0.5)
	self.particles:setDirection(math.atan2(self.dy, self.dx))

	world.camera:setPos(self.x, self.y)
	world.camera:update()
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

	self.particles:update(world.dt)
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
		local body = world.physworld:newCircleCollider(self.x, self.y, self.jumpRadius)
		body:setMass(mass)
		body:setInertia(inertia)
		body:setInertia(0.5)
		body:setType("dynamic")
		body:setLinearDamping(0)
		body:setAngularDamping(0)
		body:setLinearVelocity(self.dx, self.dy)
		body:setCollisionClass("Player")
		body:setObject(self)
		body.fixtures.Main:setFriction(10)
		body.fixtures.Main:setRestitution(0.2)

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
		local floof = world.physworld:newRectangleCollider(self.x, self.y, self.radius*1.5, self.radius*0.5)
		floof:setType("dynamic")
		floof:setAngle(math.random()*math.pi*2)
		floof:setLinearDamping(1)
		floof:setAngularDamping(0.1)
		floof:setLinearVelocity(self.dx + velx + math.random()*variance, self.dy + vely + math.random()*variance)
		floof:setAngularVelocity((math.random()-0.5)*variance*5)
		floof:setCollisionClass("Player")
		floof.fixtures.Main:setFriction(1)
		floof.fixtures.Main:setRestitution(0.5)
		self.floofs[i] = floof
	end
	self.think = self.thinkDead
	self.draw = self.drawDead
end

end)

addType("featherProjectile", "baseentity", function(baseentity)
local borb = types.borb
local featherProjectile = types.featherProjectile

featherProjectile.feather = images["feather.png"]
featherProjectile.featherOriginX = featherProjectile.feather:getWidth()*0.5
featherProjectile.featherOriginY = featherProjectile.feather:getWidth()*0.5
function featherProjectile:initialize(borb, x, y, dx, dy)
	baseentity.initialize(self)
	self.borb = borb
	self.drawCategory = world.drawCategories.foreground
	self.body = world.physworld:newCircleCollider(x, y, 0.5)
	self.body:setType("dynamic")
	self.body:setAngle(math.vecToAng(dx, dy))
	self.body:setLinearVelocity(dx, dy)
	self.body:setLinearDamping(0)
	self.body:setAngularDamping(0)
	self.body:setBullet(true)
	self.body:setObject(self)
	self.body:setCollisionClass("Player")
	self.body:setPostSolve(function(collider_1, collider_2, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
		self:postSolve(collider_2:getObject(), contact)
	end)

	local fixture = self.body.fixtures.Main
	fixture:setFriction(10)
	fixture:setRestitution(1)

	self.pd = util.newPDController(self.body, 300)
end

function featherProjectile:postSolve(other, contact)
	if other and other.onDamage then
		local x, y = contact:getPositions()
		local xn, yn = contact:getNormal()
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

