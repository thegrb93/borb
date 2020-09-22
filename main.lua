scrw, scrh, winmode = love.window.getMode()
class = require("lib/middleclass")
hook = require("lib/hook")
scheduler = require("lib/scheduler")()
util = require("lib/util")
flux = require("lib/flux")

types = {
    bread = class("bread"),
    borb = class("borb"),
    featherProjectile = class("featherProjectile"),
    crumbs = class("crumbs"),
    snake = class("snake"),
    mosquito = class("mosquito"),
    bloodspray = class("bloodspray"),
    spawn = class("spawn"),
    spike = class("spike"),
    spring = class("spring"),
    camera = class("camera"),
}

require("world")
require("borb")
require("snake")
require("mosquito")
require("camera")
require("levelents")

function love.run()
    -- love.load(love.arg.parseGameArguments(arg), arg)
    hook.call("postload")

    -- Main loop time.
    return function()
        -- Process events.
        love.event.pump()
        for name,a,b,c,d,e,f in love.event.poll() do
            if name == "quit" then
                return a or 0
            end
            hook.call(name,a,b,c,d,e,f)
        end

        love.graphics.origin()
        love.graphics.clear(love.graphics.getBackgroundColor())
        hook.call("render")
        love.graphics.present()
    end
end
