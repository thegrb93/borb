scrw, scrh, winmode = love.window.getMode()
class = require("lib/middleclass")
hook = require("lib/hook")
scheduler = require("lib/scheduler")()
util = require("lib/util")
flux = require("lib/flux")

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
require("levelents")

function love.run()
	-- love.load(love.arg.parseGameArguments(arg), arg)
	world:loadLevel("levels/level1.lua")
 
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
		world:draw()
		love.graphics.present()
	end
end
