local class = require("lib/middleclass")
local hook = require("lib/hook")
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

world:loadLevel("levels/level1.lua")

function love.wheelmoved(x,y)
	world.camera:addZoom(y)
end

function love.run()
	-- love.load(love.arg.parseGameArguments(arg), arg)
 
	-- Main loop time.
	return function()
		-- Process events.
		love.event.pump()
		for name,a,b,c,d,e,f in love.event.poll() do
			if name == "quit" then
				if not love.quit or not love.quit() then
					return a or 0
				end
			end
			hook.call(name,a,b,c,d,e,f)
		end
 
		love.graphics.origin()
		love.graphics.clear(love.graphics.getBackgroundColor())
		world:draw()
		love.graphics.present()
	end
end
