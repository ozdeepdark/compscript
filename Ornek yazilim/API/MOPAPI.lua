	

    --[[
            monAPI v1.0     - Made by Shazz
            This is a simple API for creating 'sections' on monitors.
            Feel free to share and edit to your needs but try to keep this header intact.
    ]]
     
    -- Variables
    local monitors = {}
    local hitboxes = {}
     
    -- Functions
    function wrapMonitor(side)
            if peripheral.getType(side) == "monitor" then
                    monitors[side] = {sections = {}; pH = peripheral.wrap(side)}
                    for k, v in pairs(monitors[side]["pH"]) do
                            monitors[side][k] = v
                    end
                    monitors[side]["pH"] = nil
     
                    monitors[side]["getHitbox"] =
                    function(x, y)
                            for k, v in pairs(hitboxes) do
                                    if x >= v.startX and y >= v.startY and x <= v.endX and y <= v.endY then
                                            return v.name, v.section
                                    end
                            end
                            return nil
                    end
                    monitors[side]["createSection"] =
                    function(startX, startY, endX, endY)
                            monitor = monitors[side]
                            startX = math.floor(startX)
                            startY = math.floor(startY)
                            endX = math.floor(endX)
                            endY = math.floor(endY)
                            if endX < startX then
                                    error("endX must be greater than startX")
                            end
                            if endY < startY then
                                    error("endY must be greater than startY")
                            end
                           
                            monitor["sections"][#monitor["sections"]+1] = {startX = startX; startY = startY; endX = endX; endY = endY; textColour = colours.white; backgroundColour = colours.black; cursorPosX = 1; cursorPosY = 1;}
                            local sectionID = #monitor["sections"]
                            local self = monitor["sections"][sectionID]
                            local pH = monitor
                            local w, h = self.endX - self.startX + 1, self.endY - self.startY + 1
                           
                            self.realCursorPosX = self.startX + self.cursorPosX - 1
                            self.realCursorPosY = self.startY + self.cursorPosY - 1
     
                            local functions = {
                                    -- getSize
                                    getSize = function()
                                            return w, h
                                    end;
                           
                                    -- setPos
                                    setCursorPos = function(x, y)
                                            if type(x) == "number" and type(y) == "number" then
                                                    if x <= w and y > 0 and y <= h then
                                                            self.cursorPosX, self.cursorPosY = x, y
                                                            self.realCursorPosX = self.startX + self.cursorPosX - 1
                                                            self.realCursorPosY = self.startY + self.cursorPosY - 1
                                                    else
                                                            self.cursorPosX, self.cursorPosY = nil, nil
                                                    end
                                            else
                                                    error("Expected number")
                                            end
                                    end;
                                   
                                    -- getPos
                                    getCursorPos = function()
                                            return cursorPosX, cursorPosY
                                    end;
                                   
                                    -- textColour + backgroundColour
                                    setTextColour = function(colour)
                                            self.textColour = colour
                                    end;
                                   
                                    setBackgroundColour = function(colour)
                                            self.backgroundColour = colour
                                    end;
                                   
                                    setTextColor = function(colour)
                                            self.textColour = colour
                                    end;
                                   
                                    setBackgroundColor = function(colour)
                                            self.backgroundColour = colour
                                    end;
                                   
                                    -- write
                                    write = function(text)
                                            if self.cursorPosX and self.cursorPosY then
                                                    text = string.sub(text, 1, w - self.cursorPosX + 1) .. ""
                                                    if self.cursorPosX <= 0 then
                                                            text = string.sub(text, math.abs(self.cursorPosX)+2, #text) .. ""
                                                            pH.setCursorPos(self.startX, self.realCursorPosY)
                                                    else
                                                            pH.setCursorPos(self.realCursorPosX, self.realCursorPosY)
                                                    end
                                                    pH.setTextColour(self.textColour)
                                                    pH.setBackgroundColour(self.backgroundColour)
                                                    pH.write(text)
                                            end
                                    end;
                                   
                                    -- clear
                                    clear = function()
                                            pH.setBackgroundColour(self.backgroundColour)
                                            for i=self.startY, self.endY do
                                                    pH.setCursorPos(self.startX, i)
                                                    pH.write(string.rep(" ", w))
                                            end
                                    end;
                                   
                                    -- clearLine
                                    clearLine = function()
                                            pH.setBackgroundColour(self.backgroundColour)
                                            pH.setCursorPos(self.startX, self.realCursorPosY)
                                            pH.write(string.rep(" ", w))
                                    end;
                                   
                                    -- drawBorder
                                    drawBorder = function(horChar, verChar, cornerChar)
                                            pH.setTextColour(self.textColour)
                                            pH.setBackgroundColour(self.backgroundColour)
                                           
                                            pH.setCursorPos(self.startX, self.startY)
                                            pH.write(string.rep(string.sub(horChar, 1, 1) .. "", w))
                                           
                                            pH.setCursorPos(self.startX, self.endY)
                                            pH.write(string.rep(string.sub(horChar, 1, 1) .. "", w))
                                           
                                            for i=1, h do
                                                    pH.setCursorPos(self.startX, self.startY + i - 1)
                                                    pH.write(string.sub(verChar, 1, 1) .. "")
                                                    pH.setCursorPos(self.endX, self.startY + i - 1)
                                                    pH.write(string.sub(verChar, 1, 1) .. "")
                                            end
                                           
                                            pH.setCursorPos(self.startX, self.startY)
                                            pH.write(string.sub(cornerChar, 1, 1) .. "")
                                            pH.setCursorPos(self.endX, self.startY)
                                            pH.write(string.sub(cornerChar, 1, 1) .. "")
                                            pH.setCursorPos(self.startX, self.endY)
                                            pH.write(string.sub(cornerChar, 1, 1) .. "")
                                            pH.setCursorPos(self.endX, self.endY)
                                            pH.write(string.sub(cornerChar, 1, 1) .. "")
                                    end;
                                   
                                    -- fill
                                    fill = function(char)
                                            pH.setBackgroundColour(self.backgroundColour)
                                            pH.setTextColour(self.textColour)
                                            for i=1, h do
                                                    pH.setCursorPos(self.startX, self.startY + i - 1)
                                                    pH.write(string.rep(string.sub(char, 1, 1) .. "", w))
                                            end
                                    end;
                                   
                                    -- getSectionID
                                    getSectionID = function()
                                            return sectionID
                                    end;
                                   
                                    -- registerHitbox
                                    registerHitbox = function(name, startX, startY, endX, endY)
                                            table.insert(hitboxes, {name = name; section = sectionID; startX = self.startX + startX - 1; startY = self.startY + startY - 1; endX = self.endX + startX - 1; endY = self.startY + endY - 1;})
                                    end;
                                   
                                    -- isColour
                                    isColour = function()
                                            return pH.isColour()
                                    end;
                                   
                                    -- isColor
                                    isColor = function()
                                            return pH.isColour()
                                    end;
                                   
                                    -- clearHitbox
                                    clearHitbox = function()
                                            local toDelete = {}
                                            for k, v in pairs(hitboxes) do
                                                    if v.section == sectionID then
                                                            toDelete[#toDelete+1] = k
                                                    end
                                            end
                                            for k, v in pairs(toDelete) do
                                                    hitboxes[v] = nil
                                            end
                                    end;
                                   
                                    -- delete
                                    delete = function()
                                            monitor["sections"][sectionID] = nil
                                    end;
                            }
                            return functions
                    end
                    return monitors[side]
            else
                    if peripheral.isPresent(side) then
                            error("No peripherals on " .. side)
                    else
                            error("Peripheral on " .. side .. " not monitor")
                    end
            end
    end

