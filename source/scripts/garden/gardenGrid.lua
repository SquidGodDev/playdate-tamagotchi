-- I used a gridview for the plot data. This file handles all the planting, drawing,
-- growing, and harvesting of the plants

local pd <const> = playdate
local gfx <const> = pd.graphics

local gardenData

class('GardenGrid').extends(gfx.sprite)

function GardenGrid:init(minRow, maxRow, minCol, maxCol, seedList)
    gardenData = GARDEN_DATA
    self.seedList = seedList

    self.gridview = pd.ui.gridview.new(36, 36)
    self.maxCols = 8
    self.maxRows = 5
    self.gridview:setNumberOfColumns(self.maxCols)
    self.gridview:setNumberOfRows(self.maxRows)

    self.gridWidth = 358
    self.gridHeight = 220
    self.edgePadding = 10
    self.gridview:setCellPadding(5, 5, 3, 3)

    -- This is a thing I've started doing, which is getting the metatable for the gridview
    -- and storing data in there. That way, inside the gridview drawCell method, you can use
    -- the self object and get data from it, which is pretty useful
    self.gridviewObject = getmetatable(self.gridview)
    self.gridviewObject.plotImage = gfx.image.new("images/garden/gardenPlot")
    self.gridviewObject.selectorImage = gfx.image.new("images/garden/plotSelector")

    local plantImages = {}
    for _, plantName in ipairs(PLANTS_IN_ORDER) do
        plantImages[plantName] = gfx.image.new("images/garden/plants/" .. plantName)
    end
    self.gridviewObject.plantImages = plantImages

    self.minCol = minCol
    self.maxCol = maxCol
    self.minRow = minRow
    self.maxRow = maxRow
    self.gridviewObject.minCol = self.minCol
    self.gridviewObject.maxCol = self.maxCol
    self.gridviewObject.minRow = self.minRow
    self.gridviewObject.maxRow = self.maxRow
    self.gridviewObject.seedsImage = gfx.image.new("images/garden/plants/seeds")
    self.gridviewObject.plantOffset = 10

    self.gridview:setSelection(1, 3, 4)

    function self.gridview:drawCell(section, row, column, selected, x, y, width, height)
        if row < self.minRow or row > self.maxRow or column < self.minCol or column > self.maxCol then
            return
        end
        if selected then
            local selectorWidth = self.selectorImage:getSize()
            local selectorOffset = (selectorWidth - width) / 2
            self.selectorImage:draw(x - selectorOffset, y - selectorOffset)
        end
        self.plotImage:draw(x, y)
        local plotData = gardenData[row][column]
        if plotData then
            if plotData.grown then
                local plantName = plotData.plant
                local plantImage = self.plantImages[plantName]
                plantImage:draw(x + self.plantOffset, y + self.plantOffset)
            else
                self.seedsImage:draw(x + self.plantOffset, y + self.plantOffset)
            end
        end
    end

    self:setCenter(0, 0)
    self:moveTo((400 - self.gridWidth) / 2 - 4, (240 - self.gridHeight + self.edgePadding) / 2 + 10)
    self:add()

    self.updateCounter = 0
    self.updateRate = 20
    self:updatePlants()

    self.plantSound = pd.sound.sampleplayer.new("sound/garden/plant")
    self.harvestSound = pd.sound.sampleplayer.new("sound/garden/plantHarvest")
end

function GardenGrid:update()
    local _, row, column = self.gridview:getSelection()
    local forceRedrawGrid = false

    -- I use a polling mechanism to make sure the plants update while you're in the
    -- garden scene. It updates about once every second
    self.updateCounter += 1
    if self.updateCounter % self.updateRate == 0 then
        forceRedrawGrid = self:updatePlants()
    end

    if pd.buttonJustPressed(pd.kButtonA) and not self.seedList.listOut then
        local plotData = GARDEN_DATA[row][column]
        local selectedPlant = self.seedList:getSelectedPlant()
        if not plotData then
            local plantSeeds = PLANT_INVENTORY[selectedPlant].seeds
            if plantSeeds > 0 then
                self.plantSound:play()
                PLANT_INVENTORY[selectedPlant].seeds -= 1
                -- So here is how I handle the plant growing, even when the playdate is sleeping.
                -- I store the time based on irl time that the plant should be grown by, and I can
                -- check the current time against that to see if it's past that time.
                GARDEN_DATA[row][column] = {
                    plant = selectedPlant,
                    grown = false,
                    growTime = self:getRandomGrowthTime()
                }
                forceRedrawGrid = true

            end
        else
            if plotData.grown then
                self.harvestSound:play()
                PLANT_INVENTORY[plotData.plant].plant += 1
                GARDEN_DATA[row][column] = nil
                forceRedrawGrid = true
            end
        end
    end

    if pd.buttonJustPressed(pd.kButtonUp) and not self.seedList.listOut then
        if row > self.minRow then
            self.gridview:selectPreviousRow(true)
        end
    elseif pd.buttonJustPressed(pd.kButtonDown) and not self.seedList.listOut then
        if row < self.maxRow then
            self.gridview:selectNextRow(true)
        end
    elseif pd.buttonJustPressed(pd.kButtonLeft) then
        if column > self.minCol then
            self.gridview:selectPreviousColumn(true)
        end
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        if column < self.maxCol then
            self.gridview:selectNextColumn(true)
        end
    end

    if self.gridview.needsDisplay or forceRedrawGrid then
        Signals:notify("updateGardenDisplay")
        local gridviewImage = gfx.image.new(self.gridWidth + self.edgePadding * 2, self.gridHeight + self.edgePadding * 2)
        gfx.pushContext(gridviewImage)
            self.gridview:drawInRect(0, 0, self.gridWidth + self.edgePadding * 2, self.gridHeight + self.edgePadding * 2)
        gfx.popContext()
        self:setImage(gridviewImage)
    end
end

-- How I get the growth time is I use get seconds since epoch, which returns the
-- number of seconds since the epoch time, which is January 1st, 1970, and then add
-- the amount of seconds I want it to take to grow, which basically sets a time in the
-- future that the plant should grow.
function GardenGrid:getRandomGrowthTime()
    local minTime = 600
    local maxTime = 1200
    local secondsSinceEpoch = pd.getSecondsSinceEpoch()
    return secondsSinceEpoch + math.random(minTime, maxTime)
end

function GardenGrid:updatePlants()
    local hasUpdated = false
    local secondsSinceEpoch = pd.getSecondsSinceEpoch()
    for i=self.minRow, self.maxRow do
        for j=self.minCol, self.maxCol do
            local plotData = GARDEN_DATA[i][j]
            if plotData then
                -- And here, I can just check if the current time is past the expected growth
                -- time
                if not plotData.grown and (secondsSinceEpoch >= plotData.growTime) then
                    GARDEN_DATA[i][j].grown = true
                    hasUpdated = true
                end
            end
        end
    end
    return hasUpdated
end

function GardenGrid:getSelectedPlot()
    local _, row, column = self.gridview:getSelection()
    return GARDEN_DATA[row][column]
end