pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

make_player = function(x, y)
  local self = {}
  self.x = x or 0
  self.y = y or 0
  self.xpos = x / 8 or 0
  self.ypos = y / 8 or 0
  self.frame = 3
  self.sframe = 0
  self.flipx = false
  self.step = 0

  self.update = player_update
  self.draw = player_draw

  return self
end

player_update = function(self)
  self.step += 1

  if btnp(0) then -- left
    if (self.xpos - 1) >= 0 then
      self.flipx = true
      self.xpos -= 1
    end
  end

  if btnp(1) then -- right
    if (self.xpos + 1) <= 7 then
      self.flipx = false
      self.xpos += 1
    end
  end

  if btnp(2) then -- up
    if (self.ypos - 1) >= 0 then
      self.ypos -= 1
    end
  end

  if btnp(3) then -- down
    if (self.ypos + 1) <= 7 then
      self.ypos += 1
    end
  end

  moving = false

  if self.xpos * 8 > self.x then
    moving = true
    self.x += 1
    self.frame = 1
    self.flipx = false
  end

  if self.xpos * 8 < self.x then
    moving = true
    self.x -= 1
    self.frame = 1
    self.flipx = true
  end

  if self.ypos * 8 > self.y then
    moving = true
    self.y += 1
    self.frame = 3
  end

  if self.ypos * 8 < self.y then
    moving = true
    self.y -= 1
    self.frame = 5
  end

  if self.step % 3 == 0 and moving then
    self.sframe = (self.sframe + 1) % 2
  end
end

player_draw = function(self)
  spr(self.frame + self.sframe, self.x, self.y, 1, 1, self.flipx)
  -- spr(51, self.x-5, self.y+3) -- seeds
  -- spr(52, self.x-5, self.y+3) -- watering can
  -- spr(53, self.x+2, self.y+6, 1, 1, false, true) -- shovel
end

function _init()
  poke(0x5f2c, 3)

  palt(1, true) -- dark blue color as transparency is true
  palt(0, false) -- black color as transparency is false

  player = make_player(8, 16)
end

function _update()
  player:update()
end

function _draw()
  cls()

  map(0, 0, 0, 0, 8, 8)
  player:draw()

		print("day 009", 18, 29, 7)
  -- print(player.sframe)
  -- spr(frame, 8, 8, 6, 5)
  -- print(player.sframe)
end


__gfx__
0000000011cccc1111cccc1111ccccc111ccccc111ccccc111ccccc133333333333333333dddddddddddddddddddddd300000000000000000000000000cccc00
0000000011ccc55511ccc55515555cc115555cc115ccccc115ccccc15666666533333333dddddddddddddddddddddddd0000000000000000000000000ddddc00
007007001144f0f11144f0f1144444411444444114444441144444415606606539999993dddddddddddddddddddddddd00000000000000000000000004444440
00077000114ff0f1114ff0f11f0ff0f11f0ff0f114444441144444413606606334444443dddddddddddddddddddddddd0000000000000000000000000f0ff0f0
0007700011ffffe111ffffe11ffeeff11ffeeff114444441144444413650056334400043dddddddddddddddddddddddd0000000000000000000000000ffeeff0
0070070011c8551111558c11115885511558851115ccc551155ccc513555555334400043dddddddddddddddddddddddd0000000000000000000000000d888cd0
0000000011cc55111155cc111144c551155c44111144c551155c44113667766334400043dddddddddddddddddddddddd00000000000000000000000000cccc00
00000000114414411114411111114411114411111144141111414411556776553440004366666666666666666666666600000000000000000000000000400400
3333333300cccc0000cccc00ffffffffffffffffffffffffffffffffffffffffffffffff65555556555555556555555600000000000000000000000000cccc00
3333333300cccccc0ddddc00fffffffffffffffffffffffffff33ffffffffffffff33fff657777565dddddd5657777560000000000000000000000000ddddc00
333333330044f0f004444440fffffffff9ffff9fffff3ffffff33ffffff33fffff3333ff657777565dddddd56577775600000000000000000000000004444440
33333333004ff0f00f0ff0f0fffffffff9ffff9ffff33fffff3333fffff33ffff888888f657777565dddddd5657777560000000000000000000000000f0ff0f0
3333333300ffffe00ffeeff0fffffffffffffffffff33fffff333fffff8888fff888888f657777565dddd5d5657777560000000000000000000000000ffeeff0
3333333300888c0000888c00fffffffffff9fffffff33ffffff33fffff8888fff888888f655555565dddd5d56555555600000000000000000000000000888c00
3333333300cddc0000cccc00fffffffffff9ffffffffffffffffffffffffffffff8888ff666666665dddddd56666666600000000000000000000000000cccc00
333333330004400000400400ffffffffffffffffffffffffffffffffffffffffffffffff666666665dddddd56666666600000000000000000000000000400400
00cccc0000cccc0000cccc0044444444444444444444444444444444444444444444444400000000000000000000000000000000000000000000000000cccc00
0ddddc000ddddc000dcccc0044444444444444444444444444433444444444444443344400000000004444000000000000065000000ff000000000000dcccc00
0444444004444440044444404444444449444494444434444443344444433444443333440000000000055000006ccc600066650000fff0000000000004444440
0f0ff0f00f0ff0f004444440444444444944449444433444443333444443344448888884000000000044440006d66660006666000ffff0f00000000004444440
0ffeeff00ffeeff00444444044444444444444444443344444333444448888444888888400000000004334000d06c660006666000ffffff00000000004444440
00888c0000888dd00dcccdd04444444444494444444334444443344444888844488888840000000000488400000666000005d0000ffffff0000000000dcccdd0
00dccd000d4ccdd00044cdd04444444444494444444444444444444444444444448888440000000000444400000000000005d00000ffff00000000000044cdd0
00400400000004000044040044444444444444444444444444444444444444444444444400000000000000000000000000000000000000000000000000440400
00cccc0000cccc0000cccc0011444411111111111116711111111111333333333333333333333333777777777777777777777777777777770000000000cccc00
0ddddc000ddddc000dcccc00111551111111111111666711111bb111333333333333333333333333704444077000000770065007700ff007000000000dcccc00
04444440044444400444444011544511166ccc611166661111bbbb114444444433cccccccccccc3370055007706ccc677066650770fff0070000000004444440
0f0ff0f00f0ff0f004444440144444416dd666161166661118888881455555543cccccccccccccc37044440776d66667706666077ffff0f70000000004444440
ddfeefdd0ffeeff00444444014433441d116c6161115d11118888881455555543cccccccccccccc3704334077d06c667706666077ffffff70000000004444440
dd888cdd0dd888d00ddcccd014488441111666611115d11118888881444444443cccccccccccccc370488407700666077005d0077ffffff7000000000ddcccd0
00cccc000ddcc4000ddc440014488421111111111115d11111888811444444443cccccccccccccc370444407700000077005d00770ffff07000000000ddc4400
00400400004000000040440011444211111111111115d111111111114444444433cccccccccccc33777777777777777777777777777777770000000000404400
__gff__
0000000000000000080000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000008080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
090a0b1010103839000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
191a1b3710101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101e1e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10141410102628101e1e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1014141010262610001e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
29292a2b3c2d2929000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
