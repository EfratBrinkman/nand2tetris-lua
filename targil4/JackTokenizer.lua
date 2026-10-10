-- JackTokenizer.lua
local JackTokenizer = {}

local keywords = {
    ["class"] = true, ["constructor"] = true, ["function"] = true, ["method"] = true,
    ["field"] = true, ["static"] = true, ["var"] = true, ["int"] = true,
    ["char"] = true, ["boolean"] = true, ["void"] = true, ["true"] = true,
    ["false"] = true, ["null"] = true, ["this"] = true, ["let"] = true,
    ["do"] = true, ["if"] = true, ["else"] = true, ["while"] = true, ["return"] = true
}

local symbols = {
    ["{"] = true, ["}"] = true, ["("] = true, [")"] = true, ["["] = true, ["]"] = true,
    ["."] = true, [","] = true, [";"] = true, ["+"] = true, ["-"] = true, ["*"] = true,
    ["/"] = true, ["&"] = true, ["|"] = true, ["<"] = true, [">"] = true, ["="] = true, ["~"] = true
}

function JackTokenizer.escape_xml(str)
    local replacements = {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;",
        ['"'] = "&quot;"
    }
    return replacements[str] or str
end

function JackTokenizer.tokenize(source, input_filename)
    local tokens = {}
    local i = 1
    local n = #source

    while i <= n do
        local char = source:sub(i, i)

        -- Skip standard whitespace blocks
        if char:match("%s") then
            i = i + 1

        -- Handle potential inline or block-comment branches
        elseif char == "/" then
            local next_char = source:sub(i + 1, i + 1)
            if next_char == "/" then
                while i <= n and source:sub(i, i) ~= "\n" do
                    i = i + 1
                end
            elseif next_char == "*" then
                i = i + 2
                while i <= n and source:sub(i, i + 1) ~= "*/" do
                    i = i + 1
                end
                i = i + 2
            else
                table.insert(tokens, { type = "SYMBOL", value = "/" })
                i = i + 1
            end

        -- Check structural and operational symbols
        elseif symbols[char] then
            table.insert(tokens, { type = "SYMBOL", value = char })
            i = i + 1

        -- Isolate string literals
        elseif char == '"' then
            i = i + 1
            local start_pos = i
            while i <= n and source:sub(i, i) ~= '"' do
                i = i + 1
            end
            local str_value = source:sub(start_pos, i - 1)
            table.insert(tokens, { type = "STRING_CONST", value = str_value })
            i = i + 1

        -- Parse valid integer numerical constants
        elseif char:match("%d") then
            local start_idx, end_idx = source:find("^%d+", i)
            local int_value = source:sub(start_idx, end_idx)
            table.insert(tokens, { type = "INT_CONST", value = int_value })
            i = end_idx + 1

        -- Route text terms into designated keywords or user identifiers
        elseif char:match("[%a_]") then
            local start_idx, end_idx = source:find("^[%a_][%w_]*", i)
            local word = source:sub(start_idx, end_idx)
            
            if keywords[word] then
                table.insert(tokens, { type = "KEYWORD", value = word })
            else
                table.insert(tokens, { type = "IDENTIFIER", value = word })
            end
            i = end_idx + 1
        else
            i = i + 1
        end
    end

    -- Automatically export structural flat T.xml verification logs
    if input_filename then
        local t_filename = input_filename:gsub("%.jack$", "T.xml")
        local t_file = io.open(t_filename, "w")
        if t_file then
            t_file:write("<tokens>\n")
            for _, token in ipairs(tokens) do
                local tag = ""
                if token.type == "KEYWORD" then tag = "keyword"
                elseif token.type == "SYMBOL" then tag = "symbol"
                elseif token.type == "IDENTIFIER" then tag = "identifier"
                elseif token.type == "INT_CONST" then tag = "integerConstant"
                elseif token.type == "STRING_CONST" then tag = "stringConstant"
                end
                local escaped = JackTokenizer.escape_xml(token.value)
                t_file:write(string.format("<%s> %s </%s>\n", tag, escaped, tag))
            end
            t_file:write("</tokens>\n")
            t_file:close()
        end
    end

    return tokens
end

return JackTokenizer