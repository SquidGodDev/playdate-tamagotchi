-- This is the generic enemy class. I can use this class and extend it, switching up some of the properties,
-- and create a bunch of different enemies very easily. This is because this class defines all the building blocks,
-- like the AI, attack patterns, health, and movement

import "scripts/battle/playerAttackSprite"

local pd <const> = playdate
local gfx <const> = pd.graphics

class('BaseEnemy').extends(gfx.sprite)

function BaseEnemy:init(battleScene, image)
    self.battleScene = battleScene

    -- Some properties you can change when extending the class
    self.maxHealth = 100
    self.health = 0

    self.moveTime = 2000
    self.attackBias = 0.5
    self.attackDmg = 5
    self.teleporter = false

    self.row = 2
    self.baseX = 321
    self.baseY = 73
    self.gap = 51
    self:setCenter(0, 0)
    self:moveTo(self.baseX + 100, self.baseY + self.gap)
    self:setImage(image)
    self:add()

    self.dead = false

    self.warningSound = pd.sound.sampleplayer.new("sound/battle/warning")
    self.attackSound = pd.sound.sampleplayer.new("sound/battle/enemySlice")
end

function BaseEnemy:update()
    -- Handles the animation for attacking and when defeated
    if self.deathAnimator then
        self:moveTo(self.x, self.deathAnimator:currentValue())
        if self.deathAnimator:ended() then
            self:remove()
        end
    elseif self.attackAnimator then
        self:moveTo(self.attackAnimator:currentValue())
        if self.attackAnimator:ended() then
            self.attackAnimator = nil
        end
    end
end

-- This is the "AI", basically either attacking or moving based on a timer.
-- I can even define how likely the enemy is going to attack vs move
function BaseEnemy:createMoveTimer()
    self.moveTimer = pd.timer.new(self.moveTime, function()
        local randVal = math.random()
        if randVal >= self.attackBias then
            self:attack()
        else
            self:move()
        end
        self:createMoveTimer()
    end)
end

-- Generic function for when the enemy gets hit. Handles the flashing on hit
-- and death
function BaseEnemy:damage(dmg)
    self.health -= dmg
    if self.health <= 0 then
        self.dead = true
        self.health = 0
        if self.moveTimer then
            self.moveTimer:remove()
        end
        self.deathAnimator = gfx.animator.new(1000, self.y, 260, pd.easingFunctions.inBack)
    end
    self:setVisible(false)
    pd.timer.new(100, function()
        self:setVisible(true)
    end)
end

function BaseEnemy:attack()
    self.warningSound:play()
    local attackDist = 10
    local attackOutLine = pd.geometry.lineSegment.new(self.x, self.y, self.x - attackDist, self.y)
    local attackInLine = pd.geometry.lineSegment.new(self.x - attackDist, self.y, self.x, self.y)
    self.attackAnimator = gfx.animator.new({100, 100}, {attackOutLine, attackInLine}, {pd.easingFunctions.linear, pd.easingFunctions.linear})
    -- Extend
end

-- Defines how the enemy can move. If the enemy is a "teleporter", then it can move anywhere.
-- Otherwise, only to a random adjacent cell
function BaseEnemy:move()
    local validMoves
    if self.row == 1 then
        if self.teleporter then
            validMoves = {2, 3}
        else
            validMoves = {2}
        end
    elseif self.row == 2 then
        validMoves = {1, 3}
    elseif self.row == 3 then
        if self.teleporter then
            validMoves = {1, 2}
        else
            validMoves = {2}
        end
    end
    self.row = validMoves[math.random(1, #validMoves)]
    self:moveTo(self.baseX, self.baseY + (self.row - 1) * self.gap)
end

-- The next several functions are a bunch of different attack patterns that I can use in
-- the enemy subclasses to determine their attack pattern. I start off with a single cell
-- attack, and the other functions can just use a combination of that. Ends up being quite
-- elegant and easy to use - check out the individual enemies to see how I use it
function BaseEnemy:singleAttack(dmg, x, y)
    self.battleScene:createWarning(x, y)
    pd.timer.new(1200, function()
        if self.dead then
            return
        end
        self.attackSound:play()
        self.battleScene:damagePlayer(dmg, x, y)
        local gridBaseX = self.battleScene.gridBaseX
        local gridBaseY = self.battleScene.gridBaseY
        local gridGap = self.battleScene.gridGap
        PlayerAttackSprite(gridBaseX + (x - 1) * (gridGap), gridBaseY + (y - 1) * (gridGap))
    end)
end

function BaseEnemy:directSingleAttack(dmg)
    local attackX = math.random(1, 3)
    local attackY = self.row
    self:singleAttack(dmg, attackX, attackY)
end

function BaseEnemy:directRowAttack(dmg)
    for i=1,3 do
        self:singleAttack(dmg, i, self.row)
    end
end

function BaseEnemy:directDoubleAttack(dmg)
    local attackY = self.row
    local attackPattern = math.random(3)
    if attackPattern == 1 then
        self:singleAttack(dmg, 1, attackY)
        self:singleAttack(dmg, 2, attackY)
    elseif attackPattern == 2 then
        self:singleAttack(dmg, 2, attackY)
        self:singleAttack(dmg, 3, attackY)
    else
        self:singleAttack(dmg, 1, attackY)
        self:singleAttack(dmg, 3, attackY)
    end
end

function BaseEnemy:xAttack(dmg)
    local xPattern = math.random(2)
    if xPattern == 1 then
        self:singleAttack(dmg, 1, 1)
        self:singleAttack(dmg, 3, 1)
        self:singleAttack(dmg, 2, 2)
        self:singleAttack(dmg, 1, 3)
        self:singleAttack(dmg, 3, 3)
    else
        self:singleAttack(dmg, 2, 1)
        self:singleAttack(dmg, 1, 2)
        self:singleAttack(dmg, 2, 2)
        self:singleAttack(dmg, 3, 2)
        self:singleAttack(dmg, 2, 3)
    end
end

function BaseEnemy:columnAttack(dmg)
    local colPattern = math.random(2)
    if colPattern == 1 then
        self:singleAttack(dmg, 2, 1)
        self:singleAttack(dmg, 2, 2)
        self:singleAttack(dmg, 2, 3)
    else
        self:singleAttack(dmg, 1, 1)
        self:singleAttack(dmg, 1, 2)
        self:singleAttack(dmg, 1, 3)

        self:singleAttack(dmg, 3, 1)
        self:singleAttack(dmg, 3, 2)
        self:singleAttack(dmg, 3, 3)
    end
end