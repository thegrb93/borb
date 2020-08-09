local wf = require("lib/windfield")
local rube = require("lib/rube")
local skiplist = require("lib/skiplist")

local world = class("world")
local levelclasses = {spawn = types.spawn, spike = types.spike}

world.backgroundimg = love.graphics.newImage( "img/background.png" )
world.backgroundw = world.backgroundimg:getWidth()*0.5
world.backgroundh = world.backgroundimg:getHeight()*0.5

function world:initialize()
    self.dt = 1/winmode.refreshrate
end

function world:loadLevel(level)
    self.t = 0
    self.physworld = wf.newWorld(0, 60, true)
    self.physworld:addCollisionClass("Player", {ignores = {"Player"}})

    self.camera = types.camera:new()
    self.backcamera = types.camera:new()
    self.ents = skiplist.new()

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
    scheduler:tick(self.t)

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

    love.graphics.setLineWidth(0.01)
    self.physworld:draw()

    self.camera:pop()
    self.physworld:update(self.dt)
end

_G.world = world:new()


