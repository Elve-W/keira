--[[

   #####                                ##
  ##   ##                               ##
  ##       ##  ##  ## ###    #####    ######    #####   ##  ##   #####
  ##       ##  ##  ###  ##  ##   ##     ##     ##   ##  ##  ##  ##
  ##  ###  ##  ##  ##   ##  ##   ##     ##     ##   ##  ##  ##   ####
  ##   ##  ##  ##  ##   ##  ##   ##     ##     ##   ##  ##  ##      ##
   #####    #####  ##   ##   #####       ###    #####    #####  #####

  Автор: Андрій "^_^"
  Ідея: Breakout (1976) / Arkanoid (1986)

--]]

-------------------------------------------------------------------------------
-- Константи екрану
-------------------------------------------------------------------------------

SCREEN_W = display.width
SCREEN_H = display.height

WHITE = display.color565(255, 255, 255)
BLACK = display.color565(0, 0, 0)
RED   = display.color565(255, 0, 0)

-------------------------------------------------------------------------------
-- Параметри блоків
-------------------------------------------------------------------------------

COLS = 11
ROWS = 4
SPACING_X = 1
SPACING_Y = 6
START_Y   = 20

BLOCK_W = math.floor((SCREEN_W - (COLS - 1) * SPACING_X) / COLS)
BLOCK_H = 14

BLOCK_COLORS = {
  display.color565(176, 244, 66),   -- Acid green
  display.color565(178, 132, 190),  -- African violet
  display.color565(124, 185, 232),  -- Aero
  display.color565(241, 156, 187),  -- Amaranth pink
  display.color565(145, 92, 131),   -- Antique fuchsia
  display.color565(132, 132, 130),  -- Battleship gray
  display.color565(255, 215, 0)     -- Gold
}

-------------------------------------------------------------------------------
-- Звуки
-------------------------------------------------------------------------------

HIT_SOUND = {
  {880, 8}, {784, 8}, {698, 8}
}

WALL_SOUND = {
  {523, 8}, {659, 8}
}

LOSE_LIFE_SOUND = {
  {220, 8}, {196, 8}, {175, 8}, {165, 8}
}

LEVEL_UP_SOUND = {
  {440, 8}, {523, 8}, {659, 8}, {880, 8}
}

-------------------------------------------------------------------------------
-- Класи гри
-------------------------------------------------------------------------------

Block = {
  x = 0, y = 0, type = 0, hp = 1
}
function Block:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end
function Block:draw()
  if self.hp > 0 then
    display.fill_rect(self.x, self.y, BLOCK_W, BLOCK_H, BLOCK_COLORS[self.type + 1])
  end
end

Ball = {
  x = SCREEN_W/2,
  y = 175,
  r = 8,
  hp = 3,
  dx = 2,
  dy = -2,
  startX = SCREEN_W/2,
  startY = 175
}
function Ball:reset()
  self.x = self.startX
  self.y = self.startY
  self.dx = 2
  self.dy = -2
end
function Ball:update()
  if self.hp <= 0 then return end
  self.x = self.x + self.dx
  self.y = self.y + self.dy

  if self.x < self.r then 
    self.x = self.r; self.dx = -self.dx
    buzzer.play_melody(WALL_SOUND, 100)
  end
  if self.x + self.r > SCREEN_W then 
    self.x = SCREEN_W - self.r; self.dx = -self.dx
    buzzer.play_melody(WALL_SOUND, 100)
  end
  if self.y < self.r then 
    self.y = self.r; self.dy = -self.dy
    buzzer.play_melody(WALL_SOUND, 100)
  end
  if self.y + self.r > SCREEN_H then
    self.hp = self.hp - 1
    buzzer.play_melody(LOSE_LIFE_SOUND, 400)
    if self.hp > 0 then self:reset() end
  end
end
function Ball:draw()
  if self.hp > 0 then
    display.fill_circle(self.x, self.y, self.r, RED)
  end
end

Paddle = {
  x = SCREEN_W/2,
  y = 210,
  len = 100,
  thickness = 8,
  startX = SCREEN_W/2,
  startY = 210
}
function Paddle:reset()
  self.x = self.startX
  self.y = self.startY
