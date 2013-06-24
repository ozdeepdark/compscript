	

    ----------------------------------------------------------------------
    --                              Master API                          --
    ----------------------------------------------------------------------
     
    -- Version 0.1
     
    -- Master is an API that controls modules that use my module API.
    -- Master should have:
    --  1) fuel chest in the first slot.
    --  2) stuff chest in the second slot
    --  3) wireless mining turtle in the third slot
    --  4) Any number of fuel/stuff chests and wireless mining turtles in its inventory
    --  5) Note, that Master keeps at least one of each of those items in it's inventory.
    -- Master's job is to listen to requests and send responses.
    -- Usage:
    --  1) For each type of the module you use, make a function which returns a response which will determine what module will do.
    --     This function recieves the ID of that module as an argument
    --     Of course, your module should know about that response and have that in its task table.
    --     You can use master.makeTask(taskName, coordinates, additionalData) function to generate a task response.
    --     additionalData parameter is optional, and if you don't want to send any coordinates, pass an empty table as coordinates.
    --     There is a master.makeReturnTask() function added for convinience - it just makes a task that returns module to the Master
    --  2) Use master.setType(Type, taskFunction) function to associate that function with the type of the module
    --     you might want to change the state of the module in your taskFunction. Use master.getState(ID) and master.setState(ID, state)
    --     functions to do that. Initial state of each module is "Waiting"
    --  4) Set navigation zones for modules using the master.setNavigation(x, z, height) function
    --     Please notice that x, z are 2D coordinates and height is the height of the plane where all the navigation is done
    --  5) Initialize the master by running master.init(filename, ID, mainChannel, moduleCount) function
    --     Master should have module API on its disk and a script for modules (that's the filename argument)
    --     mainChannel is the channel on which master listens, and the moduleCount is the required amount of modules
    --     ID is a new ID of the Master
    --  6) make a stateFunction() that determines whether master should stop the operation. It should return false if it should stop
    --     and return true if it shouldn't. State function can do other things, such as reinitialization to a new module script and so on
    --     but it shouldn't take too much time to execute. Use master.reinit(filename, moduleCount) function to change the module script, if you want to.
    --  7) Run master.operate(stateFunction) to start.
     
    -- Some basic variables:
    -- MasterID is the unique identifier of master. Default is 100
    local MasterID = 100
     
    -- Channel is the channel Master listens.
    local channel
    -- Position is just the position of the Master.
    local Position = {x = 0, y = 0, z = 0, f = 0}
    -- New placed modules will request "Position" to know where they are.
    local modPosition = {x = 1, y = 0, z = 0, f = 0}
     
    -- naviZones is used by modules to navigate and not interlock themselves
    local naviZones = {x = 0, z = 0, height = 0}
    function setNavigation (x, z, height)
        naviZones = {x = x, z = z, height = height}
    end
     
    --[[
    *********************************************************************************************
    *                                    Communication Part                                     *
    *********************************************************************************************
    ]]--
     
    -- We need a modem to communicate.
    local modem = peripheral.wrap ("right")
     
    -- The first function is used to parse a message received on modem
    -- It determines whether the message is valid or not
    -- Message should be a table with fields
    --  1) Protocol - must be equal to "KuuNet"
    --  2) ID - that's a sender ID
    --  3) Master - that must be equal to MasterID variable.
    --  4) Type - the type of the module. Used to know how to handle its task requests
    --  Some other fields
    function isValid (message)
        if message ~= nil then
            if message.Protocol ~= "KuuNet" then
                return false
            end
            if message.ID == nil then
                return false
            end
            if message.Master ~= MasterID then
                return false
            end
            return true
        else
            return false
        end
    end
     
    -- The function that listens for a valid message and returns it
    function listen ()
        while true do
            local event, modemSide, sndChan, rplyChan, text_msg, senderDistance = os.pullEvent("modem_message")
            local msg = textutils.unserialize (text_msg)
            if isValid(msg) then
                return msg
            end
        end
    end
     
    -- And a function to send a response
    function response (ID, chan, message)
        message.Protocol = "KuuNet"
        message.ID = ID
        message.Master = MasterID
        modem.transmit (chan+1, chan, textutils.serialize(message))
    end
     
    --[[
    *********************************************************************************************
    *                                   Module Placement Part                                   *
    *********************************************************************************************
    ]]--
    -- moduleCount is the number of active modules
    -- needModules is the number of modules required
    -- modulesAvailable is the number of available modules
    local moduleCount = 0
    local needModules = 0
    local modAvailable = nil
    -- This function searches the turtle inventory for same item
    -- as in the given slot, or selects that slot if there are more than one item
    function searchItem (slot)
        turtle.select (slot)
        local found = 0
        for i=1,16 do
            if i ~= slot then
                if turtle.getItemCount (i) > 0 then
                    if turtle.compareTo (i) then
                        found = i
                    end
                end
            end
        end
        if found == 0 then
            if turtle.getItemCount (slot) > 1 then
                found = slot
            else
                turtle.select(1)
                return false
            end
        end
        turtle.select (found)
        return true
    end
    -- This is the function to search the whole inventory for the same items and return how many items are there
    local function countBySample (slot)
        turtle.select (slot)
        local count = 0
        for i = 1,16 do
            if turtle.compareTo(i) then
                count = count + turtle.getItemCount(i)
            end
        end
        return count
    end
    -- A function to know how many modules are available.
    -- A module is available if there is at least two turtles and at least two of each Ender chests left
    -- The counting takes some time, so there is a variable to speed up the process
    function availableModules ()
        if modAvailable == nil then
            local minimum = 1024
            for i = 1, 3 do
                local quantity = countBySample(i) - 1
                if minimum > quantity then
                    minimum = quantity
                end
            end
            modAvailable = minimum
        end
        return modAvailable
    end
    -- Function to place a new module
    function addModule ()
        searchItem (3)   -- search for a module
        if turtle.place () then  -- put it down
            searchItem (1)
            turtle.drop (1)  -- Add a fuel chest
            searchItem (2)
            turtle.drop (1)  -- And a stuff chest
            turtle.select (1)-- select first slot to make things look good :)
            peripheral.call ("front", "turnOn")    -- Turn on the module    
            modAvailable = modAvailable - 1
        end
    end
     
    --[[
    *********************************************************************************************
    *                                       Operation Part                                      *
    *********************************************************************************************
    ]]--
     
    -- This is a table that contains all the states of the modules.
    -- Indexes of that table are ID's and values are tables with following fields
    --  1) Type - type of the module. Each Type has it's own task table
    --  2) State - the state of the module. List of states is unique for each module type, but there are some common states: "Waiting" and "Returning"
    tStates = {}
     
    -- There is a function that searches for a free ID. Let's limit the maximun number of IDs to 1024
    function freeID ()
        for i = 1, 1024 do
            if tStates [i] == nil then
                return i
            end
        end
    end
     
    -- Tasks table. I'll explain it a bit later
    tTasks = {}
     
    -- Here is the table used to handle the requests.
    tRequests = {
        -- "Master" is the request sent by new modules. We should assign a new ID to it and remember that ID in tStates table
        Master = function (request)
            local ID = freeID ()
            response (request.ID, channel, {NewID = ID})
            tStates[ID] = {State = "Waiting", Type = request.Type}
            moduleCount = moduleCount + 1
        end,
        -- Task is the request used to reques the next thing module should do
        -- It uses the tTasks table. There is a function for each module type which returns a response
        -- Response may contain coordinate of the next place and id should contain "Task" field
        -- This function may do something else, change the state of module and so on.
        -- To associate it with the module, sender ID is passed to that function
        -- tTasks table should be filled by user of this API
        Task = function (request)
            response (request.ID, channel, tTasks[request.Type](request.ID))
        end,
        -- "Returned" is the request sent by module that has returned to Master and waiting there until Master collects it
        Returned = function (request)
            while turtle.suck () do end -- Get all the items that module had
            turtle.dig ()               -- And get the module back
            tStates[request.ID] = nil -- delete that module from our state table
            moduleCount = moduleCount - 1 -- and decrease the counter
            modAvailable = modAvailable + 1
        end
    }
     
    -- This is the variable used to determine whether the master should place modules
    local isPlacing = false
     
    -- This is the function used to place modules if there are any available and state is
    -- It automatically stops placing modules when there is enough modules
    function moduleManager ()
        while true do
            if isPlacing then
                if moduleCount == needModules or availableModules() == 0 then
                    isPlacing = false
                else
                    addModule ()
                end
            end
            sleep (6)
        end
    end
     
    -- The main operation function
    -- stateFunction is the function used to determine when master should stop.
    -- Master stops when there are to active modules and stateFunction returns false.
    -- State function can do other things, such as reinitialization to a new module script and so on, but it shouldn't take too much time to execute
    function operate (stateFunction)
        local server = function ()
            while stateFunction() or moduleCount > 0 do
                local request = listen ()
                tRequests[request.Request](request) -- Just execute the request handler.
            end
        end
        parallel.waitForAny (server, moduleManager)
        modem.closeAll ()
    end
     
    --[[
    *********************************************************************************************
    *                                    Initialization Part                                    *
    *********************************************************************************************
    ]]--
     
    -- Some basic movement and refueling
    -- Refuel assumes that Master has a bunch of fuel chests in slot 1 and slot 16 is empty
    function refuel (amount)
        if turtle.getFuelLevel () > amount then
            return true
        else
            turtle.select (1)
            turtle.placeUp ()
            turtle.select (16)
                turtle.suckUp ()
                while turtle.refuel (1) do
                    if turtle.getFuelLevel() >= amount then
                        turtle.dropUp ()
                        turtle.select (1)
                        turtle.digUp ()
                        return true
                    end
                    if turtle.getItemCount (1) == 0 then
                        turtle.suckUp ()
                    end
                end
            end
        turtle.dropUp ()
        turtle.select (1)
        turtle.digUp ()
        return false
    end
     
    local tMoves = {
        forward = turtle.forward,
        back = turtle.back
    }
    function forceMove (direction)
        refuel (1)
        while not tMoves[direction]() do
            print "Movement obstructed. Waiting"
            sleep (1)
        end
    end
     
    -- The function to set the "task" function for the said module type
    function setType (Type, taskFunction)
        tTasks[Type] = taskFunction
    end
     
    -- The initialization function of the master.
    -- Filename is the name of module's script. It will be copied on the disk drive
    function init (filename, ID, mainChannel, moduleCount)
        -- Set the ID of the Master
        MasterID = ID
        -- Set the main channel and listen on said channel
        channel = mainChannel
        modem.open (channel)
       
        -- Next, we need to know the position of the master.
        -- If gps is not found, use relative coordinates
        modem.open(gps.CHANNEL_GPS)
        local gpsPresent = true
        local x, y, z = gps.locate(5)
        if x == nil then
            x, y, z = 0, 0, 0
            gpsPresent = false
        end
       
        -- Now we need to move forward to copy files on disk and determine our f
        forceMove ("forward")
        local newX, newZ = 1, 0 -- if there is no gps, assume that master is facing positive x
        if gpsPresent then
            newX, __, newZ = gps.locate (5)
        end
        modem.close(gps.CHANNEL_GPS)
        -- Determine f by the difference of coordinates.
        local xDiff = newX - x
        local zDiff = newZ - z
        if xDiff ~= 0 then
            if xDiff > 0 then
                f = 0     -- Positive x
            else
                f = 2     -- Negative x
            end
        else
            if zDiff > 0 then
                f = 1     -- Positive z
            else
                f = 3     -- Negative z
            end
        end
        -- And set the position and modPosition variables.
        Position = {x = x, y = y, z = z, f = f}
        modPosition = {x = newX, y = y, z = newZ, f = f}
       
        -- Copy all the required files on the disk
        if fs.exists ("/disk/module") then
            fs.delete ("/disk/module")
        end
        fs.copy ("module", "/disk/module")
        if fs.exists ("/disk/"..filename) then
            fs.delete ("/disk/"..filename)
        end
        fs.copy (filename, "/disk/"..filename)
        -- Make a startup file for modules
        local file = fs.open ("/disk/startup", "w")
        file.writeLine ("shell.run(\"copy\", \"/disk/module\", \"/module\")")
        file.writeLine ("shell.run(\"copy\", \"/disk/"..filename.."\", \"/startup\")")
        file.writeLine ("shell.run(\"startup\")")
        file.close()
       
        -- Now, make a file with the data modules need
        file = fs.open ("/disk/initdata", "w")
        -- Communication data: master ID and communication channel
        file.writeLine (textutils.serialize ({MasterID = MasterID, channel = channel}) )
        -- Location data:
        file.writeLine (textutils.serialize (modPosition))
        -- Navigation data:
        file.writeLine (textutils.serialize (naviZones))
        file.close()
       
        -- And go back to initial location
        forceMove ("back")
       
        -- Set the amount of modules needed. I use "+" because one can run init again to add a different type of module to the operation
        needModules = needModules + moduleCount
        -- And start placing them
        isPlacing = true
    end
     
     
    --[[
    *********************************************************************************************
    *                                       Utility Part                                        *
    *********************************************************************************************
    ]]--
     
    -- This is just a return response added for convinience, because every task function should return the module eventually.
    function makeReturnTask ()
        -- return position is two block away of Master. So, let's calculate it.
        local tShifts = {
            [0] = { 1,  0},
            [1] = { 0,  1},
            [2] = {-1,  0},
            [3] = { 0, -1},
        }
        local xShift, zShift = unpack (tShifts[modPosition.f])
        returnX = modPosition.x + xShift
        returnZ = modPosition.z + zShift
        return {   Task = "Return",
            x = returnX,
            y = modPosition.y,
            z = returnZ,
            f = (modPosition.f+2)%4, -- basically, reverse direction
        }
    end
     
    -- And a function to make any other task
    -- additionalData is optional. coordinates can be an empty table
    function makeTask (taskName, coordinates, additionalData)
        local newTask = {Task = taskName}
        for key, value in pairs (coordinates) do  
            newTask[key] = value
        end
        if additionalData ~= nil then
            for key, value in pairs (additionalData) do  
                newTask[key] = value
            end
        end
        return newTask
    end
     
    function getState (ID)
        return tStates[ID].State
    end
     
    function setState (ID, newState)
        tStates[ID].State = newState
    end
     
    -- reinit function is just a simplified init, that doesn't update channel, MasterID and Master's position. Use it to change the modules script
     function reinit (filename, moduleCount)
        forceMove ("forward")
        -- Copy all the required files on the disk
        if fs.exists ("/disk/module") then
            fs.delete ("/disk/module")
        end
        fs.copy ("module", "/disk/module")
        if fs.exists ("/disk/"..filename) then
            fs.delete ("/disk/"..filename)
        end
        fs.copy (filename, "/disk/"..filename)
        -- Make a startup file for modules
        local file = fs.open ("/disk/startup", "w")
        file.writeLine ("shell.run(\"copy\", \"/disk/module\", \"/module\")")
        file.writeLine ("shell.run(\"copy\", \"/disk/"..filename.."\", \"/startup\")")
        file.writeLine ("shell.run(\"startup\")")
        file.close()
       
        -- Now, make a file with the data modules need
        file = fs.open ("/disk/initdata", "w")
        -- Communication data: master ID and communication channel
        file.writeLine (textutils.serialize ({MasterID = MasterID, channel = channel}) )
        -- Location data:
        file.writeLine (textutils.serialize (modPosition))
        -- Navigation data:
        file.writeLine (textutils.serialize (naviZones))
        file.close()
       
        -- And go back to initial location
        forceMove ("back")
       
        -- Set the amount of modules needed. I use "+" because one can run init again to add a different type of module to the operation
        needModules = needModules + moduleCount
        -- And start placing them
        isPlacing = true
    end

