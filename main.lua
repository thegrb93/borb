scrw, scrh, winmode = love.window.getMode()
love.physics.setMeter(1)
love.keyboard.setTextInput(false)

class = require("lib/middleclass")
hook = require("lib/hook")
scheduler = require("lib/scheduler")()
flux = require("lib/flux")

commands = {}
model = require("lib/model")

images = setmetatable({},{__index=function(t,k)
	local r=love.graphics.newImage("img/"..k) t[k] = r return r
end})
sounds = setmetatable({},{__index=function(t,k)
	local r=love.sound.newSoundData("sound/"..k) t[k] = r return r
end})
models = setmetatable({},{__index=function(t,k)
	local r=model:new(k) t[k] = r return r
end})
fonts = setmetatable({},{__index=function(t,name)
	local r=setmetatable({},{__index=function(t2,size)
		local r2 = love.graphics.newFont("img/"..name, size) t2[size] = r2 return r2
	end}) t[name] = r return r
end})

util = require("lib/util")
util.loadTypes()

function love.run()
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