end
function Paddle:move(dx)
  self.x = self.x + dx
  if self.x - self.len/2 < 0 then self.x = self.len/2 end
  if self.x + self.len/2 > SCREEN_W then self.x = SCREEN_W - self.len/2 end
end
function Paddle:draw()
  display.fill_rect(self.x - self.len/2, self.y - self.thickness/2, self.len, self.thickness, BLACK)
end

-------------------------------------------------------------------------------
-- Стан гри
-------------------------------------------------------------------------------

STATES = { HELLO=0, IN_GAME=1, GAME_OVER=2 }
game_state = STATES.HELLO

blocks = {}
ball = Ball
paddle = Paddle
level = 1

-------------------------------------------------------------------------------
-- Ініціалізація блоків
-------------------------------------------------------------------------------
function init_blocks()
  blocks = {}
  local idx = 0
  for r = 0, ROWS-1 do
    for c = 0, COLS-1 do
      local x = c * (BLOCK_W + SPACING_X)
      local y = START_Y + r * (BLOCK_H + SPACING_Y)
      local t = idx % 7
      local hp = (t < 5) and 1 or (t == 5 and 3 or 2)
      table.insert(blocks, Block:new{ x=x, y=y, type=t, hp=hp })
      idx = idx + 1
    end
  end
end

-------------------------------------------------------------------------------
-- Restart
-------------------------------------------------------------------------------
function restart_game()
  level = 1
  ball.hp = 3
  ball:reset()
  paddle:reset()
  init_blocks()
  game_state = STATES.IN_GAME
end

-------------------------------------------------------------------------------
-- Update
-------------------------------------------------------------------------------
function lilka.update(delta)
  local state = controller.get_state()

-- Вихід з гри
if state.d.just_pressed then
    util.exit()
end


  if game_state == STATES.HELLO then
    if state.start.just_pressed then
      restart_game()
    end
    return
  end

  if game_state == STATES.GAME_OVER then
    if state.b.just_pressed then
      restart_game()
    end
    return
  end

  -- керування
  local dx = 0
  if state.left.pressed then dx = -5 end
  if state.right.pressed then dx = 5 end
  paddle:move(dx)

  -- м’яч
  ball:update()
  if ball.hp <= 0 then 
    game_state = STATES.GAME_OVER 
  end

  -- відбивання від ракетки
  if ball.y + ball.r >= paddle.y - paddle.thickness/2
     and ball.x >= paddle.x - paddle.len/2
     and ball.x <= paddle.x + paddle.len/2
  then
    ball.dy = -math.abs(ball.dy)
    ball.y = paddle.y - paddle.thickness/2 - ball.r
    buzzer.play_melody(HIT_SOUND, 150)
  end

  -- блоки
  local allDestroyed = true
  for _, b in ipairs(blocks) do
    if b.hp > 0 then allDestroyed = false end
    -- перевірка зіткнення
    if b.hp > 0 and
       ball.x + ball.r > b.x and ball.x - ball.r < b.x + BLOCK_W and
       ball.y + ball.r > b.y and ball.y - ball.r < b.y + BLOCK_H then
      b.hp = b.hp - 1
      ball.dy = -ball.dy
      buzzer.play_melody(HIT_SOUND, 200)
    end
  end
  if allDestroyed then
    init_blocks()
    ball:reset()
    paddle:reset()
    level = level + 1
    buzzer.play_melody(LEVEL_UP_SOUND, 300)
  end
end

-------------------------------------------------------------------------------
-- Draw
-------------------------------------------------------------------------------
function lilka.draw()
  display.fill_screen(WHITE)

  if game_state == STATES.HELLO then
    display.set_cursor(80, SCREEN_H/2)
    display.print("PRESS START")
    return
  end

  if game_state == STATES.GAME_OVER then
    display.fill_screen(BLACK)
    display.set_cursor(80, SCREEN_H/2 - 20)
    display.print("GAME OVER")
    display.set_cursor(70, SCREEN_H/2 + 20)
    display.print("Levels passed: " .. (level-1))
    display.set_cursor(60, SCREEN_H/2 + 50)
    display.print("PRESS B TO RESTART")
    return
  end

  -- блоки
  for _, b in ipairs(blocks) do b:draw() end
  -- м’яч і платформа
  ball:draw()
  paddle:draw()
  -- рівень
  display.set_cursor(5, 5)
  display.print("Level: " .. level)
end
