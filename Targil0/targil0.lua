-- Yael Rubnitz
-- Efrat Brinkman
-- Group: 150060.31.5786.41

-- Global variables to store totals
local totalBuy = 0
local totalCell = 0

-- Function HandleBuy: Calculates subtotal and writes formatted output
local function handleBuy(product, amount, price, outFile)
    local subtotal = tonumber(amount) * tonumber(price)
    totalBuy = totalBuy + subtotal
    outFile:write("### BUY " .. product .. " ###\n")
    outFile:write(subtotal .. "\n")
end

-- Function HandleSell: Calculates subtotal and writes formatted output
local function handleSell(product, amount, price, outFile)
    local subtotal = tonumber(amount) * tonumber(price)
    totalCell = totalCell + subtotal
    outFile:write("$$$ CELL " .. product .. " $$$\n")
    outFile:write(subtotal .. "\n")
end

-- 1. Get directory path from user
print("Enter folder path:")
local folderPath = io.read()

-- 2. Extract folder name
local folderName = folderPath:match("([^/\\]+)$")

-- 3. Convert backslashes to forward slashes (handles spaces)
local outFileName = folderPath .. "/" .. folderName .. ".asm"

-- 4. Open output file for writing
local outFile = io.open(outFileName, "w")
if not outFile then
    print("Could not create file at: " .. outFileName)
    return
end

-- 5. Scan all .vm files in the given directory
local p = io.popen('dir "' .. folderPath .. '" /b')
for fileName in p:lines() do
    if fileName:match("%.vm$") then
        local shortName = fileName:gsub("%.vm$", "")
        outFile:write(shortName .. "\n")
        
        local inFile = io.open(folderPath .. "/" .. fileName, "r")
        if inFile then
            for line in inFile:lines() do
                local words = {}
                for word in line:gmatch("%S+") do table.insert(words, word) end
                
                if words[1] == "buy" then
                    handleBuy(words[2], words[3], words[4], outFile)
                elseif words[1] == "sell" or words[1] == "cell" then
                    handleSell(words[2], words[3], words[4], outFile)
                end
            end
            inFile:close()
        end
        print("Finished processing: " .. fileName)
    end
end
p:close()

-- 6. Final totals
local finalBuy = "TOTAL BUY: " .. totalBuy
local finalCell = "TOTAL CELL: " .. totalCell

print(finalBuy)
print(finalCell)
outFile:write(finalBuy .. "\n" .. finalCell .. "\n")
outFile:close()
print("Success! File created at: " .. outFileName)