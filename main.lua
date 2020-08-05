local class = require("lib/middleclass")
require("enums")

types = {
    bread = class("bread"),
    borb = class("borb"),
    spawn = class("spawn"),
    spike = class("spike"),
    camera = class("camera"),
}

require("world")
require("borb")
require("camera")

world:loadLevel(require("levels/level1"))

function love.wheelmoved(x,y)
    world.camera:addZoom(y)
end

function love.draw()
    world:draw()
end
