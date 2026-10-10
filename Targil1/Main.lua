local Parser = require("Parser")
local CodeWriter = require("CodeWriter")

local function main()
    local inputPath = arg[1]
    if not inputPath then
        print("Usage: lua Main.lua <path_to_file_or_dir>")
        return
    end

    inputPath = inputPath:gsub("[\\/]$", "")

    local vmFiles = {}
    local outputFileName

    if inputPath:match("%.vm$") then
        table.insert(vmFiles, inputPath)
        outputFileName = inputPath:gsub("%.vm$", ".asm")
    else
        outputFileName = inputPath .. "/" .. inputPath:match("([^\\/]+)$") .. ".asm"
        local p = io.popen('dir "' .. inputPath .. '" /b')
        for file in p:lines() do
            if file:match("%.vm$") then
                table.insert(vmFiles, inputPath .. "/" .. file)
            end
        end
        p:close()
    end

    if #vmFiles == 0 then
        print("No .vm files found!")
        return
    end

    local writer = CodeWriter.new(outputFileName)
    print("Output file: " .. outputFileName)

    if #vmFiles > 1 then
        writer:writeInit()
    end

    for _, file in ipairs(vmFiles) do
        print("Translating: " .. file)
        local parser = Parser.new(file)
        
        local currentFileName = file:match("([^\\/]+)%.vm$")
        writer.fileName = currentFileName 

        while parser:advance() do
            if parser.commandType == "C_PUSH" or parser.commandType == "C_POP" then
                writer:writePushPop(parser.commandType, parser.arg1, parser.arg2)
            elseif parser.commandType == "C_ARITHMETIC" then
                writer:writeArithmetic(parser.arg1)
            elseif parser.commandType == "C_LABEL" then
                writer:writeLabel(parser.arg1)
            elseif parser.commandType == "C_GOTO" then
                writer:writeGoto(parser.arg1)
            elseif parser.commandType == "C_IF" then
                writer:writeIf(parser.arg1)
            elseif parser.commandType == "C_FUNCTION" then
                writer:writeFunction(parser.arg1, parser.arg2)
            elseif parser.commandType == "C_CALL" then
                writer:writeCall(parser.arg1, parser.arg2)
            elseif parser.commandType == "C_RETURN" then
                writer:writeReturn() 
            end
        end
    end

    writer:close()
    print("Successfully translated " .. #vmFiles .. " files.")
end

main()