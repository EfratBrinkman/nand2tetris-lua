
-- CodeWriter.lua
local CodeWriter = {}

local segments = {
    ["local"] = "LCL",  
    argument = "ARG",
    this = "THIS",
    that = "THAT"
}
-- KUKU
function CodeWriter:writeInit()
    local asm = {
        "// Bootstrap code",
        "@256",
        "D=A",
        "@SP",
        "M=D"
    }
    self.file:write(table.concat(asm, "\n") .. "\n")
    
    self:writeCall("Sys.init", 0)
end

function CodeWriter.new(outputFileName)
    local file = io.open(outputFileName, "w")
    local baseName = outputFileName:match("([^/\\]+)%.asm$") or "Output"
    
    local obj = { 
        file = file, 
        fileName = baseName,
        labelCounter = 0 
    }
    setmetatable(obj, { __index = CodeWriter })
    return obj
end

function CodeWriter:pushDToStack(asm)
    table.insert(asm, "@SP")
    table.insert(asm, "A=M")
    table.insert(asm, "M=D")
    table.insert(asm, "@SP")
    table.insert(asm, "M=M+1")
end

function CodeWriter:popStackToD(asm)
    table.insert(asm, "@SP")
    table.insert(asm, "M=M-1")
    table.insert(asm, "A=M")
    table.insert(asm, "D=M")
end


function CodeWriter:writeArithmetic(command)
    local asm = {}
    table.insert(asm, "// " .. command)

    if command == "add" or command == "sub" or command == "and" or command == "or" then
        self:popStackToD(asm)
        
        table.insert(asm, "@SP")
        table.insert(asm, "A=M-1")
        
        if command == "add" then table.insert(asm, "M=M+D")
        elseif command == "sub" then table.insert(asm, "M=M-D")
        elseif command == "and" then table.insert(asm, "M=M&D")
        elseif command == "or" then table.insert(asm, "M=M|D")
        end
        
    elseif command == "eq" or command == "gt" or command == "lt" then
        self:popStackToD(asm) -- y
        table.insert(asm, "@SP")
        table.insert(asm, "A=M-1")
        table.insert(asm, "D=M-D") -- D = x - y
        
        local label = "LABEL_" .. self.labelCounter
        self.labelCounter = self.labelCounter + 1
        
        local jumpType = ""
        if command == "eq" then jumpType = "JEQ"
        elseif command == "gt" then jumpType = "JGT"
        elseif command == "lt" then jumpType = "JLT" end
        
        table.insert(asm, "@" .. label .. "_TRUE")
        table.insert(asm, "D;" .. jumpType)
        
        table.insert(asm, "@SP")
        table.insert(asm, "A=M-1")
        table.insert(asm, "M=0")
        table.insert(asm, "@" .. label .. "_END")
        table.insert(asm, "0;JMP")
        
        table.insert(asm, "(" .. label .. "_TRUE)")
        table.insert(asm, "@SP")
        table.insert(asm, "A=M-1")
        table.insert(asm, "M=-1") -- 
        
        table.insert(asm, "(" .. label .. "_END)")


    elseif command == "neg" or command == "not" then
        table.insert(asm, "@SP")
        table.insert(asm, "A=M-1")
        if command == "neg" then table.insert(asm, "M=-M")
        else table.insert(asm, "M=!M") end
    end

    self.file:write(table.concat(asm, "\n") .. "\n")
end


function CodeWriter:writePushPop(command, segment, index)
    local asm = {}
    table.insert(asm, "// " .. command .. " " .. segment .. " " .. index)

    if command == "C_PUSH" then
        if segment == "constant" then
            table.insert(asm, "@" .. index)
            table.insert(asm, "D=A")
            self:pushDToStack(asm)
        elseif segments[segment] then
            table.insert(asm, "@" .. segments[segment])
            table.insert(asm, "D=M")
            table.insert(asm, "@" .. index)
            table.insert(asm, "A=D+A")
            table.insert(asm, "D=M")
            self:pushDToStack(asm)    
        elseif segment == "temp" then
            table.insert(asm, "@" .. (5 + index))
            -- table.insert(asm, "@" .. (6 + index))
            table.insert(asm, "D=M")
            self:pushDToStack(asm)
        elseif segment == "pointer" then
            local reg = (index == 0) and "THIS" or "THAT"
            table.insert(asm, "@" .. reg)
            table.insert(asm, "D=M")
            self:pushDToStack(asm)
        elseif segment == "static" then
            table.insert(asm, "@" .. self.fileName .. "." .. index)
            table.insert(asm, "D=M")
            self:pushDToStack(asm) 
        end

    elseif command == "C_POP" then
        if segments[segment] then
            table.insert(asm, "@" .. segments[segment])
            table.insert(asm, "D=M")
            table.insert(asm, "@" .. index)
            table.insert(asm, "D=D+A")
            table.insert(asm, "@R13")
            table.insert(asm, "M=D")
            self:popStackToD(asm)
            table.insert(asm, "@R13")
            table.insert(asm, "A=M")
            table.insert(asm, "M=D")
        elseif segment == "temp" then
            self:popStackToD(asm)
            table.insert(asm, "@" .. (5 + index))
            --table.insert(asm, "@" .. (6 + index))
            table.insert(asm, "M=D")
        elseif segment == "pointer" then
            local reg = (index == 0) and "THIS" or "THAT"
            self:popStackToD(asm)
            table.insert(asm, "@" .. reg)
            table.insert(asm, "M=D")
        elseif segment == "static" then
            self:popStackToD(asm)
            table.insert(asm, "@" .. self.fileName .. "." .. index)
            table.insert(asm, "M=D")
        end
    end

    self.file:write(table.concat(asm, "\n") .. "\n")
