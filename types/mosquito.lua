addType("mosquito", "baseentity", function(baseentity)
local mosquito = types.mosquito
local bloodspray = types.bloodspray

mosquito.graphic = images["triangle.png"]
-- mosquito.graphic = images["mosquito.png"]
mosquito.graphicw = mosquito.graphic:getWidth()
mosquito.graphich = mosquito.graphic:getHeight()
mosquito.graphicmap = {
	maxt = 1,
	{t = 0.1, u1 = 0/3, v1 = 0/3, u2 = 1/3, v2 = 1/3},
	{t = 0.2, u1 = 1/3, v1 = 0/3, u2 = 2/3, v2 = 1/3},
	{t = 0.3, u1 = 3/3, v1 = 0/3, u2 = 3/3, v2 = 1/3},
	{t = 0.4, u1 = 0/3, v1 = 1/3, u2 = 1/3, v2 = 2/3},
	{t = 0.5, u1 = 1/3, v1 = 1/3, u2 = 2/3, v2 = 2/3},
	{t = 0.6, u1 = 3/3, v1 = 1/3, u2 = 3/3, v2 = 2/3},
	{t = 0.7, u1 = 0/3, v1 = 2/3, u2 = 1/3, v2 = 3/3},
	{t = 0.8, u1 = 1/3, v1 = 2/3, u2 = 2/3, v2 = 3/3},
	{t = 0.9, u1 = 3/3, v1 = 2/3, u2 = 3/3, v2 = 3/3},
}

function mosquito.staticinit()
	mosquito.sprite = types.animatedSpriteBlurred:new(mosquito.graphic, mosquito.graphicmap)
	mosquito.shape = love.physics.newCircleShape(1)
end

function mosquito:initialize(x, y)
	baseentity.initialize(self, x, y, 0)
	self.drawCategory = world.drawCategories.foreground

	self.targetx, self.targety = x, y
	self.body = world.physworld:newCollider(x, y, 0)
	self.body:setType("dynamic")
	self.body:setLinearDamping(0)
	self.body:setAngularDamping(0)
	self.body:setBullet(true)
	self.body:setObject(self)
	self.body:setCollisionClass("Enemy")
	self.body:setGravityScale(0)

	self.body:setPostSolve(function(collider_1, collider_2, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
		self:postSolve(collider_2:getObject(), contact, normal_impulse1)
	end)

	local fixture = self.body:addFixture("Main", mosquito.shape)
	fixture:setFriction(10)
	fixture:setRestitution(0.5)

	self.pd = util.newPDController(self.body, 20)

	self.think = mosquito.aliveThink
	self.draw = mosquito.aliveDraw
	self.alive = true
	self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()
end

function mosquito:postSolve(other, contact, normal_impulse)
	if self.alive then
	else
		normal_impulse = normal_impulse * 0.01
		local nx, ny = contact:getNormal()
		self:onDamage(self.x, self.y, nx*normal_impulse, ny*normal_impulse)
		self:remove()
	end
end

function mosquito:onDamage(x, y, xn, yn)
	bloodspray:new(x, y, xn*10, yn*10):spawn()
	self.body:setGravityScale(1)
	self.think = self.deadThink
	self.draw = self.deadDraw
	self.alive = false
end

function mosquito:onRemove()
	self.body:destroy()
end

function mosquito:aliveThink()
	self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()
	self.pd(self.targetx - self.x, self.targety - self.y, 0 - self.a, -self.dx, -self.dy, -self.da)

	local pl = world.player
	if math.lengthSqr(pl.x - self.x, pl.y - self.y) < 100 then
		self.think = mosquito.chaseThink
	end
end

function mosquito:chaseThink()
	self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()

	local pl = world.player
	local dx, dy = math.normalizeVec(pl.x - self.x, pl.y - self.y)
	self.targetx, self.targety = self.x + dx*3, self.y + dy*3

	local tx, ty = math.rotVecCW(dx, dy)
	local wave = math.sin(world.t*5)*5

	self.pd(self.targetx - self.x, self.targety - self.y, math.angnorm(math.vecToAng(dx, dy)) - self.a, tx*wave-self.dx, ty*wave-self.dy, -self.da)
end

function mosquito:deadThink()
	self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()
end

function mosquito:aliveDraw()
	-- love.graphics.circle("fill", self.x, self.y, 1)
	mosquito.sprite:draw(world.t, 0.2, self.x, self.y, self.a, 2, 2)
end

function mosquito:deadDraw()
	-- love.graphics.circle("fill", self.x, self.y, 1)
	mosquito.sprite:draw(world.t, 0.2, self.x, self.y, self.a, 2, 2)
end

end)
