local winW, winH = love.graphics.getPixelDimensions()

local class = require("middleclass")
local rube = require("rube")
local skiplist = require("skiplist")
local world = class("world")
_G.world = world
-- local halfpipe = class("halfpipe")
local borb = require("borb")
local bread = class("bread")
local camera = class("camera")
local levelclasses = {spawn = class("spawn")}

world.backgroundimg = love.graphics.newImage( "background.png" )
world.backgroundw = world.backgroundimg:getWidth()*0.5
world.backgroundh = world.backgroundimg:getHeight()*0.5
function world:initialize()
    world.myworld = self
    self.dt = 0.01666666666 --love.timer.getDelta()
    self.t = 0
    self.physworld = love.physics.newWorld(0, 10, true)
    self:loadLevel(require("level1"))

    self.camera = camera:new()
    self.backcamera = camera:new()
    self.ents = skiplist.new()
    self.player = borb:new(self.spawnpoint.x, self.spawnpoint.y, 1.5)
    self.bread = bread:new()
    self.ents:insert(self.player)
    -- self.ents:insert(halfpipe:new())
    self.ents:insert(self.bread)
    
    self.physworld:setCallbacks(
        function(a,b,coll) end,
        function(a,b,coll) end,
        function(a,b,coll) end,
        function(a,b,coll,l,t)
            local dataA, dataB = a:getUserData(), b:getUserData()
            if dataA and dataA.postSolve then dataA:postSolve(dataB,a,b,coll,l,t) end
            if dataB and dataB.postSolve then dataB:postSolve(dataA,a,b,coll,l,t) end
        end
    )
end

function world:loadLevel(leveldata)
    self.leveldata = leveldata
    local bodies = rube(self.physworld, leveldata)

    if leveldata.image then
        for id, v in pairs(leveldata.image) do
            if v.name == "world" then
                self.foregroundimg = love.graphics.newImage( v.file )
                self.foregroundw = self.foregroundimg:getWidth()*0.5
                self.foregroundh = self.foregroundimg:getHeight()*0.5
                self.foregroundscale = v.scale / self.foregroundimg:getHeight()
            else
                local obj = levelclasses[v.name]
                if obj then
                    obj:new(v)
                end
            end
        end
    end
end

function world:draw()
    self.t = self.t + self.dt
    self.backcamera.zoom = self.camera.zoom*0.1
    self.backcamera:setPos(self.camera.x, self.camera.y)
    self.backcamera:update()
    self.backcamera:push()
    love.graphics.draw(world.backgroundimg, 0, 0, 0, 0.25, 0.25, world.backgroundw, world.backgroundh)
    self.backcamera:pop()

    self.camera:push()
    love.graphics.draw(self.foregroundimg, 0, 0, 0, self.foregroundscale, self.foregroundscale, self.foregroundw, self.foregroundh)
    for _, v in self.ents:ipairs() do
        v:draw()
    end
    self.camera:pop()
    self.physworld:update(self.dt)
end

function levelclasses.spawn:initialize(data)
    world.myworld.spawnpoint = {x = data.center.x, y = -data.center.y}
end

bread.graphic = love.graphics.newImage( "bread.png" )
bread.graphicw = bread.graphic:getWidth()*0.5
bread.graphich = bread.graphic:getHeight()*0.5
function bread:initialize()
    bread.order = 1
end

function bread:getPos()
    return love.graphics.inverseTransformPoint(love.mouse.getPosition())
end

function bread:draw()
    local x, y = self:getPos()
    love.graphics.draw(bread.graphic, x, y, math.sin(world.myworld.t)*0.1, 0.002, 0.002, bread.graphicw, bread.graphich)
end

function camera:initialize()
    self.x = 0
    self.y = 0
    self.zoom = 25
    self.transform = love.math.newTransform()
    self:update()
end

function camera:push()
    love.graphics.push("transform")
    love.graphics.replaceTransform(self.transform)
end

function camera:pop()
    love.graphics.pop("transform")
end

function camera:update()
    self.transform:reset()
    self.transform:translate(winW/2, winH/2)
    self.transform:scale(self.zoom, self.zoom)
    self.transform:translate(-self.x, -self.y)
end

function camera:setPos(x, y)
    self.x = x
    self.y = y
end

function camera:addZoom(zoom)
    self.zoom = math.max(self.zoom + zoom, 1)
    self:update()
end

world:new()

function love.wheelmoved(x,y)
    world.myworld.camera:addZoom(y)
end

function love.draw()
    world.myworld:draw()
end
