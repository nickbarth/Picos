pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- globals
----
gameover = false
actors = {}
ui = {}
score = 0

mode = {
  idle=0,
  move=1,
  attack=2
}

board = {
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
}

state = mode.a -- move
-- actor methods
----

-- destroy
function destroy(self)
  del(actors, self)
end

-- animation
function animate(self, frames, speed)
  if self.step % speed == 0 then
    self.cframe = (self.cframe + 1) % frames
  end
end

-- actors
----

-- sprite
make_sprite = function(x, y, frame)
  local self = {}
  self.x = x or 0
  self.y = y or 0
  self.dx = 0
  self.dy = 0
  self.frame = frame
  self.cframe = 0
  self.forward = true
  self.step = 0
  self.ddx = 0
  self.ddy = 0
  self.die = false

  -- state
  self.idle = true

  -- update
  function self.update(self)
  end

  -- draw
  function self.draw(self)
    local frame = self.cframe + self.frame
    spr(frame, self.x, self.y, 1, 1, not self.forward, false)
  end

  return self
end

-- ui
make_cursor = function(x, y)
  local self = make_sprite(x, y, 49)

  function controls(self)
    if btnp(0) then -- left
      self.x = (self.x - 8) % 64
    end

    if btnp(1) then -- right
      self.x = (self.x + 8) % 64
    end

    if btnp(2) then -- up
      self.y = (self.y - 8) % 56
    end

    if btnp(3) then -- down
      self.y = (self.y + 8) % 56
    end
  end

  self.update = function(self)
    self.step += 1
    controls(self)
    -- animate(self, 2, 15)
  end

  return self
end

make_toolbar = function(x, y)
  local self = make_sprite(x, y, 49)
  self.selected = 0

  function self.controls(self)
    if btnp(0) then -- left
      self.selected = (self.selected - 1) % 3
    end

    if btnp(1) then -- right
      self.selected = (self.selected + 1) % 3
    end
  end

  self.update = function(self)
    self.step += 1
    self:controls()
  end

  -- draw
  function self.draw(self)
    local frame = self.cframe + self.frame
    spr(29, self.x, self.y, 3, 1, false, false)

    if self.selected == 0 then
      spr(45, self.x, self.y, 1, 1, false, false)
    elseif self.selected == 1 then
      spr(46, self.x+8, self.y, 1, 1, false, false)
    elseif self.selected == 2 then
      spr(47, self.x+16, self.y, 1, 1, false, false)
    end
  end

  return self
end

-- avaliable moves
make_moves = function()
  local self = {}

  self.selected = 0
  self.target = { x=24, y=0, speed=2 }
  self.active = true

  -- update
  function self.update(self)
    debug = self.target.x
  end

  -- draw
  function self.draw(self)
    -- local frame = self.cframe + self.frame

    if self.active then
      local speed = self.target.speed
      local target = self.target

      for n=0, speed do 
        spr(51, target.x+(8 * n), target.y, 1, 1, false, false)
        spr(51, target.x-(8 * n), target.y, 1, 1, false, false)
        spr(51, target.x, target.y+(8 * n), 1, 1, false, false)
        spr(51, target.x, target.y-(8 * n), 1, 1, false, false)
      end
    end
  end

  return self
end


-- player units
make_redboy = function(x, y)
  local self = make_sprite(x, y, 1)

  self.pos = { x=0, y=3 }

  self.update = function(self)
    self.step += 1
    animate(self, 2, 4)
  end

  return self
end

make_greenboy = function(x, y)
  local self = make_sprite(x, y, 17)

  self.update = function(self)
    self.step += 1
    animate(self, 2, 4)
  end

  return self
end

make_pinkgirl = function(x, y)
  local self = make_sprite(x, y, 33)

  self.update = function(self)
    self.step += 1
    animate(self, 2, 4)
  end

  return self
end

-- enemy units
make_mushboy = function(x, y)
  local self = make_sprite(x, y, 6)

  self.update = function(self)
    self.step += 1
    animate(self, 2, 4)
  end

  return self
end

make_shyboy = function(x, y)
  local self = make_sprite(x, y, 22)

  self.update = function(self)
    self.step += 1
    animate(self, 2, 4)
  end

  return self
end

make_spookboy = function(x, y)
  local self = make_sprite(x, y, 38)

  self.update = function(self)
    self.step += 1
    animate(self, 2, 4)
  end

  return self
end

-- helpers
----

