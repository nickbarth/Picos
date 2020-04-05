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
  object_init()
end

function game_update()
  player_update()
  axe_update()
  enemy_update()
  object_update()
end

function game_draw()
  enemy_draw()
  player_draw()
  axe_draw()
  object_draw()
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
pig=27
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

function add_object(x,y,otype)
  local object={
    ot=otype,
    f=otype,
    cf=0,
    x=x,
    y=y,
    dx=0,
    dy=0,
  }
  
  if otype==cloud then
    if object.y==48 then
		    object.angle=1
    else
      object.angle=1.5
    end
  end
  
  add(objects,object)
end

function object_init()
  for y=0,8 do
    for x=0,32 do
      local ot=mget(x,y)
    	  
						if ot==cloud then
								mset(x,y,7) -- sky
								mset(x+1,y,7)
								add_object(x*8,y*8,ot)
						end
				end
		end
end

function object_update()
  for object in all(objects) do
    if false then
    elseif object.x+16<cam.x then
      del(objects,object)
    elseif object.ot==cloud then
      cloud_update(object)
    end
  end
end

function cloud_update(self)
  -- movemovement
  debug="cloud"
  

  
  self.y+=sin(self.angle)*1
  self.angle+=0.02
  
  if standing(self,player) then
    player.y=self.y-8
    
    player.dy=0
    player.jumping=false
  end
end

function object_draw()
  for object in all(objects) do
    spr(object.f+object.cf,object.x,object.y,1,1,object.fx,object.fy)
    
    if object.ot==cloud then
      spr(object.f+1,object.x+8,object.y,1,1,object.fx,object.fy)
    end
  end
end
-->8
-- shared

-- collision
function touched(obj1,obj2)
  return abs(obj1.x-obj2.x)<5 and
         abs(obj1.y-obj2.y)<5
end

function standing(obj1,obj2)
  return ((abs(obj1.x-obj2.x)<5 or
         abs((obj1.x+8)-obj2.x)<5) and
         abs(obj1.y-obj2.y)<8 and
         obj1.y-5>obj2.y)
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
33333333000000000000000006666660000000004499999999999944c333333cb3bbbbbbbbbbbbbbbbbbbb3b000000000000000004444440ffffff000ffffff0
bbbbbbbb0000000000000000677777760066660044999999999999443bbbbbb33bbbbbbbbbbbbbbbbbbbbbb3000000000000000044444f445fff5f0005fff5f0
b444444b000000000008888067777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb300555f000044440044444444eeeeef000eeeeef0
44444444000888800028222867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3044444400444444044444444ededef000ededef0
44444444208822280282888867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3044444400444444044444444eeeeef000eeeeef0
4f444444028288880282828867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb30f444440044444404f444444ffffff00ffffffff
44444f4402828288dd82282867777776006666004499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3054444400f44444044444444ffffff000ffffff0
44444444dd822828dd88888806666660000000004499999999999944bbbbbbbbb3bbbbbbbbbbbbbbbbbbbb3b005444000044f400044444400f00f000000f00f0
dccddccd003333000033330000000000000000000055500000555000c333333cb3bbbbbbbbbbbbbbbbbbbb3b000600000000600000000000000000000aaa0666
dddddddd0323333003233330033330000000000005565500055655003bbbbbb33bbbbbbbbbbbbbbbbbbbbbb300666000000666000050000000000500aaaa5666
dddddddd083333300833333032333300000660000516555005165550bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb306666600006666600555060000605550a5aa5a66
dddddddd000333300003333088333300006776000aaa55660aaa5555bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb366665000000566660055566006655500aaa55a00
dddddd6d00333000003330000033330000677600aaaaa666aaaaa666bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb306655500005556600005666666665000000aaa77
dd6dd6dd033300000333000003330000000660000055566600555666bbbbbbbb33bbbbbbbbbbbbbbbbbbbb330060555005550600006666600666660000555577
d6dddddd033303330333330033330003000000000005555500055566bbbbbbbb333bbbbbbbbbbbbbbbbbb333000005000050000000066600006660000aaaa777
dddddddd003333300033333303333333000000000000005500000055bbbbbbbb3333333333333333333333330000000000000000000060000006000065550000
00000000000000000000000000000000000000000aaa66660aaa0666333333dddccddccddccddccddd333333000000000000000006666666666666600aaa0666
0000000000eeee0000eeee000000000000000000aaaa5666aaaa5666bbbbbb3dddddddddddddddddd3bbbbbb00000000000000006777777777777776aaaa5666
00555500022ee220022ee2200666666006666660a5aa5a00a5aa5a66b444445ddddddddddddddfddd544444b000ee000000880006777777777777776a5aa5a77
056666500eeeeee00eeeeee06777777667767776aaa55a00aaa55a664444445ddddddddddfddddddd544444400e88e00008ee8006777777777777776aaa55a77
056666500ee88ee00ee88ee06777777667776776000aaa66000aaa664444445dddddddddddddddddd544444400e88e00008ee8006777777777777776000aaa77
056666500ee88ee00ee88ee0677777766776777600555566005555004f44445dddddddddddddd66dd54444f4000ee00000088000667777777777776600555500
033366300eeeeee00eeeeee06ffffff66fff6ff60aaaa6660aaaa00044444f5dddddddddd66dddddd5f44444000000000000000066677776677776660aaaa000
333333330e0ee0e000e00e00066666600666666065550000655500004444445dddddddddddddddddd54444440000000000000000066666600666666065550000
__map__
0909190a1919081919081919190a070707070707070707070707070707080909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
191919191919191919191919191a070707070707070707070707070707181919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
282928282a2a181a282829292a2a070707070707070707070707070707282929000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516070707070707070715160707070707070707070707070707070707071516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15160707070707073d3e15160707070707070707070707070707070707071516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516070707070707070715161717171717171717171717171717171717351516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
151607071b3d3e07070715161919191919111919111919111930191919191516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010103720202031202020101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
