pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- init

function _init()	
		poke(0x5f2c, 3)
  debug=""
  
  game_init()
end

function _update()
 step+=1
 game_update()
end

function _draw()
  cls()
  map(0,0,0,0,32,8)
  game_draw()
  
  print(debug, cam.x,0)
end

-->8
-- menu
-->8
-- game

step=0
score=0
gravity=0.3
friction=0.85
cam={x=0,y=0}

function game_init()
		step=0
		score=0
		cam={x=0,y=0}

  enemy_init()
end

function game_update()
  player_update()
  axe_update()
  enemy_update()
end

function game_draw()
  enemy_draw()
  player_draw()
  axe_draw()
end
-->8
-- player

player={
  hp=1,
  f=1,
  cf=0,
  x=0,
  y=48,
  dx=0,
  dy=0,
  fx=false,
  fy=false,
  max_dx=2,
  max_dy=3,
  accl=0.3,
  boost=3,
  jumping=false,
  dead=false,
}

function player_update()
  player.dy+=gravity
  player.dx*=friction
  
  if player.hp<=0 then
  		if not dead then
  		  dead=true
  		  player.dy-=player.boost/2
  		end
    player.f=1
    player.y+=player.dy
    player.fy=true
    return
  end
  
  if btn(⬅️) then
    player.dx-=player.accl
  elseif btn(➡️) then
    player.dx+=player.accl
  end
    
  -- jump
  if (btnp(⬆️) or btnp(🅾️))
   and not player.jumping then
    player.dy-=player.boost
    player.jumping=true
  end
  
  -- attack
  if btnp(❎) then
    add_axe()    
  end
  
  -- apply movement
  player.x+=player.dx
  player.y+=player.dy
  
  if player.x<cam.x then
    player.x=cam.x
    player.dx=0
  end
  
  --camera
  if player.x-cam.x>16 then
    cam.x+=player.dx
  end
  camera(cam.x,cam.y)
  
  -- frames
  if player.jumping then
    player.f=1
    player.cf=0
  elseif btn(❎) then
    player.f=3
    player.cf=0
  elseif abs(player.dx) < 1 then
    player.f=2
    player.cf=0
  else
    player.f=1
    if step%3==0 then
      player.cf=(player.cf+1)%2
    end
  end
  
  -- ground
  if player.y > 48 then
    player.y=48
    player.dy=0
    player.jumping=false
  end
end

function player_draw()
  spr(player.f+player.cf,player.x,player.y,1,1,player.fx,player.fy)
end

-->8
-- axe

axes={}
axe_limit=2
  
function add_axe()  
  -- limit axes
  if count(axes) >= axe_limit then
    return
  end
  
  axe={
    f=43,
    cf=0,
    x=player.x,
    y=player.y,
    dx=player.dx/1.2,
    dy=0,
    angle=0.3
  }
  
  add(axes,axe)
end

function axe_update()
  for axe in all(axes) do
    
    -- axe movemovement
    axe.y+=sin(axe.angle)*2
    axe.x+=2+axe.dx

    -- trajectory
    if axe.angle < 0.80 then
     axe.angle+=0.05
    end
    
    -- animation
    if step % 3 == 0 then
      axe.cf=(axe.cf+1)%4
    end
    
    -- remove axe
    if axe.y > 64 then
      del(axes, axe)
    end
		end
end

function axe_draw()
	 for axe in all(axes) do
 	  spr(axe.f+axe.cf, axe.x, axe.y)
 	end
end
-->8
-- enemies

enemies={}

-- enemy types
snail=17
snake=33
bee=53
rock=48
shot=59
squid=49
pig=30
bolder=-1

function add_enemy(x,y,etype)
  local enemy={
    et=etype,
    f=etype,
    timer=0,
    hp=1,
    cf=0,
    x=x,
    y=y,
    dx=0,
    dy=0,
    fx=false,
    fy=false,
    dead=false,
  }	
  
  -- enemy init
  if etype==snail then
    enemy.dx=-1
  elseif etype==bee then
    enemy.dx=-0.5
    enemy.angle=0.3
  elseif etype==pig then
    enemy.dx=-1
  elseif etype==shot then
    enemy.dx=-1
  elseif etype==squid then
    enemy.angle=0
  		enemy.y+=8
  end
  
  add(enemies,enemy)
end

