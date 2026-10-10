local Parser = require("Parser")
local CodeWriter = require("CodeWriter")

local function runTest(fileName)
    local parser = Parser.new(fileName .. ".vm")
    local writer = CodeWriter.new(fileName .. ".asm")

    print("Translating " .. fileName .. ".vm...")

    while parser:advance() do
        -- 1. טיפול בפקודות זיכרון
        if parser.commandType == "C_PUSH" or parser.commandType == "C_POP" then
            writer:writePushPop(parser.commandType, parser.arg1, parser.arg2)
        
        -- 2. טיפול בפקודות חישוב (החלק החדש!)
        elseif parser.commandType == "C_ARITHMETIC" then
            writer:writeArithmetic(parser.arg1)
        end
    end

    writer:close()
    print("Done! Created " .. fileName .. ".asm")
end

runTest("BasicTest")