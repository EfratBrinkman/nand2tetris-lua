-- Parser.lua
local Parser = {}

function Parser.new(fileName)
    local file = io.open(fileName, "r")
    if not file then error("Could not open file: " .. fileName) end
    
    local obj = {
        file = file,
        currentCommand = nil,
        commandType = nil,
        arg1 = nil,
        arg2 = nil
    }
    
    setmetatable(obj, { __index = Parser })
    return obj
end

function Parser:advance()
    local line = self.file:read("*line")
    if not line then return false end

    line = line:gsub("//.*", ""):match("^%s*(.-)%s*$")
    
    if line == "" then return self:advance() end

    local parts = {}
    for part in line:gmatch("%S+") do
        table.insert(parts, part)
    end

    self.currentCommand = line
    local command = parts[1]


    if command == "push" or command == "pop" then
        self.commandType = (command == "push") and "C_PUSH" or "C_POP"
        self.arg1 = parts[2]
        self.arg2 = tonumber(parts[3])
    elseif command == "label" then
        self.commandType = "C_LABEL"
        self.arg1 = parts[2]
    elseif command == "goto" then
        self.commandType = "C_GOTO"
        self.arg1 = parts[2]
    elseif command == "if-goto" then
        self.commandType = "C_IF"
        self.arg1 = parts[2]
    elseif command == "function" or command == "call" or command == "return" then
        if command == "function" then self.commandType = "C_FUNCTION"
        elseif command == "call" then self.commandType = "C_CALL"
        else self.commandType = "C_RETURN" end
        self.arg1 = parts[2]
        self.arg2 = tonumber(parts[3])
    else
        self.commandType = "C_ARITHMETIC"
        self.arg1 = command
    end

    return true
end

return Parser