end

function CodeWriter:writeLabel(label)
    local asm = {}
    table.insert(asm, "// label " .. label)
    table.insert(asm, "(" .. self.fileName .. "." .. label .. ")")
    self.file:write(table.concat(asm, "\n") .. "\n")
end

function CodeWriter:writeGoto(label)
    local asm = {}
    table.insert(asm, "// goto " .. label)
    table.insert(asm, "@" .. self.fileName .. "." .. label)
    table.insert(asm, "0;JMP")
    self.file:write(table.concat(asm, "\n") .. "\n")
end

function CodeWriter:writeIf(label)
    local asm = {}
    table.insert(asm, "// if-goto " .. label)
    self:popStackToD(asm)
    table.insert(asm, "@" .. self.fileName .. "." .. label)
    table.insert(asm, "D;JNE") 
    self.file:write(table.concat(asm, "\n") .. "\n")
end


function CodeWriter:writeFunction(functionName, numLocals)
    local asm = { "// function " .. functionName .. " " .. numLocals }
    table.insert(asm, "(" .. functionName .. self.labelCounter .. ")") -- הוספתי את השם של הקובץ לליבל 
    
    for i = 1, numLocals do
        table.insert(asm, "@0")
        table.insert(asm, "D=A")
        self:pushDToStack(asm)
    end
    self.file:write(table.concat(asm, "\n") .. "\n")
end


function CodeWriter:writeCall(functionName, numArgs)
    local returnLabel = "RETURN_" .. functionName .. "_" .. self.labelCounter
    self.labelCounter = self.labelCounter + 1
    
    local asm = { "// call " .. functionName .. " " .. numArgs }
    
    -- 1. push returnAddress
    table.insert(asm, "@" .. returnLabel)
    table.insert(asm, "D=A")
    self:pushDToStack(asm)
    
    -- 2. push LCL, ARG, THIS, THAT 
    local segs = {"LCL", "ARG", "THIS", "THAT"}
    --    local segs = { "KUKU", "LCL", "ARG", "THIS", "THAT"}
    for _, seg in ipairs(segs) do
        table.insert(asm, "@" .. seg)
        table.insert(asm, "D=M")
        self:pushDToStack(asm)
    end
    
    -- 3. ARG = SP - 5 - numArgs
    table.insert(asm, "@SP")
    table.insert(asm, "D=M")
    table.insert(asm, "@5")
    --table.insert(asm, "@6")
    table.insert(asm, "D=D-A")
    table.insert(asm, "@" .. numArgs)
    table.insert(asm, "D=D-A")
    table.insert(asm, "@ARG")
    table.insert(asm, "M=D")
    
    -- 4. LCL = SP
    table.insert(asm, "@SP")
    table.insert(asm, "D=M")
    table.insert(asm, "@LCL")
    table.insert(asm, "M=D")
    
    -- 5. goto functionName
    table.insert(asm, "@" .. functionName .. self.labelCounter) -- הוספתי את השם של הקובץ לליבל
    table.insert(asm, "0;JMP")
    
    -- 6. (returnAddress)
    table.insert(asm, "(" .. returnLabel .. ")")
    
    self.file:write(table.concat(asm, "\n") .. "\n")
end

function CodeWriter:writeReturn()
    local asm = { "// return" }
    
    -- 1. endFrame (R14) = LCL
    table.insert(asm, "@LCL")
    table.insert(asm, "D=M")
    table.insert(asm, "@R14") 
    table.insert(asm, "M=D")
    
    -- 2. retAddr (R15) = *(endFrame - 5)
    table.insert(asm, "@5")
    -- table.insert(asm, "@6")
    table.insert(asm, "A=D-A")
    table.insert(asm, "D=M")
    table.insert(asm, "@R15")
    table.insert(asm, "M=D")
    
    -- 3. *ARG = pop()
    self:popStackToD(asm)
    table.insert(asm, "@ARG")
    table.insert(asm, "A=M")
    table.insert(asm, "M=D")
    
    -- 4. SP = ARG + 1
    table.insert(asm, "@ARG")
    table.insert(asm, "D=M+1")
    table.insert(asm, "@SP")
    table.insert(asm, "M=D")
    
    -- 5. (THAT, THIS, ARG, LCL)
    local saved_segments = { "THAT", "THIS", "ARG", "LCL" }
    -- local saved_segments = { "KUKU", "THAT", "THIS", "ARG", "LCL"  }
    for i, seg in ipairs(saved_segments) do
        table.insert(asm, "@R14")
        table.insert(asm, "D=M")
        table.insert(asm, "@" .. i)
        table.insert(asm, "A=D-A") 
        table.insert(asm, "D=M")  
        table.insert(asm, "@" .. seg)
        table.insert(asm, "M=D")   
    end
    
    -- 6. goto retAddr
    table.insert(asm, "@R15")
    table.insert(asm, "A=M")
    table.insert(asm, "0;JMP")
    
    self.file:write(table.concat(asm, "\n") .. "\n")
end
 

function CodeWriter:close()
    self.file:close()
end

return CodeWriter