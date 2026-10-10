-- JackParser.lua
local JackTokenizer = require("JackTokenizer")
local SymbolTable = require("SymbolTable")
local VMWriter = require("VMWriter")

local JackParser = {}
JackParser.__index = JackParser

local ops = {
    ["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true,
    ["&"] = true, ["|"] = true, ["<"] = true, [">"] = true, ["="] = true
}

local unary_ops = { ["-"] = true, ["~"] = true }

local keyword_constants = { ["true"] = true, ["false"] = true, ["null"] = true, ["this"] = true }

function JackParser.new(tokens, output_filename)
    local self = setmetatable({}, JackParser)
    self.tokens = tokens
    self.cursor = 1
    self.depth = 0
    
    self.xml_file = io.open(output_filename, "w")
    if not self.xml_file then
        print("Error: Could not create XML file: " .. output_filename)
    end
    
    local vm_filename = output_filename:gsub("%.xml$", ".vm")
    self.symbol_table = SymbolTable.new()
    self.vm_writer = VMWriter.new(vm_filename)
    
    self.class_name = ""
    self.label_index = 0
    
    return self
end

function JackParser:close()
    if self.xml_file then self.xml_file:close() end
    if self.vm_writer then self.vm_writer:close() end
end


function JackParser:next_label(prefix)
    local lbl = prefix .. self.label_index
    self.label_index = self.label_index + 1
    return lbl
end


function JackParser:get_indent()
    return string.rep("  ", self.depth)
end

function JackParser:write_element(tag, val)
    local escaped = JackTokenizer.escape_xml(val)
    local indent = self:get_indent()
    if self.xml_file then
        self.xml_file:write(string.format("%s<%s> %s </%s>\n", indent, tag, escaped, tag))
    end
end

function JackParser:get_tag(tkn)
    if tkn.type == "KEYWORD" then return "keyword"
    elseif tkn.type == "SYMBOL" then return "symbol"
    elseif tkn.type == "IDENTIFIER" then return "identifier"
    elseif tkn.type == "INT_CONST" then return "integerConstant"
    elseif tkn.type == "STRING_CONST" then return "stringConstant"
    end
end

function JackParser:process(expected_val)
    local tkn = self.tokens[self.cursor]
    if not tkn then return end
    
    if expected_val and tkn.value ~= expected_val then
        print("Syntax Error: Expected " .. expected_val .. " but got " .. tkn.value)
    end
    
    local tag = self:get_tag(tkn)
    self:write_element(tag, tkn.value)
    self.cursor = self.cursor + 1
end

function JackParser:peek(offset)
    offset = offset or 0
    return self.tokens[self.cursor + offset]
end



function JackParser:compileClass()
    self:open_tag("class") 
    self:process("class")
    
    self.class_name = self.tokens[self.cursor].value
    self:process() -- className
    
    self:process("{")
    
    while self:peek() and (self:peek().value == "static" or self:peek().value == "field") do
        self:compileClassVarDec()
    end
    
    while self:peek() and (self:peek().value == "constructor" or self:peek().value == "function" or self:peek().value == "method") do
        self:compileSubroutine()
    end
    
    self:process("}")
    self:close_tag("class") 
end

function JackParser:compileClassVarDec()
    self:open_tag("classVarDec") 
    
    local kind = self.tokens[self.cursor].value
    self:process() 
    
    local type_str = self.tokens[self.cursor].value
    self:process() 
    
    local name = self.tokens[self.cursor].value
    self:process() 
    
    self.symbol_table:define(name, type_str, kind) 
    
    while self:peek() and self:peek().value == "," do
        self:process(",")
        name = self.tokens[self.cursor].value
        self:process()
        self.symbol_table:define(name, type_str, kind) 
    end
    
    self:process(";")
    self:close_tag("classVarDec") 
end

function JackParser:compileSubroutine()
    self:open_tag("subroutineDec") 
    
    local subroutine_kind = self.tokens[self.cursor].value
    self:process() -- constructor / function / method
    
    local return_type = self.tokens[self.cursor].value
    self:process() -- void / type
    
    local subroutine_name = self.tokens[self.cursor].value
    self:process() -- subroutineName
    
    self.symbol_table:startSubroutine()
    
    if subroutine_kind == "method" then
        self.symbol_table:define("this", self.class_name, "argument")
    end
    
    self:process("(")
    self:compileParameterList()
    self:process(")")
    
    self:open_tag("subroutineBody") 
    self:process("{")
    
    while self:peek() and self:peek().value == "var" do
        self:compileVarDec()
    end
    
    local nLocals = self.symbol_table:varCount("local")
    local full_func_name = self.class_name .. "." .. subroutine_name
    self.vm_writer:writeFunction(full_func_name, nLocals)
    
    if subroutine_kind == "constructor" then
        local nFields = self.symbol_table:varCount("this")
        self.vm_writer:writePush("constant", nFields)
        self.vm_writer:writeCall("Memory.alloc", 1)
        self.vm_writer:writePop("pointer", 0) 
    elseif subroutine_kind == "method" then
  
        self.vm_writer:writePush("argument", 0)
        self.vm_writer:writePop("pointer", 0)
    end
    
    self:compileStatements()
    
    self:process("}")
    self:close_tag("subroutineBody") 
    self:close_tag("subroutineDec") 
end

function JackParser:compileParameterList()
    self:open_tag("parameterList") 
    
    if self:peek() and self:peek().value ~= ")" then
        local type_str = self.tokens[self.cursor].value
        self:process() 
        
        local name = self.tokens[self.cursor].value
        self:process() 
        
        self.symbol_table:define(name, type_str, "argument") 
        
        while self:peek() and self:peek().value == "," do
            self:process(",")
            type_str = self.tokens[self.cursor].value
            self:process()
            name = self.tokens[self.cursor].value
            self:process()
            self.symbol_table:define(name, type_str, "argument") 
        end
    end
    
    self:close_tag("parameterList") 
end

function JackParser:compileVarDec()
    self:open_tag("varDec") 
    self:process("var") 
    
    local type_str = self.tokens[self.cursor].value
    self:process() 
    
    local name = self.tokens[self.cursor].value
    self:process() 
    
    self.symbol_table:define(name, type_str, "local") 
    
    while self:peek() and self:peek().value == "," do
        self:process(",")
        name = self.tokens[self.cursor].value
        self:process()
        self.symbol_table:define(name, type_str, "local") 
    end
    
    self:process(";")
    self:close_tag("varDec") 
end

function JackParser:compileStatements()
    self:open_tag("statements")
    local statement_keywords = { 
        ["let"] = true, ["if"] = true, ["while"] = true, ["do"] = true, ["return"] = true 
    }
    
    while self:peek() and statement_keywords[self:peek().value] do
        local kw = self:peek().value
        if kw == "let" then self:compileLet()
        elseif kw == "if" then self:compileIf()
        elseif kw == "while" then self:compileWhile()
        elseif kw == "do" then self:compileDo()
        elseif kw == "return" then self:compileReturn()
        end
    end
    self:close_tag("statements")
end

function JackParser:compileLet()
    self:open_tag("letStatement")
    self:process("let")
    
    local var_name = self.tokens[self.cursor].value
    self:process() -- varName
    
    local kind = self.symbol_table:kindOf(var_name)
    local index = self.symbol_table:indexOf(var_name)
    
    local is_array = false
    if self:peek() and self:peek().value == "[" then
        is_array = true
        self:process("[")
        self:compileExpression() 
        self:process("]")
        
        self.vm_writer:writePush(kind, index)
        self.vm_writer:writeArithmetic("add")
        
        self.vm_writer:writePop("temp", 1)
    end
    
    self:process("=")
    self:compileExpression() 
    self:process(";")
    
    if is_array then
        self.vm_writer:writePush("temp", 1)
        self.vm_writer:writePop("pointer", 1)
        self.vm_writer:writePop("that", 0)
    else
        self.vm_writer:writePop(kind, index)
    end
    
    self:close_tag("letStatement")
end
function JackParser:compileIf()
    self:open_tag("ifStatement")
    self:process("if")
    self:process("(")
    self:compileExpression() 
    self:process(")")
    
    local label_true = self:next_label("IF_TRUE")
    local label_false = self:next_label("IF_FALSE")
    local label_end = self:next_label("IF_END")
    
    self.vm_writer:writeIf(label_true)
    self.vm_writer:writeGoto(label_false)
    
    self.vm_writer:writeLabel(label_true)
    self:process("{")
    self:compileStatements()
    self:process("}")
    
    if self:peek() and self:peek().value == "else" then
        self.vm_writer:writeGoto(label_end)
        self.vm_writer:writeLabel(label_false)
        self:process("else")
        self:process("{")
        self:compileStatements()
        self:process("}")
        self.vm_writer:writeLabel(label_end)
    else
        self.vm_writer:writeLabel(label_false)
    end
    
    self:close_tag("ifStatement")
end

function JackParser:compileWhile()
    self:open_tag("whileStatement")
    
    local label_exp = self:next_label("WHILE_EXP")
    local label_end = self:next_label("WHILE_END")
    local label_body = self:next_label("WHILE_BODY")
    
    self.vm_writer:writeLabel(label_exp)
    
    self:process("while")
    self:process("(")
    self:compileExpression()
    self:process(")")
    
    self.vm_writer:writeIf(label_body)
    self.vm_writer:writeGoto(label_end)
    
    self.vm_writer:writeLabel(label_body)
    self:process("{")
    self:compileStatements()
    self:process("}")
    
    self.vm_writer:writeGoto(label_exp)
    self.vm_writer:writeLabel(label_end)
    
    self:close_tag("whileStatement")
end


function JackParser:compileDo()
    self:open_tag("doStatement")
    self:process("do")
    
    self:compileSubroutineCall()
    
    self:process(";")
    self.vm_writer:writePop("temp", 0)
    
    self:close_tag("doStatement")
end

function JackParser:compileReturn()
    self:open_tag("returnStatement")
    self:process("return")
    
    if self:peek() and self:peek().value ~= ";" then
        self:compileExpression()
    else
        self.vm_writer:writePush("constant", 0)
    end
    
    self:process(";")
    self.vm_writer:writeReturn()
    self:close_tag("returnStatement")
end

function JackParser:compileExpression()
    self:open_tag("expression")
    self:compileTerm()
    
    while self:peek() and ops[self:peek().value] do
        local op = self:peek().value
        self:process() 
        self:compileTerm()
        
        if op == "+" then self.vm_writer:writeArithmetic("add")
        elseif op == "-" then self.vm_writer:writeArithmetic("sub")
        elseif op == "*" then self.vm_writer:writeCall("Math.multiply", 2)
        elseif op == "/" then self.vm_writer:writeCall("Math.divide", 2)
        elseif op == "=" then self.vm_writer:writeArithmetic("eq")
        elseif op == ">" then self.vm_writer:writeArithmetic("gt")
        elseif op == "<" then self.vm_writer:writeArithmetic("lt")
        elseif op == "&" then self.vm_writer:writeArithmetic("and")
        elseif op == "|" then self.vm_writer:writeArithmetic("or")
        end
    end
    self:close_tag("expression")
end

function JackParser:compileTerm()
    self:open_tag("term")
    local tkn = self:peek()
    if not tkn then return end
    
    if tkn.type == "INT_CONST" then
        self.vm_writer:writePush("constant", tonumber(tkn.value))
        self:process()
        
    elseif tkn.type == "STRING_CONST" then
        local str = tkn.value
        self.vm_writer:writePush("constant", #str)
        self.vm_writer:writeCall("String.new", 1)
        for j = 1, #str do
            local char_code = string.byte(str, j)
            self.vm_writer:writePush("constant", char_code)
            self.vm_writer:writeCall("String.appendChar", 2)
        end
        self:process()
        
    elseif keyword_constants[tkn.value] then
        local kw = tkn.value
        if kw == "true" then
            self.vm_writer:writePush("constant", 0)
            self.vm_writer:writeArithmetic("not")
        elseif kw == "false" or kw == "null" then
            self.vm_writer:writePush("constant", 0)
        elseif kw == "this" then
            self.vm_writer:writePush("pointer", 0)
        end
        self:process()
        
    elseif unary_ops[tkn.value] then
        local op = tkn.value
        self:process() 
        self:compileTerm()
        if op == "-" then
            self.vm_writer:writeArithmetic("neg")
        elseif op == "~" then
            self.vm_writer:writeArithmetic("not")
        end
        
    elseif tkn.value == "(" then
        self:process("(")
        self:compileExpression()
        self:process(")")
        
    elseif tkn.type == "IDENTIFIER" then
        local next_tkn = self:peek(1)
        if next_tkn and next_tkn.value == "[" then
            -- קריאת ערך מתוך מערך (a[i])
            local var_name = tkn.value
            local kind = self.symbol_table:kindOf(var_name)
            local index = self.symbol_table:indexOf(var_name)
            
            self:process() -- varName
            self:process("[")
            self:compileExpression()
            self:process("]")
            
            self.vm_writer:writePush(kind, index)
            self.vm_writer:writeArithmetic("add")
            self.vm_writer:writePop("pointer", 1) 
            self.vm_writer:writePush("that", 0)   
            
        elseif next_tkn and (next_tkn.value == "(" or next_tkn.value == ".") then
            self:compileSubroutineCall()
        else
            local var_name = tkn.value
            local kind = self.symbol_table:kindOf(var_name)
            local index = self.symbol_table:indexOf(var_name)
            if kind ~= "NONE" then
                self.vm_writer:writePush(kind, index)
            end
            self:process()
        end
    end
    self:close_tag("term")
end

function JackParser:compileExpressionList()
    self:open_tag("expressionList")
    local count = 0
    if self:peek() and self:peek().value ~= ")" then
        self:compileExpression()
        count = count + 1
        while self:peek() and self:peek().value == "," do
            self:process(",")
            self:compileExpression()
            count = count + 1
        end
    end
    self:close_tag("expressionList")
    return count
end

function JackParser:compileSubroutineCall()
    local first_name = self.tokens[self.cursor].value
    self:process() 
    
    local full_name = ""
    local nArgs = 0
    
    if self:peek() and self:peek().value == "." then
        self:process(".")
        local subroutine_name = self.tokens[self.cursor].value
        self:process()
        
        local kind = self.symbol_table:kindOf(first_name)
        
        if kind ~= "NONE" then
            local obj_type = self.symbol_table:typeOf(first_name)
            local index = self.symbol_table:indexOf(first_name)
            
            self.vm_writer:writePush(kind, index)
            
            full_name = obj_type .. "." .. subroutine_name
            nArgs = 1 
        else
            full_name = first_name .. "." .. subroutine_name
            nArgs = 0
        end
    else
        self.vm_writer:writePush("pointer", 0)
        full_name = self.class_name .. "." .. first_name
        nArgs = 1
    end
    
    self:process("(")
    nArgs = nArgs + self:compileExpressionList()
    self:process(")")
    
    self.vm_writer:writeCall(full_name, nArgs)
end

function JackParser:open_tag(tag_name)
    local indent = self:get_indent()
    if self.xml_file then self.xml_file:write(indent .. "<" .. tag_name .. ">\n") end
    self.depth = self.depth + 1
end

function JackParser:close_tag(tag_name)
    self.depth = self.depth - 1
    local indent = self:get_indent()
    if self.xml_file then self.xml_file:write(indent .. "</" .. tag_name .. ">\n") end
end

return JackParser