-- place object
function place(obj, makefn, x, y)
  if (mget(x,y) == obj) then
    actors[#actors+1] = makefn(x*8,y*8)
    mset(x,y, 11) -- empty grass
  end
end

-- pico
----

function _init()
  poke(0x5f2c, 3)

  -- music(0)
  for y=0,60 do
    for x=0,60 do

      -- players
      place(1, make_redboy, x, y)
      place(17, make_greenboy, x, y)
      place(33, make_pinkgirl, x, y)

      -- enemies
      place(6, make_mushboy, x, y)
      place(22, make_shyboy, x, y)
      place(38, make_spookboy, x, y)

    end
  end

  -- ui
  ui[#ui+1] = make_cursor(0, 0)
  ui[#ui+1] = make_toolbar(19, 56)
  ui[#ui+1] = make_moves()
end

function _update()
  for k, actor in pairs(actors) do
    actor:update()
  end

  for k, el in pairs(ui) do
    el:update()
  end
end

function _draw()
  cls(0)

  map(0, 0, 0, 0, 60, 60)

  for k, actor in pairs(actors) do
    actor:draw()
  end

  for k, el in pairs(ui) do
    el:draw()
  end

  print(debug, 1, 1, 7)
end

__gfx__
00000000088888000000000000000000008888800000000000444400000000000000000000044440000000003333333333333333333333333333333333333333
000000000888888008888800888880000088888800000000045555500044440000444400004555550004400033333333333333333333b33333333333333339a3
007007000ff5ff50088888808888880000ff5ff50854e0000448448004555550045555500044844805847000333333333333333b3663b333383338333a333333
000770000ff444400ff5ff50ff5ff50000ff444488f4e88d4444444404484480044844800444444445444ffd33333333333b333b3333336b3e333e3339339a33
000770000ffffee00ff44440ff44440000ffffee88f4f88d4444747444444444444444440444478745447ffd333333333b33333333b633333338333333333333
00700700022888000ffffee0ffffee00002288808854f8800fffff00444474744444747400fffff045844ff0333333333b333b3333333333333333e33393a333
000000000228880002288800228880000022888088fff2250fffff000fffff000fffff0000fffff045444ff53333333333333b33333336633333383333333393
0000000005505500055055002288800000550dd088fff22505505500055055000fffff0000550dd004444ff53333333333333333333333333333333333333333
000000000bbbbb00000000000000000000bbbbb00000000088888800000000000000000008888880000000003333333333333333000000000000000000000000
000000000bbbbbb00bbbbb00bbbbb00000bbbbbb000000008877770088888800888888000887777000000000444444433333333300c66cc00c66ccc00ccccc00
000000000ff5ff500bbbbbb0bbbbbb0000ff5ff50b50e000047577508877770088777700004757750050500049999994333333330cc66cc00c455cc00ccc5cc0
000000000fffff000ff5ff50ff5ff50000fffff0bbffebbd047777000475775004757750004777708777588d49999994444444430cc66cc00c444cc00c5555c0
000000000ffffee00fffff00fffff00000ffffeebbfffbbd087775500477770004777700008777558777788d49999494499999940c5555c00c455cc00c5555c0
00000000033bbb000ffffee0ffffee000033bbb0bb5ffbb0022888000877755008777550002288808757788049499444494999940cc55cc00c4444400ccc5cc0
00000000033bbb00033bbb0033bbb0000033bbb0bbfff3350228880002288800022888000022888087777225343444334444949400c55cc00c4444400ccccc00
00000000055055000550550033bbb00000550dd0bbfff33505505500055055000228880000550dd0884482253333333333334443000000000000000000000000
00000000099999000000000000000000009999900000000007777700000000000777770000777770000000003333333333333333099999999999999999999990
0000000099999990099999000999990009999999095080007777777007777700777777700777777707578770355555533333333399f66ff99f66fff99fffff99
0000000099f5ff509999999099999990099f5ff599ff8eed777577507777777077757750077757757777877d57766665333333339ff66ff99f455ff99fffdff9
000000009fffff0099f5ff5099f5ff5009fffff099fffeed777777707775775077777770077777777777777d56666665355555539ff66ff99f444ff99fddddf9
000000009ffff8809fffff009fffff0009ffff88995ffee0777778807777777077777880077777887757777056666665566667759f5555f99f455ff99fddddf9
00000000988eee009ffff8809ffff8800988eee099fff885766777707777788076677770076677777777766555666555575666659ff55ff99f4444499fffdff9
00000000988eee00988eee00988eee000988eee0999ff8857667777076677770766777700766777777777665335553333535555399f55ff99f4444499fffff99
000000000550550095505500988eee0000550dd009999990055055007557557055000dd000550dd0077777703333333333333333099999999999999999999990
000000007707707799099099cc0cc0cc88088088000000000000000000000000777777777777777799999999cccccccc888888880eeeeeeeeeeeeeeeeeeeeee0
000000007000000790000009c000000c800000080000000000000000000000007ccccc777000000790000009c000000c80000008eef66ffeef66fffeefffffee
00000000000000000000000000000000000000000000000000000000000000007c6ddd577000000790000009c000000c80000008eff66ffeef455ffeefffdffe
000000007000000790000009c000000c800000080000000000000000000000007cdddd577000000790000009c000000c80000008eff66ffeef444ffeefddddfe
000000007000000790000009c000000c800000080000000000000000000000007cdd56677000000790000009c000000c80000008ef5555feef455ffeefddddfe
00000000000000000000000000000000000000000000000000000000000000007c665cc77000000790000009c000000c80000008eff55ffeef44444eefffdffe
000000007000000790000009c000000c800000080000000000000000000000007c66cc777000000790000009c000000c80000008eef55ffeef44444eefffffee
000000007707707799099099cc0cc0cc88088088000000000000000000000000777777777777777799999999cccccccc888888880eeeeeeeeeeeeeeeeeeeeee0
__map__
0f0f0b0111210b2c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b0b0b0d0e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d1c1b0b0b2c0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b0b0d0b1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e1b0b0b0b2b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0b1c0c2c0b0f0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0616260b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000