local wf = require("lib/windfield")
local rube = require("lib/rube")

local world = class("world")
local levelclasses = {spawn = types.spawn, spike = types.spike}

world.backgroundimg = love.graphics.newImage( "img/background.png" )
world.backgroundw = world.backgroundimg:getWidth()*0.5
world.backgroundh = world.backgroundimg:getHeight()*0.5

function world:initialize()
    self.dt = 1/winmode.refreshrate
    self.addents = {}
    self.rments = {}
    self.addedents = {}
    self.ents = {} -- sorted by entity draworder
end

function world:loadLevel(level)
    self.t = 0
    self.physworld = wf.newWorld(0, 60, true)
    self.physworld:addCollisionClass("Player", {ignores = {"Player"}})

    self.camera = types.camera:new()
    self.backcamera = types.camera:new()

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
    self:addEntity(self.player)
end

function world:addEntity(ent)
    if self.addedents[ent] then error("Entity is already in entities list!") end
    if ent.draworder == nil then ent.draworder = 0 end
    self.addents[ent] = true
end

function world:removeEntity(ent)
    if self.addents[ent] then
        self.addents[ent] = nil
    else
        if not self.addedents[ent] then error("Entity isn't in entities list!") end
        self.rments[ent] = true
    end
end

function world:draw()
    for ent in next, self.addents do
        self.addedents[ent] = true
        self.addents[ent] = nil
        local found = false
        for k, e in ipairs(self.ents) do
            if ent.draworder <= e.draworder then
                table.insert(self.ents, k, ent)
                found = true
                break
            end
        end
        if not found then self.ents[#self.ents+1] = ent end
    end
    for ent in next, self.rments do
        self.addedents[ent] = nil
        self.rments[ent] = nil
        for k, e in ipairs(self.ents) do
            if ent==e then
                table.remove(self.ents, k)
                break
            end
        end
    end

    self.t = self.t + self.dt
    scheduler:tick(self.t)

    for _, v in ipairs(self.ents) do
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
    for _, v in ipairs(self.ents) do
        v:draw()
    end

    love.graphics.setLineWidth(0.01)
    self.physworld:draw()

    self.camera:pop()
    self.physworld:update(self.dt)
end

_G.world = world:new()


