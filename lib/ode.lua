local class = require("middleclass")

local ODE1 = class("ode1")

function ODE1:initialize(func, initialState)
    self.func = func
    self.state = initialState
end

function ODE1:step(dt)
    
end

return ODE1
