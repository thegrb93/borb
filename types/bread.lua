addType("bread", "baseentity", function(baseentity)
local bread = types.bread

bread.graphic = images["bread.png"]
bread.originx = bread.graphic:getWidth()*0.5
bread.originy = bread.graphic:getHeight()*0.5
function bread:initialize(borb, x, y)
	baseentity.initialize(self)
	self.borb = borb
	self.drawCategory = world.drawCategories.foreground
	self.body = world.physworld:newCircleCollider(x, y, 0.5)
	self.body:setType("dynamic")
	self.body:setLinearDamping(0)
	self.body:setAngularDamping(1)
	self.body:setBullet(true)
	self.body:setObject(self)
	self.body:setCollisionClass("Player")
	self.body:setGravityScale(0)

	local fixture = self.body.fixtures.Main
	fixture:setFriction(10)
	fixture:setRestitution(1)

	self.pd = util.newPDController(self.body, 300)
end

function bread:getPos()
	return self.body:getPosition()
end

function bread:think()
	local mx, my = world.camera.transform:inverseTransformPoint(love.mouse.getPosition())
	local x, y = self.body:getPosition()
	local dx, dy = self.body:getLinearVelocity()
	local bdx, bdy = self.borb.body:getLinearVelocity()
	local diffx, diffy = mx - x, my - y
	self.pd(diffx, diffy, 0, bdx-dx, bdy-dy, 0)
end

function bread:draw()
	local x, y = self.body:getPosition()
	love.graphics.draw(self.graphic, x, y, self.body:getAngle(), 0.002, 0.002, self.originx, self.originy)
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
		local setKutta, getKutta, updateKutta = util.rungeKutta()
		local crumb = {
			active = false,
			setKutta = setKutta,
			getKutta = getKutta,
			updateKutta = updateKutta,
		}
		self.crumbs[i] = crumb
	end
end

function crumbs:addCrumb(x, y, a, dx, dy, da)
	for k, v in ipairs(self.crumbs) do
		if not v.active then
			v.active = true
			v.setKutta(x, y, a, dx, dy, da)
			break
		end
	end
end

function crumbs.crumbThink(crumb, tx, ty, tdx, tdy)
	local x, y, a, dx, dy, da = crumb.getKutta()
	local dirx, diry = tx - x, ty - y
	local dirlenSqr = math.lengthSqr(dirx, diry)
	if dirlenSqr < 1 then crumb.active = false return end

	local dirlen = math.sqrt(dirlenSqr)
	local veldot = math.max(math.dot(dirx, diry, dx, dy) / dirlen, 0)
	local tanvelx, tanvely = dx - dirx/dirlen*veldot, dy - diry/dirlen*veldot
	crumb.x, crumb.y, crumb.a = crumb.updateKutta(dirx*10 - tanvelx*5 + (tdx - dx)*0, diry*10 - tanvely*5 + (tdy - dy)*0, 0)
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
			love.graphics.draw(self.graphic, crumb.x, crumb.y, crumb.a, 0.005, 0.005, self.originx, self.originy)
		end
	end
end

end)
