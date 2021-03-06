	

    -- Mastermine is a Master part of turtle swarm quarry made by PonyKuu
    -- It uses my master API
     
    -- version 0.1
     
    os.loadAPI ("master")
     
    local tArgs = {...}
     
    if #tArgs ~= 5 then
        print ("Usage: mastermine <xstart> <ystart> <zstart> <xsize> <zsize>")
        return
    end
     
    -- set up a table with all the mining locations
    local mineLocations = {}
    local xstart, ystart, zstart, xsize, zsize = unpack (tArgs)
    for i = 0, xsize/4 - 1 do
        for j = 0, zsize/4 - 1 do
            local x = xstart + i*4
            local z = zstart + j*4
            table.insert (mineLocations, {x = x, y = ystart, z = z, f = 0})
        end
    end
     
    -- Calculate the navigation zones. The point that divides area into zones is in the middle of the mining area.
    local naviX = xstart + xsize/2
    local naviZ = zstart + zsize/2
    local naviHeight = ystart + 2
    master.setNavigation (naviX, naviZ, naviHeight)
     
    local function mineMachine (ID)
        -- If there are untouched locations
        if #mineLocations > 0 then
            master.setState (ID, "Mining")
            -- remove one from table
            local nextLocation = table.remove (mineLocations)
            -- Some debug output
            print ("Module ", ID, " is mining at {", nextLocation.x, " ,", nextLocation.y, " ,", nextLocation.z, "}")
            -- And make a task to mine that location
            return master.makeTask ("Mine", nextLocation, {holeSize = 4})
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
    master.init("modulemine", 100, 1000, #mineLocations)
     
    local function stateFunction ()
        if #mineLocations > 0 then
            return true
        else
            return false
        end
    end
    master.operate (stateFunction)
    print "Mining finished! Have a nice day!"

