	

    -- Mastermine is a Module part of turtle swarm quarry made by PonyKuu
    -- It uses my module API v0.2a
     
    -- Version 0.3
     
    os.loadAPI ("module")
     
    -- this function is used to carefuly move forward, digging the blocks below and above the module and not trap itself under bedrock
    -- it returns how many times it has ascended and a boolean which is true if module was maneuvering around bedrock.
    local function safeForward ()
    -- this variable stores how many times turtle ascended
    local ascended = 0
    -- this one stores how many times it should move forward
    local timesForward = 1
    -- this one is true if module was interacting with bedrock
    local hitBedrock = false
    while timesForward > 0 do
    -- try to move forward
    if not module.move("forward") then
    -- if failed, try to move up. And that means that we hit bedrock!
    hitBedrock = true
    if not module.move ("up") then
    -- if failed to move up, we are in serious trouble. Turn around and try to find a way back
    module.turn ("around")
    -- move back until we'll be able to move up
    while not module.move ("up") do
    --if we can't move forward, move down
    while not module.move ("forward") do
    module.move ("down")
    ascended = ascended - 1
    end
    -- increment the counter each time we move back
    timesForward = timesForward + 1
    end
    -- increment ascended variable if module succeeded to move up
    ascended = ascended + 1
    -- turn around when we outta that big trouble
    module.turn ("around")
    else
    -- increment ascended variable if module succeeded to move up
    ascended = ascended + 1
    end
    else
    -- decrement the counter if module succeded to move forward and dig the blocks above and below
    timesForward = timesForward - 1
    turtle.digUp ()
    module.checkSpace()
    turtle.digDown ()
    module.checkSpace ()
    end
    end
    return ascended, hitBedrock
    end
     
    -- this function is used to move up or down, while digging a 2x1 hole.
    -- it returns the actual number of blocks it moved if it hit bedrock
    local function column (direction, length)
    turtle.dig ()
    module.checkSpace ()
    for i = 1, length-1 do
    if not (module.move (direction)) then
    return i
    end
    turtle.dig ()
    module.checkSpace ()
    end
    return length
    end
     
    --- a small function which tries to dig a 1x3xlength line
    --- it returns how much time module ascended during that line and booleean that indicates if module hit bedrock
    local function makeLine (length)
    -- this variable is used to remember how much times module ascended while moving forward
    local ascended = 0
    -- this one is true if module was interacting with bedrock
    local hitBedrock = false
    -- at the begining of the line dig down
    turtle.digDown ()
    module.checkSpace ()
    -- check if module has the amount of fuel to move for 2xlength times, so it won't stuck under bedrock without being able to place the chest
    module.checkFuel (2*length)
    for i = 1, length-1 do
    local newAscended, bedrock = safeForward ()
    -- update ascended variable
    ascended = ascended + newAscended
    -- update bedrock flag, using boolean pony magic
    hitBedrock = hitBedrock or bedrock
    -- try to move down if ascended is greater than zero
    while ascended > 0 and module.move("down") do
    ascended = ascended - 1
    end
    end
    return ascended, hitBedrock
    end
     
     
    -- this is the main mining function
    local function slice (length, depth)
    -- if length is 2, 3, or 4, then use columns to make that hole
    if length < 5 then
    local realDepth = column ("down", depth)
    local ascended = 0
    for i = 1, length - 2 do
    ascended = ascended + safeForward ()
    end
    column ("up", realDepth - ascended)
    module.dumpStuff ()
    -- if length is 5 or more, just use plain old zig-zags
    else
    -- this variable is used to determine when module should stop mining
    local finish = false
    local currentDepth = 0
    while not finish do
    local ascended = 0
    -- change the depth if module has ascended and set finish to true if module has hit bedrock while moving
    ascended, finish = makeLine (length)
    currentDepth = currentDepth - ascended
    module.turn ("around")
    for i = 1, 3 do
    -- if module is deep enough or cannot move down, stop
    if not finish and currentDepth < depth - 1 and module.move ("down") then
    currentDepth = currentDepth + 1
    else
    finish = true
    break
    end
    end
    end
    -- make the last line and remember how much times module have ascended
    local ascended = makeLine (length)
    -- dump stuff and go up!
    module.dumpStuff ()
    for i = ascended, currentDepth - 1 do
    module.move ("up")
    end
    end
    end
     
    -- set up our Mine task
    module.addTasks {
    Mine = function (response)
    slice (response.length, response.depth)
    end
    }
    -- set up the module type to Miner
    module.setType ("Miner")
     
    -- set up the chest configuration
    module.setChests {Fuel = 1, Stuff = 2}
    -- get all the data from disk and Master
    module.init ()
    -- set fallback location
    local fallback = module.getPosition()
    fallback.y = module.getNaviData().height
    module.setFallback (fallback)
    module.operate ()

