pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- globals
ugc = 0.08 -- gravity constant
started = false
gameover = false
actors = {}
player = {}
boss = {}
bg = { x=0 }
score = 0
cam = { x=0, y=0 }
checkpoint = { x=0, y=0 }

-- actor methods
----

-- tile is ground
function ground(self)
  self.y = flr(self.y / 8) * 8
end

-- tile is ramp
function ramped(x, y)
  sprite = mget(flr(x)/8, (flr(y)/8) + 1)
  return fget(sprite, 1) -- ramp flag
end

-- tile is wall
function walled(x, y)
  sprite = mget(flr(x)/8, (flr(y)/8) + 1)
  return fget(sprite, 2) -- wall flag
end

-- tile is ground
function grounded(x, y)
  sprite = mget(flr(x+4)/8, (flr(y)/8) + 1)
  return fget(sprite, 0) -- ground flag
end

-- destroy
function destroy(self)
  del(actors, self)
end

-- collision
function touched(self, fn)
  if not player.die and player.x >= self.x - 4 and player.x < self.x + 8 and player.y >= self.y - 4 and player.y < self.y + 8 then
    fn()
  end
end

function killtouch(self)
  touched(self, function()
    if not player.falling then
      sfx(6)
      player.die = true
      player.dy = -2
    elseif player.falling then
      sfx(4)
      player.dy = -3
      destroy(self)
    end
  end)
end

-- movement
function movement(self)
  self.x += self.dx
  self.y += self.dy
  self.dx += self.ddx
  self.dy += self.ddy

  -- drag friction
  if self.ddx == 0 then
    self.dx *= 0.9
  end

  -- falling
  if not self.ghost and self.dy >= 0 and grounded(self.x, self.y) then
    self.falling = false
    self.dy = 0
    ground(self)
  else
    self.falling = true
  end

  -- ramps
  if self.dy > 0 and (ramped(self.x + 4, self.y - 4) or
    ramped(self.x - 4, self.y - 4)) then
      ground(self)
      self.y -= 4
      self.falling = false
  end

  -- walls
  if walled(self.x + 4, self.y - 4) or walled(self.x - 4, self.y - 4) then
      self.x = flr(self.x / 8) * 8
      self.dx = 0
  end

  -- gravity
  if self.falling and not self.flying then
    if flr(abs(self.dy)) == 0 then self.dy = 1 end
    self.dy += abs(ugc * self.dy)
  end

  -- max speed
  if self.dx > 3 then self.dx = 3 end
  if self.dx < -3 then self.dx = -3 end
  if self.dy > 4 then self.dy = 4 end
  if self.dy < -4 then self.dy = -4 end

  -- bounds
  if self.x < 40 then
    self.x = 40
    self.dx = 0
  end

  if self.x > 504 then
    self.x = 504
    self.dx = 0
  end

  -- reset
  self.ddx = 0
end


-- player methods
----

-- death
function died(self, frm)
  if self.die then
    self.frame = frm
    self.cframe = 0
    self.y += self.dy

    if flr(abs(self.dy)) == 0 then self.dy = 1 end
    self.dy += abs(ugc * self.dy)

    if self.y > (cam.y + 200) then
      self.die = false
      self.x = checkpoint.x
      self.y = checkpoint.y
      cam.x = checkpoint.x 
      cam.y = checkpoint.y - 30
      self.dx = 0
      self.dy = 0
      boss.hp = 5 -- reset boss hp
    end
  end
end

-- update camera
function move_camera(sprite)
  cam.x = sprite.x - 28 -- x center

  cam.x += 20 * (sprite.dx / 12)
  cam.y = sprite.y - 28

  camera(cam.x, cam.y)
end

-- can jump
function canjump(self)
  return self.falling == false
end

-- player input
function controls(self)
  if btn(0) then -- left
    self.forward = false
    self.ddx -= 0.25
  end

  if btn(1) then -- right
    self.forward = true
    self.ddx += 0.25
  end

  if (btnp(2) or btnp(4) or btnp(5)) and canjump(self) then -- jump
    sfx(3)
    self.dy = -3
    self.falling = true
  end
end

-- boss / crab / bee input
function patrol_ai(self)
  if self.x >= self.xmax then
    self.forward = true
    self.speed *= -1
  end

  if self.x <= self.xmin then
    self.forward = false
    self.speed *= -1
  end

  self.dx = self.speed
end

-- fish input
function jump_ai(self)
  if self.y >= self.ystart then
    self.ddy = self.speed
  else
    self.ddy = 0
  end
end

-- animation methods
----

-- spin animation
function spinning(self)
  if abs(self.dx) > 2.5 and not self.spinning then
    self.spinning = true
    self.frame = 67
  elseif abs(self.dx) < 2.5 then
    self.spinning = false
    self.frame = 64
  end

  if self.cframe > 2 and self.spinning then
    self.cframe = 0
  end
end

-- animations
----

-- player
function animate(self)
  if self.cframe > 1 and not self.spinning then
    self.cframe = 0
  end

  if self.step % 2 == 0 and self.ddx != 0 then
    self.cframe = self.cframe + 1
  end
