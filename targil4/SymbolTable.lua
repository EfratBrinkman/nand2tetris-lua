-- SymbolTable.lua
local SymbolTable = {}
SymbolTable.__index = SymbolTable

function SymbolTable.new()
    local self = setmetatable({}, SymbolTable)
    
    self.class_scope = {}     
    self.subroutine_scope = {} 
    
    self.counters = {
        ["static"]   = 0,
        ["this"]    = 0, 
        ["argument"] = 0,
        ["local"]    = 0  
    }
    
    return self
end

function SymbolTable:startSubroutine()
    self.subroutine_scope = {}
    self.counters["argument"] = 0
    self.counters["local"] = 0
end

function SymbolTable:define(name, type_str, kind)
    local k = kind:lower()
    if k == "var" then k = "local" end
    if k == "field" then k = "this" end
    
    local index = self.counters[k]
    if not index then return end
    self.counters[k] = self.counters[k] + 1
    
    local row = { type = type_str, kind = k, index = index }
    
    if k == "static" or k == "this" then
        self.class_scope[name] = row
    elseif k == "argument" or k == "local" then
        self.subroutine_scope[name] = row
    end
end

function SymbolTable:varCount(kind)
    local k = kind:lower()
    if k == "var" then k = "local" end
    if k == "field" then k = "this" end
    return self.counters[k] or 0
end

function SymbolTable:_Lookup(name)
    if self.subroutine_scope[name] then
        return self.subroutine_scope[name]
    end
    return self.class_scope[name]
end

function SymbolTable:kindOf(name)
    local res = self:_Lookup(name)
    if res then
        return res.kind
    end
    return "NONE"
end

function SymbolTable:typeOf(name)
    local res = self:_Lookup(name)
    if res then
        return res.type
    end
    return nil
end

function SymbolTable:indexOf(name)
    local res = self:_Lookup(name)
    if res then
        return res.index
    end
    return nil
end

return SymbolTable