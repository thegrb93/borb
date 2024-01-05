local class = require("lib/middleclass")
local hook = {}
local hooktbl = class("hooktbl")

function hooktbl:initialize()
    self.hooks = {}
    self.hookstoadd = {}
    self.hookstoremove = {}
    self.call = self.callclean
end

function hooktbl:add(id)
    self.hookstoadd[id] = true
    self.hookstoremove[id] = nil
    self.call = self.calldirty
end

function hooktbl:remove(id)
    self.hookstoadd[id] = nil
    self.hookstoremove[id] = true
    self.call = self.calldirty
end

function hooktbl:calldirty(...)
    local i = 1
    while i<=#self.hooks do
        local node = self.hooks[i]
        if self.hookstoremove[node.id] then
            table.remove(self.hooks, i)
            self.hookstoremove[node.id] = nil
        elseif self.hookstoadd[node.id] then
            self.hookstoadd[node.id] = nil
            i = i + 1
        else
            i = i + 1
        end
    end

    for id in pairs(self.hookstoremove) do
        self.hookstoremove[id] = nil
    end
    for id in pairs(self.hookstoadd) do
        self.hooks[#self.hooks+1] = id
        self.hookstoadd[id] = nil
    end

    self.call = self.callclean
    self:call(...)
end

function hooktbl:callclean(name, ...)
    for _, node in ipairs(self.hooks) do
        node[name](node, ...)
    end
end

local hooktbls = setmetatable({},{__index=function(self,k) local t=hooktbl:new() self[k]=t return t end})

function hook.add(name, id)
    hooktbls[name]:add(id)
end
function hook.remove(name, id)
    hooktbls[name]:remove(id)
end
function hook.call(name, ...)
    hooktbls[name]:call(name, ...)
end

return hook
