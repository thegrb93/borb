local class = require("middleclass")

local animation = class("animation")

local animationFuncs = {
    linear = function(frac1, frac2, x)
        return frac2*x[1] + frac1*x[2]
    end,
    cubicBezier = function(frac1, frac2, x)
        return frac2^3*x[1] + 3*frac2^2*frac1*x[2] + 3*frac2*frac1^2*x[3] + frac1^3*x[4]
    end
}

function animation:initialize(duration, data, type, looping)
    self.duration = duration
    self.data = data
    self.func = animationFuncs[type]
    self.looping = looping
end

function animation:reset(time)
    self.startTime = time
end

function animation:set(time, frac)
    self.startTime = time - frac*self.duration
end

function animation:get(t)
    local frac1
    if self.looping then
        frac1 = ((t - self.startTime) % self.duration)/self.duration
    else
        frac1 = math.max(math.min((t - self.startTime)/self.duration, 1), 0)
    end
    local frac2 = 1-frac1
    local result = {}
    for i=1, #self.data do
        result[i] = self.func(frac1, frac2, self.data[i])
    end
    return result
end

return animation
