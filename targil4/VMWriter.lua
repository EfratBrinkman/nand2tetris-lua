-- VMWriter.lua
local VMWriter = {}
VMWriter.__index = VMWriter

function VMWriter.new(output_filename)
    local self = setmetatable({}, VMWriter)
    -- פתיחת קובץ ה-VM לכתיבה
    self.outfile = io.open(output_filename, "w")
    if not self.outfile then
        print("Error: Could not create VM output file: " .. output_filename)
    end
    return self
end

function VMWriter:writePush(segment, index)
    local seg = segment:lower()
    if seg == "var" then seg = "local" end
    if seg == "field" then seg = "this" end
    
    self.outfile:write(string.format("push %s %d\n", seg, index))
end

function VMWriter:writePop(segment, index)
    local seg = segment:lower()
    if seg == "var" then seg = "local" end
    if seg == "field" then seg = "this" end
    
    self.outfile:write(string.format("pop %s %d\n", seg, index))
end

function VMWriter:writeArithmetic(command)
    self.outfile:write(command:lower() .. "\n")
end

function VMWriter:writeLabel(label)
    self.outfile:write("label " .. label .. "\n")
end

function VMWriter:writeGoto(label)
    self.outfile:write("goto " .. label .. "\n")
end

function VMWriter:writeIf(label)
    self.outfile:write("if-goto " .. label .. "\n")
end

function VMWriter:writeCall(name, nArgs)
    self.outfile:write(string.format("call %s %d\n", name, nArgs))
end

function VMWriter:writeFunction(name, nLocals)
    self.outfile:write(string.format("function %s %d\n", name, nLocals))
end

function VMWriter:writeReturn()
    self.outfile:write("return\n")
end

function VMWriter:close()
    if self.outfile then
        self.outfile:close()
    end
end

return VMWriter