end

-- obj
function oanimate(self, frames, speed)
  if self.step % speed == 0 then
    self.cframe = (self.cframe + 1) % frames
  end
end

-- actors
----

-- sprite
sprite = {}
make_sprite = function(x, y, frame)
  local self = {}
  self.id = #actors
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
  self.falling = false

  -- update
  self.update = function(self)
  end

  -- draw
  self.draw = function(self)
    local frame = self.cframe + self.frame
    spr(frame, self.x, self.y, 1, 1, not self.forward, false)
  end

  return self
end

-- ring
make_ring = function(x, y)
  local self = make_sprite(x, y, 73)

  self.update = function(self)
    self.step += 1
    oanimate(self, 4, 4)
    touched(self, function()
      sfx(2)
      score += 1
      destroy(self)
    end)
  end

  return self
end

-- spring
make_spring = function(x, y)
  local self = make_sprite(x, y, 89)

  self.update = function(self)
    self.step += 1
    oanimate(self, 4, 3)
    touched(self, function()
      sfx(5)
      player.dy = -5
    end)
  end

  return self
end

-- spikes
make_spikes = function(x, y)
  local self = make_sprite(x, y, 71)

  self.update = function(self)
    self.step += 1
    oanimate(self, 2, 8)

    touched(self, function()
      if not player.die then
        sfx(6)
        player.die = true
        player.dy = -2
      end
    end)
  end

  return self
end

-- tulip
make_tulip = function(x, y)
  local self = make_sprite(x, y, 98)

  self.update = function(self)
    self.step += 1
    oanimate(self, 2, 8)
  end

  return self
end

-- sunflower
make_sunflower = function(x, y)
  local self = make_sprite(x, y, 100)

  self.update = function(self)
    self.step += 1
    oanimate(self, 2, 8)
  end

  return self
end

-- flag / checkpoint
make_flag = function(x, y)
  local self = make_sprite(x, y, 112)
  self.touched = false

  self.update = function(self)
    self.step += 1

    if self.touched then
      oanimate(self, 6, 1)
    end

    touched(self, function()
      if not self.touched then
        sfx(7)
      end
      self.touched = true
      checkpoint.x = self.x
      checkpoint.y = self.y
    end)
  end

  return self
end

-- player
make_player = function(x, y)
  local self = make_sprite(x, y, 64)

  -- state
  self.spinning = false
  self.ramping = false

  -- update
  self.update = function(self)
    self.step += 1
    died(self, 66)

    if self.die then
      return
    end

    if gameover then
      self.frame = 64
      self.cframe = 0
    end

    if not self.die and self.y > 220 then -- glitched thru level
      sfx(6)
      self.die = true
    end

    if not gameover then
      controls(self)
    end

    -- animation
    spinning(self)
    animate(self)

    movement(self)

    move_camera(self)
  end

  return self
end

-- crab
make_crab = function(x, y)
  local self = make_sprite(x, y, 80)

  -- state
  self.xmin = x - 20
  self.xmax = x + 20
  self.speed = 0.75
  self.forward = false

  -- update
  self.update = function(self)
    self.step += 1

    patrol_ai(self)
    killtouch(self)
    oanimate(self, 2, 8)
    movement(self)
  end

  return self
end

-- bee
make_bee = function(x, y)
  local self = make_sprite(x, y, 96)

  -- state
  self.xmin = x - 30
  self.xmax = x + 30
  self.speed = 0.75
  self.forward = false
  self.flying = true

  -- update
  self.update = function(self)
    self.step += 1

    killtouch(self)
    patrol_ai(self)
    oanimate(self, 2, 8)
    movement(self)
  end

  return self
end

-- fish
make_fish = function(x, y)
  local self = make_sprite(x, y, 82)

  -- state
  self.ystart = y
  self.speed = -2.5
  self.forward = false
  self.ghost = true

  -- update
  self.update = function(self)
    self.step += 1

    killtouch(self)
    jump_ai(self)
    oanimate(self, 2, 8)
    movement(self)
  end

  return self
end

-- boss
make_boss = function(x, y)
  local self = make_sprite(x, y, 77)

  -- state
  self.xmin = x 
  self.xmax = x + 60
  self.speed = -1
  self.forward = false
  self.flying = true
  self.hp = 10

  -- update
  self.update = function(self)
    self.step += 1

    touched(self, function()
      if player.falling then
        sfx(0)
        self.hp -= 1
        player.dy = -2
        if self.hp < 0 then
          destroy(self)
          gameover = true
        end
      end
    end)

    patrol_ai(self)
    oanimate(self, 2, 8)
    movement(self)
  end

  return self
end

-- boss ship
make_ship = function(x, y)
  local self = make_sprite(x, y, 93)

  -- state
  self.xmin = x
  self.xmax = x + 60
  self.speed = -1
  self.forward = false
  self.flying = true

  -- update
  self.update = function(self)
    self.step += 1

    touched(self, function()
      sfx(6)
      player.die = true
    end)

    if gameover then
      destroy(self)
    end

    patrol_ai(self)
    oanimate(self, 2, 8)
    movement(self)
  end

  return self
