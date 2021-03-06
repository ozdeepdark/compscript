	

    -- Mastermine is a Module part of turtle swarm quarry made by PonyKuu
    -- It uses my module API
     
    -- version 0.1
     
    os.loadAPI ("module")
     
    local function turn (direction)
        -- this is used to turn the turtle using numbers - it's useful in our layer-wiping code
        -- 1 - right
        -- -1 - left
        -- other - around
        if direction == 1 then
            module.turn ("right")
        elseif direction == -1 then
            module.turn ("left")
        else
            module.turn ("around")
        end
    end
     
    -- A function to dig a block under the module and chech if it should dump all the mined goods into chest
    local function digUnder ()
        turtle.digDown ()
        module.checkSpace()
    end
    local function makeLine (length) --a simple line function
        for i = 1, length-1 do
            digUnder ()
            if not module.move ("forward") then
                return false    --return false if it cannot move forward. That typically means the turtle hit bedrock.
            end
        end
        return true
    end
     
    local function wipeLayer (diameter)  --cleans a square layer
        local turnDirection = 1
        --the main algorithm
        for i = 1, diameter-1 do
            if not makeLine (diameter) then
                return false
            end
            turn (turnDirection)
            digUnder ()
            if not module.move ("forward") then
                return false
            end
            turn (turnDirection)
            turnDirection = -turnDirection
        end
        --finish the layer
        if not makeLine (diameter) then
            return false
        end
        if not module.move ("down") then
            return false --try to move down
        end
        if diameter % 2 == 0 then
            turn (1)    --turn right for the next layer if the diameter is even
        else
            turn (0)    --turn around if it is odd. A bit of magic here. That should work.
        end
        return true  --returns true if layer is done
    end
     
    local function makeHole (diameter) -- a main mining function
        local depth = 0
        while wipeLayer (diameter) do
            depth = depth+1
        end
        module.dumpStuff ()
        for i=1, depth do
            module.move ("up")
        end
        -- That's it! It's just wipes all the layers until it hits bedrock and returns to its initial depth
    end
     
    -- set up our Mine task
    module.addTasks {
        Mine = function (response)
            makeHole (response.holeSize)
        end
    }
    -- set up the module type to Miner
    module.setType ("Miner")
    module.init ()
    module.operate ()

