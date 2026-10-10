-- TestParser.lua
local Parser = require("Parser")

local function test()
    print("--- Starting Parser Test ---")
    local p = Parser.new("test.vm")
    print("Opened file: test.vm")

    while p:advance() do
        print("Command: [" .. p.currentCommand .. "]")
        print("  Type: " .. p.commandType)
        print("  Arg1: " .. (p.arg1 or "nil"))
        print("  Arg2: " .. (p.arg2 or "nil"))
        print("----------------------------")
    end
    print("--- Test Finished ---")
end

test()