end


-- place object helper
function place(obj, makefn, x, y)
  if (mget(x,y) == obj) then
    actors[#actors+1] = makefn(x*8,y*8)
    mset(x,y, 16) -- empty sky
  end
end

function _init()
  poke(0x5f2c, 3)

  palt(12, true) -- beige color as transparency is true
  palt(0, false) -- black color as transparency is false

  music(0)
  actors[#actors+1] = {}

  for y=0,100 do
    for x=0,300 do

      -- player
      place(64, function(x, y)
        player = make_player(x, y)
        actors[#actors] = player -- put in global state
      end, x, y)

      place(77, function(x, y)
        boss = make_boss(x, y)
        actors[#actors] = boss -- put in global state
      end, x, y)

      place(80, make_crab, x, y)
      place(71, make_spikes, x, y)
      place(73, make_ring, x, y)
      place(82, make_fish, x, y)
      place(96, make_bee, x, y)
      place(89, make_spring, x, y)
      place(93, make_ship, x, y)
      place(98, make_tulip, x, y)
      place(100, make_sunflower, x, y)
      place(112, make_flag, x, y)
    end
  end

  cam.x = player.x
  cam.y = player.y
  checkpoint.x = player.x
  checkpoint.y = player.y
end

function _update()
  -- if gameover then return end
  if not started then
    bg.x = (bg.x + 1) % 64

    if btnp(4) or btnp(5) then -- jump
      started = true
    end
    return
  end

  for k, actor in pairs(actors) do
    actor:update()
  end
end

function _draw()
  cls(12)

  if not started then
    spr(136, bg.x, 0, 8, 8, false, false)
    spr(136, bg.x-64, 0, 8, 8, false, false)
    spr(128, 0, 0, 8, 8, false, false)
    print("press \151 start", 5, 55, 7)
    return
  end

  map(0, 0, 0, 0, 128, 64)

  for k, actor in pairs(actors) do
    actor:draw()
  end

  -- print(debug, cam.x + 1, cam.y+1, 7)
  print("\142", cam.x + 1, cam.y+1, 10)
  print(score, cam.x + 10, cam.y+1, 7)

  if gameover then
    print("gameover", cam.x + 18, cam.y+9, 7)
    print("you  win", cam.x + 18, cam.y+18, 7)
  end
end

__gfx__
ccccccccccccccc999999999999999999cccccccccccccccccccccc00cccccccccccccccc0000000000000000000000cc0000000000000000000000c94222222
ccccccccccccc9999222222222222229999ccccccccccccccccccc0bb0cccccccccccccc00bb33bb33bb33bb33bb330000bb33bb33bb33bb33bb330094499449
cc7cc7cccccc99222b33bb3333bb33b22299ccccccccccccccccc0bbbb0ccccccccccccc03bb33bb33bb33bb33bb33b003bb33bb33bb33bb33bb33b094499449
ccc77cccccc99233bb33bb3333bb33bb33299ccccccccccccccc03bbbb30cccccccccccc03bb33bb33bb33bb33bb33b003bb33bb33bb33bb33bb33b094499449
ccc77ccccc992b33bb33bb3333bb33bb33b299ccccccccccccc033b22b330ccccccccccc03bb33bb33bb33bb33bb33b003bb33bb33bb33bb33bb33b094499449
cc7cc7cccc92bb33bb300000000003bb33bb29cccccccccccc0b33299233b0cccccccccc05222222222222222222225005222222222222222222225094499449
ccccccccc992bb33bb0cccccccccc0bb33bb299cccccccccc0bb32499423bb0ccccccccc02499449944994499449942002554444555544445555442094499449
ccccccccc923bb33b0cccccccccccc0b33bb329ccccccccc03bb24499442bb30cccccccc02499449944994499449942002554444555544445555442094499449
cccccccc9233bb330cccccccccccccc033bb33290000000033b2944994492b330000000002499449944994499449942002445555444455554444552022222249
cccccccc9233bb30cccccccccccccccc03bb332933bb33bb3329944994499233bb33bb3302499449944994499449942002445555444455554444552094499449
cccccccc9233bb30cccccccccccccccc03bb332933bb33bb3249944994499423bb33bb3302499449944994499449942002445555444455554444552094499449
cccccccc9233bb30cccccccccccccccc03bb332933bb33bb2449944994499442bb33bb3302499449944994499449942002445555444455554444552094499449
cccccccc9233bb30cccccccccccccccc03bb332933bb33b294499449944994492b33bb3302499449944994499449942002554444555544445555442094499449
cccccccc9233bb30cccccccccccccccc03bb33292222222994499449944994499222222202499449944994499449942002554444555544445555442094499449
cccccccc9233bb30cccccccccccccccc03bb33299449944994499449944994499449944902499449944994499449942002554444555544445555442094499449
cccccccc9233bb30cccccccccccccccc03bb33299449944994499449944994499449944902499449944994499449942002554444555544445555442094499449
444455559923bb330cccccccccccccc033bb3249000cccccccccccccccccccccccccc000c0222222222222222222220cc0222222222222222222220ccc000000
444455559923bb330cccccccccccccc033bb32490230cccccccccccccccccccccccc0320cc00000000000000000000cccc00000000000000000000cc00bb33bb
444455559942bb33b00cccccccccc00b33bb24490230cccccccccccccccccccccccc0320cccccccccccccccccccccccccccccccccccccccccccccccc33bb33bb
4444555599442b33bb30cccccccc03bb33b2944902300cccccccccccccccccccccc00320cccccccccccccccccccccccccccccccccccccccccccccccc33bb33bb
5555444499449223bb330000000033bb322994490233b0cccccccccccccccccccc0b3320cccccccccccccccccccccccccccccccccccccccccccccccc33bb33bb
5555444499449942bb33bbbb00bb33bb244994490233b0cccccccccccccccccccc0b3320cccccccccccccccccccccccccccccccccccccccccccccccc33222222
55554444994499442b33bb0033bb33b2944994490233bb00cccccccccccccccc00bb3320cccccccccccccccccccccccccccccccccccccccccccccccc22499449
5555444499449944922200bb33bb3329944994490223bb330cccccccccccccc033bb3220cccccccccccccccccccccccccccccccccccccccccccccccc94499449
4444444400000000000033bb33bb3229944994490242bb33b00000000000000b33bb2420000c0000c000000ccccccccc0000c000000000cccccccccccccccccc
4444444433bb33bb33bb33bb33b22449944994490242bb33bb33bb3333bb33bb33bb242033b0499400999900c000000c49940b33bb33bb00cccccccccccccccc
4444444433bb33bb33bb33bb22299449944994490242bb33bb33bb3333bb33bb33bb242033bb499494944949009999004994bb33bb33bb3300cccccccccccc00
4444444433bb33bb33bb3222944994499449944902492b33bb33bb3333bb33bb33b2942033bb499494944949949449494994bb33bb33bb33bb00cccccccc00bb
4444444433bb33bb33b22449944994499449944902499223bb33bb3333bb33bb3229942033bb499424999942949449494994bb33bb33bb33bb330000000033bb
44444444222222222229944994499449944994490249944222222222222222222449942022224444c522225c249999424444222222222233bb33bb3333bb33bb
44444444944994499449944994499449944994490249944994499449944994499449942094492220ccccccccc522225c0222944994499422bb33bb3333bb33bb
44444444944994499449944994499449944994490249944994499449944994499449942094499420cccccccccccccccc02499449944994492233bb3333bb3322
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
dddddddcdddddddcccccccccccccccccccccccdccccccccccccccccccc7ccc7ccc7ccc7cccffffcccccffccccccffccccccffcccccfffccccccfffcccccccccc
cddd70ddcddd70dddddddddcddddddccccdddddccc8888ccccddddccc67cc67cc67ccc7cc9a999fccc9a9fcccccaacccccf9a9cccc8f8cccccc8f8cccccccccc
cddd70ddcddd70ddcddd70ddcddd70dcc8f66ddccdffffdccd00df8cc67cc67cc67cc67cc9acc9fccc9a9fcccccaacccccf9a9cc4455544cc4455544cccccccc
c66dffffcd66ffffcd6670ddcd6670dcc8f66ddccddd66dccd77df8c5d655d655d655d65c9acc9fccc9a9fcccccaacccccf9a9cc9444449ff9444449cccccccc
c66d111ccd66111ccd66ffffcd66dddcc8fd77dccd0766dccdd66f8c2222222222222222c9aaaafccc9aafcccccaacccccfaa9cc9888889ff9888889cccccccc
ddd1111cddd1111cddd1111ccdffffdcc8fd00dccd07dddccdd66f8c4444444444444444cc9999ccccc99cccccc99cccccc99ccc8888888cc8888888cccccccc
cc8cc8cccc8c8cccddd8118ccc8888ccccddddccccddddddcdddddcc4444444444444444ccccccccccccccccccccccccccccccccddddddddddddddddcccccccc
e8cccce8ccccccccccddcc11ccdddd1cc555ccccc555ccccccbbbbccccc8f8ccccc8f8ccccccccccccccccccaaaaaaa6cccccccc5d2222d55d2222d5cccccccc
e8cccce8e8cccce8cddddc11cddddd115075333c5075333ccbb33bbcc9444449c9444449ccccccccccccccccfffffff6cccccccc5d8ee8d55de88ed5cccccccc
e87c77e8e87c77e8cdd00d11cdd00d115075333350753333b533335b8888888888888888ccccccccaaaaaaa699999999aaaaaaa65588885555eeee55cccccccc
8c0c07c88c0c07c8cdd77d11cdd77d11555533335555333355349355ddddddddddddddddccccccccfffffff6cddddddcfffffff65555555555555555cccccccc
8c0808c88c0808c8c66ddd1cc66ddd1c65333bbb65333bbbc3b44b3c55d2222d55d2222daaaaaaa699999999c666666c99999999c555555cc555555ccccccccc
8888888888888888cc66dddccc66dddc6333bbbb6333bbbb33bbbb3355d8ee8d55de88edfffffff6cddddddcc666666ccddddddcccddd6ccccddd6cccccccccc
cceee2cccceee2cccccc6ddccccc6ddcc5555555c5555555b49bb49b55588885555eeee599999999c666666cc666666cc666666cccd556ccccd556cccccccccc
cc5cc5ccccc55cccccc6ddddccc6ddddccdcdcdccdcdcdcdc443344cc555555cc555555ccddddddcc666666cc666666cc666666cccdcc6ccccdcc6cccccccccc
c999c777c999c666ccccccccccccccccccaaaccccccccccccc4994cccccccccccccccccccccc8888888fccccccccccccccccccccc5555ccccc5555ccccc5555c
9079966690799dddccccccccccccccccca999acccccaaacccc4994ccccfffccccccfffcccccceeeeeeefcccccccccccccccccccccddddcccccddddcccccddddc
907999dd90799966cceeeccccccccccca94449accca999accc4944cccc8f8cccccc8f8cccccc22222222cccccccccccccccccccc5566ddccc5566ddccc5566dd
aaa999ccaaa99966cc8efccccceeeccca94449acca94449acc4994cc4455544cc4455544cccccddddddccccccccc8888888fcccc56cc6dccc56cc6dccc56cc6d
ccc99477ccc994ddcc8efccccc8efcccca999accca94449acc4994cc9444449ff9444449ccccc666667ccccccccceeeeeeefcccc56cc6dccc56cc6dccc56cc6d
cc994466cc9944cccc888ccccc8efcccccaaaccccca999accc4944cc9888889ff9888889cccc66666667cccccccc22222222cccc5566ddccc5566ddccc5566dd
c9944dddc9944cccccc3cccccc888cccccc33ccccccaaacccc4994cc8888888cc8888888cc666666666676cccccccddddddcccccc5555ccccc5555ccccc5555c
6dddcccc6dddcccccccbccccccc3cccccccbbcccccc33ccccc4994ccddddddddddddddddc66666666666666cccccc666667cccccc6666ccccc6666ccccc6666c
66666666c666666cccdd66ccccc66cccccd666ccc666666cdddddddd5d2222d55d2222d56666666666666666c66666666666666cc555555cc555555ccccccccc
d7777776cd77776cccdd76ccccc66cccccd766cccd77776cdddddddd5d8ee8d55de88ed5666666666666666666666666666666669888999849994449cccccccc
d7eeee76cd7ee76cccdde6ccccc66cccccde66cccd7ee76cdddddddd5588885555eeee552d55d222222d55d266666666666666669888999849994449cccccccc
d7888876cd78876cccdd86ccccc66cccccd866cccd78876cdddddddd55555555555555558d55d8eeee8d55d8cc55d222222d55cc8999888994449994cccccccc
d7777776cd77776cccdd76ccccc66cccccd766cccd77776cddddddddc555555cc555555c8555588888855558cc55d8eeee8d55cc8999888994449994cccccccc
ddddddddcddddddcccddddcccccddcccccddddcccddddddcddddddddccddd6ccccddd6cc5555555555555555c55558888885555c8999888994449994cccccccc
ccc55cccccc55cccccc55cccccc55cccccc55cccccc55cccddddddddccd556ccccd556cc55dd55555555dd5555555555555555559888999849994449cccccccc
ccc55cccccc55cccccc55cccccc55cccccc55cccccc55cccddddddddccdcc6ccccdcc6ccdddddddddddddddd55dddddddddddd55c888999cc999444ccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccc999999999999999ccddccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccc999999999999999999dddccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccc9999999999999999dddddddccccccccccccccccccccccccccc777ccccccccccccccccccccccccccccccccccccccc7777ccccccccccc
ccccccccccccccccccccc9999999999999ddddddd7ddcccccccccccccccccccccccccc777777777ccccccccccccccccccccccccccccc777777777ccccccccccc
ccccccccccccccccccc9999999999999ddddddd777dd9ccccccccccccccccccccccc77777777777cccccccccccccccccccccccccccc77777777777cccccccccc
ccccccccccccccccccc9999999999999dddddd7777dd9cccccccccccccccccccccc777777777777ccccccccccccccccccccccccccc777777777777cccccccccc
cccccccccccccccccc999999999999ddddddd777769999cccccccccccccccccccc777777777777ccccccccccccccccccccccccccccc7777777777ccccccccccc
cccccccccccccccccc99dddddd9dddddddddd777699999cccccccccccccccccccc77777777777ccccccccccccccccccccccccccccccc77777ccccccccccccccc
cccccccccccccccc99ddddddddddddddddddd777699999cccccccccccccccccccc7777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc99777ddddddddddddddddd7699999999ccccccccccccccccccccc77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc99d777dddddddddddddddd6d99999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc999776ddddddddddddddddddd9999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc999d66dddddddddd777ddddddd999999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc9999ddddddddddd777777ddddd977999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc999999dd77dddd7700777ddddd977999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc99999dd77700dd7700777ffddd977999cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc99999dd77700777700777fffdd977779cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc99999dd7770077777ffffffffd977777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc99999ddd77770000fff000ffff977777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc2cccc
cccccccccccccccc99999dddddf00000ffff0fffff977777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc22cccc
cccccccccccccccc99999dddddf00ffffff0fffff9977777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc222cccc
cccccccccccccccc999999ddfffffffff00fffff99777777ccccccccccccccccccccccc2ccccccccccccccccccccccccccccccccccccccccccccccccc2222ccc
cccccccccccccccc999999dffffffff00ffffff999767777ccccccccccccccccccccc222ccccccccccccc22cccccc222ccccccccccccc222ccccccccc2222ccc
ccccccccccccccccc999999ffff0000fffffff999966679ccccccccccccccccccccc22222cc22ccccccc222ccccc22222cc22ccccccc22222cc22ccc2222222c
ccccccccccccccccc9999999fffffffffddddd9999f6699cccccccccccccccccccc222222c2222ccccc22222ccc222222c2222ccccc222222c2222cc2222222c
ccccccccccccccccc9999999ddddddddddddddd99fff699ccccccccccccccccccc22222222222222cc222222cc22222222222222cc2222222222222222222222
cccccccccccccccccc999999ddddddddddddddfffff999cccccccccccccccccc2222222222222222222222222222222222222222222222222222222222222222
cccccccccccccccccccc9999ffddddddd66dddffff99cccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccc9999ffdddd666666ddfff999cccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccc99ffddd6666666ddff999ccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
ccccccccccccccccc888888888888888888888888888888ccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccc88888888888888888888888888888888cccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccc88887778888888888888888887778888cccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccc88887788877787878877787887788888cccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
ccccccccccccc88888887778878787878878787887788888888ccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccc8888888887788787887888787878877888888888cccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccc8888888887788777887888787878877888888888cccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccc8888888877788888888888888888877788888888cccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccc8888888888888888888888888888888888888888cccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccc8888888888888888888888888888888888888888cccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccc88888cccccccccccccccccccccccccccccc88888cccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccc88888cccccccccccccccccccccccccccccc88888cccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccc88888cccccccccccccccccccccccccccccc88888cccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccc8888cccccccccccccccccccccccccccccccc8888cccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111111111111111111111
__label__
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaa66cccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaaaaaaaaaa66cccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccffffffffffffff66cccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccffffffffffffff66cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9999999999999999cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9999999999999999cccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccddddddddddddcccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccddddddddddddcccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc666666666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc666666666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc666666666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc666666666666cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc0000bbbb3333bbbb3333bbbb33330000cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc0000bbbb3333bbbb3333bbbb33330000cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc0033bbbb3333bbbb3333bbbb3333bb00cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc0033bbbb3333bbbb3333bbbb3333bb00cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc0033bbbb3333bbbb3333bbbb3333bb00cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc0033bbbb3333bbbb3333bbbb3333bb00cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc0033bbbb3333bbbb3333bbbb3333bb00cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc0033bbbb3333bbbb3333bbbb3333bb00cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00552222222222222222222222225500cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00552222222222222222222222225500cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00224444555555554444444455552200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00224444555555554444444455552200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccffffffffccccccccccffffcccccc00224444555555554444444455552200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccffffffffccccccccccffffcccccc00224444555555554444444455552200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc99aa999999ffcccccc99aa99ffcccc00224444555555554444444455552200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc99aa999999ffcccccc99aa99ffcccc00224444555555554444444455552200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc99aacccc99ffcccccc99aa99ffcccc00224444555555554444444455552200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc99aacccc99ffcccccc99aa99ffcccc00224444555555554444444455552200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc99aacccc99ffcccccc99aa99ffcccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc99aacccc99ffcccccc99aa99ffcccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc99aaaaaaaaffcccccc99aaaaffcccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc99aaaaaaaaffcccccc99aaaaffcccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc99999999cccccccccc9999cccccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccc99999999cccccccccc9999cccccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc00225555444444445555555544442200cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc0000000000000000000000000000cc00224444555555554444444455552200ccccbbbbbbbbcccccccccccccccccccccccccccccccccccccccccc
cccccccccccc0000000000000000000000000000cc00224444555555554444444455552200ccccbbbbbbbbcccccccccccccccccccccccccccccccccccccccccc
cccccccccc0000bbbb3333bbbb3333bbbb3333000000224444555555554444444455552200ccbbbb3333bbbbcccccccccccccccccccccccccccccccccccccccc
cccccccccc0000bbbb3333bbbb3333bbbb3333000000224444555555554444444455552200ccbbbb3333bbbbcccccccccccccccccccccccccccccccccccccccc
cccccccccc0033bbbb3333bbbb3333bbbb3333bb0000224444555555554444444455552200bb553333333355bbcccccccccccccccccccccccccccccccccccccc
cccccccccc0033bbbb3333bbbb3333bbbb3333bb0000224444555555554444444455552200bb553333333355bbcccccccccccccccccccccccccccccccccccccc
cccccccccc0033bbbb3333bbbb3333bbbb3333bb00002244445555555544444444555522005555334499335555cccccccccccccccccccccccccccccccccccccc
cccccccccc0033bbbb3333bbbb3333bbbb3333bb00002244445555555544444444555522005555334499335555cccccccccccccccccccccccccccccccccccccc
cccccccccc0033bbbb3333bbbb3333bbbb3333bb0000225555444444445555555544442200cc33bb4444bb33cccccccccccccccccccccccccccccccccccccccc
cccccccccc0033bbbb3333bbbb3333bbbb3333bb0000225555444444445555555544442200cc33bb4444bb33cccccccccccccccccccccccccccccccccccccccc
cccccccccc00552222222222222222222222225500002255554444444455555555444422003333bbbbbbbb3333cccccccccccccccccccccccccccccccccccc00
cccccccccc00552222222222222222222222225500002255554444444455555555444422003333bbbbbbbb3333cccccccccccccccccccccccccccccccccccc00
cccccccccc0022555544444444555555554444220000225555444444445555555544442200bb4499bbbb4499bbcccccccccccccccccccccccccccccccccc00bb
cccccccccc0022555544444444555555554444220000225555444444445555555544442200bb4499bbbb4499bbcccccccccccccccccccccccccccccccccc00bb
cccccccccc0022555544444444555555554444220000225555444444445555555544442200cc444433334444cccccccccccccccccccccccccccccccccc0033bb
cccccccccc0022555544444444555555554444220000225555444444445555555544442200cc444433334444cccccccccccccccccccccccccccccccccc0033bb
dd6666cccc0022444455555555444444445555220000224444555555554444444455552200cccc44999944cccccccccccccccccccccccccccccccccc003333bb
dd6666cccc0022444455555555444444445555220000224444555555554444444455552200cccc44999944cccccccccccccccccccccccccccccccccc003333bb
dd7766cccc0022444455555555444444445555220000224444555555554444ddddddddddddddcc44999944cccccccccccccccccccccccccccccccc00bb333322
dd7766cccc0022444455555555444444445555220000224444555555554444ddddddddddddddcc44999944cccccccccccccccccccccccccccccccc00bb333322
ddee66cccc002244445555555544444444555522000022444455555555444444dddddd7700dddd44994444cccccccceeeeeecccccccccccccccc00bbbb332244
ddee66cccc002244445555555544444444555522000022444455555555444444dddddd7700dddd44994444cccccccceeeeeecccccccccccccccc00bbbb332244
dd8866cccc002244445555555544444444555522000022444455555555444444dddddd7700dddd44999944cccccccc88eeffcccccccccccccc0033bbbb224444
dd8866cccc002244445555555544444444555522000022444455555555444444dddddd7700dddd44999944cccccccc88eeffcccccccccccccc0033bbbb224444
dd7766cccc002255554444444455555555444422000022555544444444555555dd6666ffffffff44999944cccccccc88eeffcccccccccccc003333bb22994444
dd7766cccc002255554444444455555555444422000022555544444444555555dd6666ffffffff44999944cccccccc88eeffcccccccccccc003333bb22994444
ddddddcccc002255554444444455555555444422000022555544444444555555dd6666111111cc44994444cccccccc888888cccccccccc00bb33332299994444
ddddddcccc002255554444444455555555444422000022555544444444555555dd6666111111cc44994444cccccccc888888cccccccccc00bb33332299994444
5555cccccc0022555544444444555555554444220000225555444444445555dddddd11111111cc44999944cccccccccc33cccccccccc00bbbb33224499994444
5555cccccc0022555544444444555555554444220000225555444444445555dddddd11111111cc44999944cccccccccc33cccccccccc00bbbb33224499994444
5555cccccc0022555544444444555555554444220000225555444444445555555588448800cccc44999944ccccccccccbbcccccccc0033bbbb22444499994444
5555cccccc0022555544444444555555554444220000225555444444445555555588448800cccc44999944ccccccccccbbcccccccc0033bbbb22444499994444
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003333bb2299444499994444
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003333bb2299444499994444
bb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333229999444499994444
bb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333229999444499994444
bb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3322449999444499994444
bb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3322449999444499994444
bb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb2244449999444499994444
bb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb2244449999444499994444
bb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bb229944449999444499994444
bb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bbbb3333bb229944449999444499994444
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222999944449999444499994444
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
99994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444999944449999444499994444
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
0000000000000303000101010101010000000000000102020104000400000000000001010001000001000000000000010001010000000101000101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1d1d1d1d1e10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010272829272829272829273738393738
1d1d1d1d1e1010101010101010101010101010101010101010101010101010101010101010101010101010101010060b101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010373839373839373839373839373839
1d1d1d1d1e1010101010101010101010101010101010101010101010101010101010101010101010101010101006161b1010104d1010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010060710101010101010101010101010101010101010101010101006161a1b1010105d1010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e101010101010101010051005061617180708101010101010101010101010561010101010101006161a1a1b101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e101010101010106462494906161a1a1a17070810105062641010494910106670101010621006161a1a1a1b101010101010101010626410101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e101010101010090a0a0a15161a1a1a1a1a17180a0a0a0a0a393a3b3b3a3c0a0a0b4747090a161a1a1a1a1b474747090a0a0a0a0a0a0a0b474747471c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e101010101010292a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2b10101010292a2a2b2d2d191a1a1a1a1a1a1b303030191a1a1a1a1a1a1a1b303030301c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e1010101010101010101010101010101010101010101010101010105210101010101010292a2a2a2a2a2a2b2a2a2a292a2a2a2a2a2a2a2b2a2a2d2d1c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010591010101010104949491010105610101010101010101010101010101010101010101010101010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e1010100c0e1010101010060a0a0a0710646610101010101010101049494910101010101010101010101010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e1049491c1e1010101006161a1a1a170a0a0a393a3b3b3b3b3a3c0a0a0a0a0a071010101010101010101010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e100c0e1c1e56101006161a1a1a1a1a1a1a1a1b101010101010191a1a1a1a1a170710101010101010101010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e701c1e1c1e666206161a1a1a1a1a1a1a1a1a1b105210105210191a1a1a1a1a1a1707106462104949491010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e090a0a0a0a0a15161a1a1a1a1a1a1a1a1a1a1b101010101010191a1a1a1a1a1a1a170a0a0a0a0a0a0a0b10101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e191a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1b101010101010191a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1b10101010101060101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e292a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2b101010101010292a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2b10100c0d0e1010100c0d0e1010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101c1d1e1010101c1d1e1010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101010101010101010101010101010101010101010101010101010101010102c2d2e1010102c2d2e1010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010105610101010101010101010561c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101010101010101010101010101010101010101010101049494910626410501010106670101010101010591064661c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101008051010101010101010101010101010101010100c0d0d0d0d0d0d0d0d0d0d0d0d0d0d0d0e10100c0d0d0d0e1c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101010101010101010101010101010101010101010101c1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1e10101c1d1d1d1e1c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101010101010101010101010494949491010101010641c1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1e10101c1d1d1d1e1c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e1056101010101010101010101010101010101010101005060a0a0a0a0a0a07081010090a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a1c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e6266401010101010626410494949101010641010620506161a1a1a1a1a1a170b4747191a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e090a0a393a3a3b3c0a0a0a0a0a0b4747090a0a0a0a15161a1a1a1a1a1a1a1a1b3030191a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e191a1a1b101010191a1a1a1a1a1b3030191a1a1a1a1a1a1a1a1a1a1a1a1a1a1b3030191a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e292a2a2b101010292a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2a2b1010101010101010101010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
1d1d1d1d1e10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101c1d1d10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
__sfx__
000300000d6502c65011650116500b65022600206002060020600216000660005600036000360003600026000260001600016000160003600026000260001600016000260002600016000160002600176001e600
000100000c5600c5600d5500d5400d5400d5500d5400855008550085500855008550085500855008550085503770037700396003f500246000b6000d6000e600144003430025300223002d700000000000000000
00010000225502255022550225502e5502e5502e5502e5502e5002e5000d5000a50009500085000e500085000f5000f5000750010500075001550015500115000750007500075000650006500065000550005500
000100001775017750187501a7501c7501e750207502175022750227502275022750227502175021750207501f7501d7501a7501775013750107000f70003700017000a700087000770006700047000270002700
00010000000002505022050200501d0501a050180501405012050100500f0500d0500c0500c0500d0500e05010050110501305015050180501a0501c0501f0502105024050250500000000000000000000000000
0101000001050010500205003050060500a0500c0500f0501205014050150500c0500a0500705004050010500305006050090500c0500e0501105015050180501b0501d0501f050220501f0501a0501705011050
00010000217501f7501d7501b7501975017750167501575014750147501375021750207501e7501f7501d7501b7501a75018750177501675015750157500b7500b7500a7500a7500b7500c7500c7500a7500a750
000100002555025550255502455036550365503655036550365503555029550295502955029550285502855028550285502855028550345503455034550345503455034550345503455034500325001950018500
011000000c0532500327003250030c053270030c0530c05325003240030c0530c053270030c0530c053250030c0532500327003250030c053270030c0530c05325003240030c0530c053270030c0530c05325003
011000001b0500e0000c0000c0000c0002205012050140501b0500c0000c0000c0000c0001905012050140501b0500e0000c0000c0000c0002205012050140501b0500c0000c0000c0000c000220501205014050
0110000016755207552275516755207552275512755147551b755197550f7550d755127551b755197550f75516755207552275516755207552275512755147551b755197550f7550d755127551b755197550f755
011000000010516155201552215516155201052210512105141051b155191550f1550d155121051b105191050f10516155201552215516155201052210512105141051b155191550f1550d155121051b10519105
__music__
00 08494a4b
01 0849430b
00 0809430b
00 08090a0b
00 08090a0b
02 08090a0b

