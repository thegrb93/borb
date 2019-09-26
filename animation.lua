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

function animation:initialize(duration, data, type)
    self.duration = duration
    self.data = data
    self.func = animationFuncs[type]
end

function animation:reset(time)
    self.startTime = time
end

function animation:set(time, frac)
    self.startTime = time - frac*self.duration
end

function animation:get(t)
    local frac1 = math.max(math.min((t - self.startTime)/self.duration, 1), 0)
    local frac2 = 1-frac
    local result = {}
    for i=1, #data do
        result[i] = self.func(frac1, frac2, data[i])
    end
    return result
end

return animation
