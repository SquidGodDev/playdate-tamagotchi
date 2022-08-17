import "scripts/garden/gardenGrid"
import "scripts/garden/seedList"

local pd <const> = playdate
local gfx <const> = pd.graphics

local gardenLevels = {
    {
        minRow = 3,
        maxRow = 3,
        minCol = 4,
        maxCol = 5
    },
    {
        minRow = 2,
        maxRow = 3,
        minCol = 4,
        maxCol = 5
    },
    {
        minRow = 2,
        maxRow = 4,
        minCol = 4,
        maxCol = 5
    },
    {
        minRow = 2,
        maxRow = 4,
        minCol = 3,
        maxCol = 5
    },
    {
        minRow = 2,
        maxRow = 4,
        minCol = 3,
        maxCol = 6
    },
    {
        minRow = 2,
        maxRow = 4,
        minCol = 2,
        maxCol = 6
    },
    {
        minRow = 2,
        maxRow = 4,
        minCol = 2,
        maxCol = 7
    },
    {
        minRow = 1,
        maxRow = 4,
        minCol = 2,
        maxCol = 7
    },
    {
        minRow = 1,
        maxRow = 5,
        minCol = 2,
        maxCol = 7
    },
    {
        minRow = 1,
        maxRow = 5,
        minCol = 1,
        maxCol = 7
    },
    {
        minRow = 1,
        maxRow = 5,
        minCol = 1,
        maxCol = 8
    }
}

class('GardenScene').extends(gfx.sprite)

function GardenScene:init()
    local background = gfx.image.new("images/garden/gardenBackground")
    self:moveTo(200, 120)
    self:setImage(background)
    self:add()

    local gardenLevel = 11
    local minRow = gardenLevels[gardenLevel].minRow
    local maxRow = gardenLevels[gardenLevel].maxRow
    local minCol = gardenLevels[gardenLevel].minCol
    local maxCol = gardenLevels[gardenLevel].maxCol
    GardenGrid(minRow, maxRow, minCol, maxCol)
    SeedList()
end