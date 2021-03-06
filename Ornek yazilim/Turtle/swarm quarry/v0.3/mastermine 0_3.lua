	

    -- Mastermine is a Master part of turtle swarm quarry made by PonyKuu
    -- It uses my master API v0.2a
     
    -- Version 0.3
     
    os.loadAPI ("master")
     
    -- *******************************************************************************************
    -- * Module Distribution *
    -- *******************************************************************************************
     
    -- Plain distribution just assigning the mining locations side-by-side.
    -- It tries to pack more modules in the hole, so it distributes all the modules along the longest direction
    local function plainDistribution (start, dimensions, taskTable)
    if dimensions.x < dimensions.z then
    for i = 0, dimensions.z-1 do
    local mineLocation = {x = start.x, y = start.y, z = start.z + i, f = 0}
    table.insert (taskTable, master.makeTask ("Mine", mineLocation, {length = dimensions.x, depth = dimensions.y}))
    end
    else
    for i = 0, dimensions.x-1 do
    local mineLocation = {x = start.x + i, y = start.y, z = start.z, f = 1}
    table.insert (taskTable, master.makeTask ("Mine", mineLocation, {length = dimensions.z, depth = dimensions.y}))
    end
    end
    end
     
     
    -- this one is splits the area to two areas. axis is the axis that would be split
    local function splitArea (start, dimensions, axis)
    assert (type(start) == "table", "Bad starting coordinates: Table required, got "..type(start), 2)
    assert (type(dimensions) == "table", "Bad quarry dimensions: Table required, got "..type(dimensions), 2)
    assert (type(axis) == "string", "Bad axis: String required, got "..type(axis), 2)
    -- a little function to copy a table
    local function tCopy (tTable)
    local newTable = {}
    for k, v in pairs (tTable) do
    newTable[k] = v
    end
    return newTable
    end
    -- make two copies of each table and change the corresponding fields.
    local startOne = tCopy (start)
    local dimensionsOne = tCopy (dimensions)
    dimensionsOne[axis] = math.floor(dimensions[axis]/2)
     
    local startTwo = tCopy (start)
    startTwo[axis] = start[axis] + math.floor(dimensions[axis]/2)
    local dimensionsTwo = tCopy (dimensions)
    dimensionsTwo[axis] = math.ceil(dimensions[axis]/2)
     
    return startOne, dimensionsOne, startTwo, dimensionsTwo
    end
     
    -- This one tries to distribute all the available modules. Minimum slice length is 5
    local function distribute (start, dimensions, moduleCount, taskTable)
    -- if we can pack all the modules in one layer, just do it!
    if moduleCount <= dimensions.x or moduleCount <= dimensions.z then
    plainDistribution (start, dimensions, taskTable)
    -- Also use plain distribution if quarry is less than 8x8
    elseif dimensions.x <= 10 and dimensions.z <= 10 then
    plainDistribution (start, dimensions, taskTable)
    -- in any other case, divide the area into two pieces and call distribute again
    -- division is done by the longest dimension
    elseif dimensions.z < dimensions.x then
    local startOne, dimensionsOne, startTwo, dimensionsTwo = splitArea (start, dimensions, "x")
    distribute (startOne, dimensionsOne, math.floor(moduleCount/2), taskTable)
    distribute (startTwo, dimensionsTwo, math.ceil(moduleCount/2), taskTable)
    else
    local startOne, dimensionsOne, startTwo, dimensionsTwo = splitArea (start, dimensions, "z")
    distribute (startOne, dimensionsOne, math.floor(moduleCount/2), taskTable)
    distribute (startTwo, dimensionsTwo, math.ceil(moduleCount/2), taskTable)
    end
    end
     
    -- *******************************************************************************************
    -- * User Input Validation *
    -- *******************************************************************************************
     
    local tArgs = {...}
     
    if #tArgs ~= 6 then
    print ("Usage: mastermine <xstart> <ystart> <zstart> <xsize> <ysize> <zsize>")
    return
    end
     
    -- convert all the parameters into numbers
    for index, value in ipairs (tArgs) do
    tArgs[index] = tonumber (value)
    assert (type(tArgs[index] == "number", "Usage: mastermine <xstart> <ystart> <zstart> <ysize> <xsize> <zsize>", -1))
    end
     
    -- and insert them into tables
    local quarryStart = {
    x = tArgs[1],
    y = tArgs[2],
    z = tArgs[3]
    }
    local quarryDimensions = {
    x = tArgs[4],
    y = tArgs[5],
    z = tArgs[6]
    }
     
    -- *******************************************************************************************
    -- * Initialization *
    -- *******************************************************************************************
     
    -- Let's set up the equipment configuration (it is default, but meh) We need to know how many modules we have before distributing them
    master.setEquipment {Fuel = 1, Stuff = 2, Turtle = 3}
    local modules = math.min (turtle.getItemCount(1), turtle.getItemCount(2), turtle.getItemCount(3))
     
     -- Calculate the navigation zones.
    local naviX = quarryStart.x + math.ceil(quarryDimensions.x / 2)
    local naviZ = quarryStart.z + math.ceil(quarryDimensions.z / 2)
    local naviHeight = quarryStart.y + 3
    master.setNavigation {x = naviX, z = naviZ, height = naviHeight}
     
    -- set up a table with all the mining tasks
    local mineTasks = {}
    -- Distribute all the modules
    distribute (quarryStart, quarryDimensions, modules, mineTasks)
     
    local function mineMachine (ID)
    -- If there are tasks in the task table
    if #mineTasks > 0 then
    master.setState (ID, "Mining")
    -- remove one from table
    local nextTask = table.remove (mineTasks)
    -- Some debug output
    print ("Module ", ID, " is mining at {", nextTask.x, " ,", nextTask.y, " ,", nextTask.z, "}")
    -- And send that task
    return nextTask
    else
    -- No locations. Return home.
    master.setState(ID, "Returning")
    print ("Module ", ID, " is returning to Master")
    return master.makeReturnTask ()
    end
    end
     
    -- Associate this function with type "Miner"
    master.setType("Miner", mineMachine)
    -- And initialize the master
    master.init("modulemine", 100, 1000, #mineTasks)
     
    local function stateFunction ()
    return #mineTasks > 0
    end
    master.operate (stateFunction)
    print "Mining finished! Have a nice day!"

