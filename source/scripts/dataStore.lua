
-- === SHOP ===
GEMS = 100
DAILY_SHOP_ITEMS = nil

-- === WISH ===
WISH_GRANTED = false
WISH_GRANT_TIME = {
    year = 1999,
    month = 12,
    day = 31
}

-- === PETS ===
SELECTED_PET = "Hachi"
PETS = {
    Hachi = {
        type = "dog",
        hunger = {
            level = 10,
            lastTime = playdate.getTime()
        },
        lastPet = playdate.getTime(),
        lastGamePlay = playdate.getTime(),
        level = 1,
        xp = 0
    }
}

-- === GARDEN ===
PLANTS_IN_ORDER = {'turnip', 'eggplant', 'lettuce', 'cherry', 'potato', 'carrot', 'mushroom', 'pumpkin', 'pineapple', 'apple', 'pear', 'corn', 'strawberry', 'grape'}

PLANT_INVENTORY = {}
for _, plant in ipairs(PLANTS_IN_ORDER) do
    PLANT_INVENTORY[plant] = {
        seeds = 10,
        plant = 10
    }
end

GARDEN_DATA = {}
for row=1,5 do
    GARDEN_DATA[row] = {}
    for col=1,8 do
        GARDEN_DATA[row][col] = nil
    end
end
