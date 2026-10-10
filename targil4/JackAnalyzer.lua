-- JackAnalyzer.lua
local tokenizer = require("JackTokenizer")
local JackParser = require("JackParser")

-- Processes a single .jack source file
local function process_file(input_filename)
    local infile = io.open(input_filename, "r")
    if not infile then
        print("Error: Could not open file " .. input_filename)
        return
    end
    local source_code = infile:read("*all")
    infile:close()

    -- 1. Tokenize source code and generate the intermediate T.xml file
    local tokens = tokenizer.tokenize(source_code, input_filename)
    
    -- 2. Derive the output destination for the main structural XML
    local output_filename = input_filename:gsub("%.jack$", ".xml")
    
    -- 3. Parse tokens and construct the parse tree
    local parser = JackParser.new(tokens, output_filename)
    parser:compileClass()
    parser:close()
    
    print("Successfully processed: " .. output_filename)
end

local function main()
    local inputPath = arg[1]
    if not inputPath then
        print("Usage: lua JackAnalyzer.lua <path_to_file_or_dir>")
        return
    end

    -- Normalize trailing slashes
    inputPath = inputPath:gsub("[\\/]$", "")
    local jackFiles = {}

    -- Handle file vs directory pathing
    if inputPath:match("%.jack$") then
        table.insert(jackFiles, inputPath)
    else
        local p = io.popen('dir "' .. inputPath .. '" /b')
        for file in p:lines() do
            if file:match("%.jack$") then
                table.insert(jackFiles, inputPath .. "/" .. file)
            end
        end
        p:close()
    end

    if #jackFiles == 0 then
        print("No .jack files found!")
        return
    end

    -- Process all discovered target files
    for _, file in ipairs(jackFiles) do
        process_file(file)
    end
end

main()