function enemy_init()
  for y=0,8 do
    for x=0,32 do
      local et=mget(x,y)
    	  
						if et==snail
						or et==rock
						or et==pig
						or et==shot then
								add_enemy(x*8,y*8,et)
								mset(x,y,25) -- grass
						elseif et==bee then
								add_enemy(x*8,y*8,et)
								mset(x,y,23) -- mountain
						elseif et==squid then
								add_enemy(x*8,y*8,et)
								mset(x,y,56) -- water
						end
    end
  end
end

function enemy_update()
  for enemy in all(enemies) do
    enemy.timer+=1
    debug=#enemies
    
    if enemy_wait(enemy) then
      enemy.timer=0
    elseif enemy.x+8<cam.x then
      del(enemies,enemy)
    elseif enemy.dead then
      enemy_dead(enemy)
    elseif enemy.et==snail then
      snail_update(enemy)
    elseif enemy.et==rock then
      rock_update(enemy)
    elseif enemy.et==bee then
      bee_update(enemy)
    elseif enemy.et==shot then
      shot_update(enemy)
    elseif enemy.et==squid then
      squid_update(enemy)
    elseif enemy.et==pig then
      pig_update(enemy)
    end
  end
end

function enemy_wait(self)
  return cam.x+63<self.x
end

function enemy_remove(self)
  if self.x+8<cam.x 
  or self.y+8>64
  or self.y+8<0 then
    del(enemies,self)
  end
end

function enemy_hit(self)
  for axe in all(axes) do
    if touched(self,axe) then
      self.hp-=1
      del(axes,axe)
      
      if self.hp<=0
      and not self.dead then
        self.dead=true
      end
    end
  end
end

function enemy_attack(self)
	 if touched(player,self)
	 and self.hp>0 then
	   player.hp-=1
	 end
end

function enemy_dead(self)
 	self.fy=true
	 self.dy+=gravity
	 self.y+=self.dy	
	 
	 if self.y>64 then
	   del(enemies,self)
	 end
end

function snail_update(self)
  enemy_hit(self)
  enemy_attack(self)
  
  
		if step%50 == 0 then
		  self.x+=self.dx
		  self.cf=(self.cf+1)%2
		end
end

function pig_update(self)
  enemy_hit(self)
  enemy_attack(self)
  
		if step%8 == 0 then
		  self.x+=self.dx
		  self.cf=(self.cf+1)%2
		end
end

function rock_update(self)
  enemy_attack(self)
end

function shot_update(self)
  enemy_attack(self)
  
  self.x+=self.dx
  
  if step%5 == 0 then
		  self.cf=(self.cf+1)%2
		end
end

function squid_update(self)
  enemy_hit(self)
  enemy_attack(self)
  
  if step%5==0 then
		  self.cf=(self.cf+1)%2
		end
		
  -- movemovement
	 self.y+=sin(self.angle)*2.1
  self.angle+=0.02
end

function bee_update(self)
  enemy_hit(self)
  enemy_attack(self)
    
  -- movemovement
	 self.y+=sin(self.angle)
  self.x+=self.dx
  self.angle+=0.025
  
  -- animation
  if step%4 == 0 then
		  self.cf=(self.cf+1)%2
		end
end

function enemy_draw()
  for enemy in all(enemies) do
    spr(enemy.f+enemy.cf,enemy.x,enemy.y,1,1,enemy.fx,enemy.fy)
  end
end
-->8
-- objects

objects={}

-- object types
egg=51
axe=44
cloud=61
statue=-1

function add_objects(x,y)
  local object={
    f=51,
    cf=0,
    x=x,
    y=y
  }
  
  add(objects,object)
end

function egg_init()

end
-->8
-- shared

-- collision
function touched(obj1, obj2)
  return abs(obj1.x-obj2.x)<5 and
         abs(obj1.y-obj2.y)<5
