local class = require("lib/middleclass")
local rube = require("lib/rube")
local skiplist = require("lib/skiplist")

local world = class("world")
local levelclasses = {spawn = types.spawn, spike = types.spike}

world.backgroundimg = love.graphics.newImage( "img/background.png" )
world.backgroundw = world.backgroundimg:getWidth()*0.5
world.backgroundh = world.backgroundimg:getHeight()*0.5

function world:initialize()
    self.dt = 0.01666666666 --love.timer.getDelta()
end

function world:loadLevel(level)
    self.t = 0
    self.physworld = love.physics.newWorld(0, 10, true)

    self.camera = types.camera:new()
    self.backcamera = types.camera:new()
    self.ents = skiplist.new()
    
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

    local leveldata = love.filesystem.load(level)()
    local bodies = rube(self.physworld, leveldata)

    if leveldata.image then
        for id, v in pairs(leveldata.image) do
            if v.name == "world" then
                self.foregroundimg = love.graphics.newImage( "img/" .. v.file )
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
    
    self.player = types.borb:new(self.spawnpoint.x, self.spawnpoint.y, 1.5)
    self.ents:insert(self.player)
end

function world:draw()
    self.t = self.t + self.dt
    for _, v in self.ents:ipairs() do
        v:think()
    end
    
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


function types.spawn:initialize(data)
    world.spawnpoint = {x = data.center.x, y = -data.center.y}
end

function types.spike:initialize(data)
    self.x, self.y = data.center.x, -data.center.y
    world.ents:insert(self)
end

function types.spike:draw(data)
    
end

_G.world = world:new()
