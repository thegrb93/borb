local wf = require("lib/windfield")
local rube = require("lib/rube")

addType("world", nil, function()
local world = types.world

world.backgroundimg = love.graphics.newImage("img/background.png")
world.backgroundw = world.backgroundimg:getWidth()*0.5
world.backgroundh = world.backgroundimg:getHeight()*0.5
function world:initialize()
    self.dt = 1/winmode.refreshrate
    self.addents = {}
    self.rments = {}
    self.addedents = {}
    self.thinkents = {}
    self.drawents = {}
    self.drawCategories = {
        "background",
        "worldforeground",
        "foreground",
        "gui"
    }
    for k, v in ipairs(self.drawCategories) do
        self.drawents[k] = {}
        self.drawCategories[v] = k
    end
    hook.add("render", self)
    hook.add("postload", self)
end

function world:postload()
    self:loadLevel("levels/level1.lua")
end

function world:loadLevel(level)
    self.t = 0
    self.physworld = wf.newWorld(0, 60, true)
    self.physworld:addCollisionClass("World", {ignores = {}})
    self.physworld:addCollisionClass("Player", {ignores = {"Player"}})
    self.physworld:addCollisionClass("Enemy", {ignores = {}})

    self.camera = types.camera:new()
    self.backcamera = types.camera:new()

    local leveldata = love.filesystem.load(level)()
    local bodies = rube(self.physworld, leveldata)

    if leveldata.image then
        for id, v in pairs(leveldata.image) do
            if v.class == "world" then
                self.foregroundimg = love.graphics.newImage("img/" .. v.file)
                self.foregroundw = self.foregroundimg:getWidth()*0.5
                self.foregroundh = self.foregroundimg:getHeight()*0.5
                self.foregroundscale = v.scale / self.foregroundimg:getHeight()
            elseif v.class then
                local meta = types[v.class]
                if meta then
                    self:addEntity(meta:new(v))
                else
                    error("Invalid type: " .. v.class)
                end
            end
        end
    end
    if leveldata.body then
        for k, v in pairs(leveldata.body) do
            if v.class then
                if v.class == "world" then
                    local body = bodies[k]
                    body:setObject(self)
                    body:setCollisionClass("World")
                else
                    local meta = types[v.class]
                    if meta then
                        self:addEntity(meta:new(bodies[k], v))
                    else
                        error("Invalid type: " .. v.class)
                    end
                end
            end
        end
    end

    hook.call("worldloaded")
end

function world:addEntity(ent)
    if self.addedents[ent] then error("Entity is already in entities list!") end
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

function world:render()
    -- Update game logic
    self.t = self.t + self.dt
    self.physworld:update(self.dt)
    flux.update(self.dt)
    scheduler:tick(self.t)
    for _, ent in ipairs(self.thinkents) do
        ent:think()
    end

    -- Update game entities
    for ent in next, self.addents do
        self.addedents[ent] = true
        self.addents[ent] = nil
        if ent.think then
            self.thinkents[#self.thinkents+1] = ent
        end
        if ent.draw then
            local drawtbl = self.drawents[ent.drawCategory]
            drawtbl[#drawtbl+1] = ent
        end
    end
    for ent in next, self.rments do
        self.addedents[ent] = nil
        self.rments[ent] = nil
        if ent.think then
            for k, e in ipairs(self.thinkents) do if ent==e then table.remove(self.thinkents, k) break end end
        end
        if ent.draw then
            local drawtbl = self.drawents[ent.drawCategory]
            for k, e in ipairs(drawtbl) do if ent==e then table.remove(drawtbl, k) break end end
        end
    end

    -- Draw game entities
    self.backcamera.zoom = self.camera.zoom*0.1
    self.backcamera:setPos(self.camera.x, self.camera.y)
    self.backcamera:update()
    self.backcamera:push()
    love.graphics.draw(world.backgroundimg, 0, 0, 0, 0.25, 0.25, world.backgroundw, world.backgroundh)
    self.backcamera:pop()

    self.camera:push()
    love.graphics.draw(self.foregroundimg, 0, 0, 0, self.foregroundscale, self.foregroundscale, self.foregroundw, self.foregroundh)
    for _, tbl in ipairs(self.drawents) do
        for _, ent in ipairs(tbl) do
            ent:draw()
        end
    end

    love.graphics.setLineWidth(0.01)
    -- self.physworld:draw()

    self.camera:pop()
end

_G.world = world:new()

end)