end
__gfx__
000000000aaaaaa00aaaaaa000000000333333330044999999994400ccccccccb333333bb333333bb333333b0000300000000040000033000000000000000000
00000000aaaaaaa0aaaaaaa00aaaaaa0bb9bb9bb0044999999994400cccccccc333bbbb33bbbbbb33bbbb33300883800000004400093390000000830000ddd00
00700700aaafcf00aaafcf00aaaaaaa0b999999b0044999999994400cccccccc33bbbbbbbbbbbbbbbbbbbb33088e882000000a9009ff99800008883000ccccc0
00077000aaffcf00aaffcf00aaafcf00999999990044999999994400cccccccc3bbbbbbbbbbbbbbbbbbbbbb308e888200000aa9009f999800088583000ccf3c0
000770000ffffe000ffffe00aaffcf00944444490044999999994400cccccccc3bbbbbbbbbbbbbbbbbbbbbb308888820000aaa90099999800858833000ccefc0
00700700fffffff00ffff0000ffffe00444444440044999999994400cccccccc3bbbbbbbbbbbbbbbbbbbbbb3088882200aaaa900099998800888330000c888c0
000000000333300003f3300003333ff0444444440044999999994400cccccccc3bbbbbbbbbbbbbbbbbbbbbb30022220009999000008888000333300000c888c0
00000000f0000f000f00f0000f00f000444444440044999999994400ccccccccb3bbbbbbbbbbbbbbbbbbbb3b0000000000000000000000000000000000088800
33333333000000000000000006666660000000004499999999999944c333333cb3bbbbbbbbbbbbbbbbbbbb3bb333333bb333333bb333333bffffff000ffffff0
bbbbbbbb0000000000000000677777760066660044999999999999443bbbbbb33bbbbbbbbbbbbbbbbbbbbbb33333333333333333333333335fff5f0005fff5f0
b444444b000000000008888067777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333eeeeef000eeeeef0
44444444000888800028222867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333ededef000ededef0
44444444208822280282888867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333eeeeef000eeeeef0
4f444444028288880282828867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333ffffff00ffffffff
44444f4402828288dd82282867777776006666004499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333ffffff000ffffff0
44444444dd822828dd88888806666660000000004499999999999944bbbbbbbbb3bbbbbbbbbbbbbbbbbbbb3b3333333b3333333b3333333b0f00f000000f00f0
cccccccc003333000033330000000000000000004449999999999444c333333cb3bbbbbbbbbbbbbbbbbbbb3b0006000000006000000000000000000000000000
cccccccc0323333003233330033330000000000044499999999994443bbbbbb33bbbbbbbbbbbbbbbbbbbbbb30066600000066600005000000000050000000000
cccccfcc083333300833333032333300000660004449999999999444bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb30666660000666660055506000060555000000000
cfcccccc000333300003333088333300006776004449999999999444bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb36666500000056666005556600665550000000000
cccccccc003330000033300000333300006776004449999999999444bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb30665550000555660000566666666500000000000
ccccc66c033300000333000003330000000660004449999999999444bbbbbbbb33bbbbbbbbbbbbbbbbbbbb330060555005550600006666600666660000000000
c66ccccc033303330333330033330003000000004449999999999444bbbbbbbb333bbbbbbbbbbbbbbbbbb3330000050000500000000666000066600000000000
cccccccc003333300033333303333333000000004449999999999444bbbbbbbb3333333333333333333333330000000000000000000060000006000000000000
00000000000000000000000000000000000000000999077709990666333333cccccccccccc333333000000000000000000000000c66666666666666c00000000
0000000000dddd0000dddd0000000000000000009999966699999dddbbbbbb3cccccccccc3bbbbbb000000000000000000000000677777777777777600000000
00555500055dd550055dd5500666666006666660959999dd95999966b444445ccccccfccc544444b00000000000ee00000088000677777777777777600000000
056666500dddddd00dddddd06777777667767776aaa99900aaa999664444445ccfccccccc54444440000000000e88e00008ee800677777777777777600000000
056666500ddeedd00ddeedd0677777766777677600099477000994dd4444445cccccccccc54444440000000000e88e00008ee800677777777777777600000000
056666500ddeedd00ddeedd0677777766776777600994466009944004f44445cccccc66cc54444f400000000000ee00000088000667777777777776600000000
033366300dddddd00dddddd06ffffff66fff6ff609944ddd0994400044444f5cc66cccccc5f44444000000000000000000000000666777766777766600000000
333333330d0dd0d000d00d0006666660066666606ddd00006ddd00004444445cccccccccc5444444000000000000000000000000c666666cc666666c00000000
__map__
0909190a1919081919081919190a070707070707070707070707070707080909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
191919191919191919191919191a070707070707070707070707070707181919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
282928282a2a181a282829292a2a070707070707070707070707070707282929000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516070707070707070715160707070707070707070707070707070707071516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516070707070707070715160707070707070707070707070707070707071516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15161707070707073d3d20161717171717171717171717171717171717351516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
151619073d3d1e071e0715161919191919111919111919111930191919191516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010103720202031202020101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
