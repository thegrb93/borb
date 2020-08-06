local class = require("lib/middleclass")
local hook = {}
local hooktbl = class("hooktbl")

function hooktbl:initialize()
    self.nhooks = 0
end

function hooktbl:find(id)
    local pnode
    local node = self.hooks
    for i=1, self.nhooks do
        if node.id == id then return pnode, node end
        pnode = node
        node = node.next
    end
end

function hooktbl:add(id, func)
    local pnode, node = self:find(id)
    if node then
        node.func = func
    else
        local node = {
            id = id,
            func = func,
            next = self.hooks
        }
        self.hooks = node
        self.nhooks = self.nhooks + 1
    end
end

function hooktbl:remove(id)
    local pnode, node = self:find(id)
    if node then
        if pnode then
            pnode.next = node.next
        else
            self.hooks = node.next
        end
        self.nhooks = self.nhooks - 1
    end
end

function hooktbl:call(...)
    local node = self.hooks
    for i=1, self.nhooks do
        local ret = node.func(...)
        if ret~=nil then return ret end
        node = node.next
    end
end

local hooktbls = setmetatable({},{__index=function(self,k) local t=hooktbl:new() self[k]=t return t end})

function hook.add(name, id, func)
    hooktbls[name]:add(id, func)
end

function hook.remove(name, id)
    hooktbls[name]:remove(id)
end

function hook.call(name, ...)
    hooktbls[name]:call(...)
end

return hook
