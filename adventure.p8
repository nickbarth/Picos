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
 btn_update()
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
  object_draw()
  axe_draw()
  print_score(score)
  player_draw()
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
  axes=false,
  jumping=false,
  dead=false,
}

function player_update()
  player.dy+=gravity
  player.dx*=friction
  
  if on_tile(player,32) then
    player.hp=0
    player.jumping=true
  end
  
  if player.hp<=0 then
  		if not player.dead then
  		  player.dead=true
  		  if not player.jumping then
  		    player.dy-=player.boost/2
  		  end
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
  if (btnd(⬆️) or btnd(🅾️))
   and not player.jumping then
    player.dy-=player.boost
    player.jumping=true
  end
  
  -- attack
  if player.axes and btnd(❎) then
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
pig=5
bolder=27

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
  elseif etype==rock then
    enemy.hp=99
  elseif etype==bolder then
    enemy.hp=99
    enemy.dx=-2.5
  elseif etype==shot then
    enemy.dx=-1
  elseif etype==squid then
    enemy.angle=1
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
						or et==bolder
						or et==pig
						or et==shot then
								add_enemy(x*8,y*8,et)
								mset(x,y,25) -- grass
						elseif et==bee then
								add_enemy(x*8,y*8,et)
								mset(x,y,23) -- mountain
						elseif et==squid then
								add_enemy(x*8,y*8,et)
								mset(x,y,32) -- water
						end
    end
  end
end

function enemy_update()
  for enemy in all(enemies) do
    enemy.timer+=1
    
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
    elseif enemy.et==bolder then
      bolder_update(enemy)
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
    if attacked(self,axe) then
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
  
		if step%50==0 then
		  self.x+=self.dx
		  self.cf=(self.cf+1)%2
		end
end

function pig_update(self)
  enemy_hit(self)
  enemy_attack(self)
  
		if step%8==0 then
		  self.x+=self.dx
		  self.cf=(self.cf+1)%2
		end
end

function bolder_update(self)
  enemy_hit(self)
  enemy_attack(self)
  
		if step%6==0 then
		  self.x+=self.dx
		  self.cf=(self.cf+1)%4
		end
end

function rock_update(self)
  enemy_attack(self)
  
		if step%8==0 then
		  self.x+=self.dx
		  self.cf=(self.cf+1)%4
		end
end

function rock_update(self)
  enemy_hit(self)
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
apple=11
banana=12
orange=13
pear=14
doll=15

function add_object(x,y,otype)
  local object={
    ot=otype,
    f=otype,
    cf=0,
    x=x,
    y=y,
    dx=0,
    dy=0,
    points=0,
    collected=false,
  }
  
  if otype==cloud then
    if object.y==48 then
		    object.angle=1
    else
      object.angle=1.5
    end
  elseif otype==axe then
    debug=object.ot
  elseif otype==egg then
    object.angle=0.3
  elseif otype==apple then
    object.points=50
  elseif otype==banana then
    object.points=100
  elseif otype==orange then
    object.points=150
  elseif otype==pear then
    object.points=250
  elseif otype==doll then
    object.points=500
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
						elseif ot==egg then
						  mset(x,y,7) -- sky
						  add_object(x*8,y*8,ot)
						elseif ot==apple
						or ot==banana
						or ot==orange
						or ot==pear
						or ot==doll
						then
								mset(x,y,7) -- sky
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
    elseif object.ot==egg then
      egg_update(object)
    elseif object.ot==axe then
      oaxe_update(object)
    elseif object.ot==apple
    or object.ot==banana
    or object.ot==orange
    or object.ot==pear
    or object.ot==doll
    then
      fruit_update(object)
    end
  end
end

function cloud_update(self)
  self.y+=sin(self.angle)*1
  self.angle+=0.02

  if standing(self,player)
  and not player.dead then
    player.y=self.y-8 
    player.dy=0
    player.jumping=false
  end
end

function egg_update(self)
  if not self.collected
  and collected(player,self) then
    self.collected=true
    self.f+=1
  end
  
  if self.collected then
    self.y+=sin(self.angle)*4
    self.x+=2+self.dx
    self.angle+=0.05
    
    if self.angle>0.75 then
      add_object(self.x,48,axe)
      del(objects,self)
    end
  end
end

function oaxe_update(self)
  if not self.collected
  and collected(player,self) then
    self.collected=true
			 player.axes=true
    del(objects,self)
  end
end

function fruit_update(self)
  if not self.collected
  and collected(player,self) then
    self.collected=true
    score+=self.points
    del(objects,self)
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

-- collisions
function attacked(obj1,obj2)
  return abs(obj1.x-obj2.x)<5 and
         abs(obj1.y-obj2.y)<5
end

function touched(obj1,obj2)
  return abs(obj1.x-obj2.x)<6 and
         abs(obj1.y-obj2.y)<6
end

function collected(obj1,obj2)
  return abs(obj1.x-obj2.x)<4 and
         abs(obj1.y-obj2.y)<4
end

function standing(obj1,obj2)
  return ((abs(obj1.x-obj2.x)<5 or
         abs((obj1.x+8)-obj2.x)<5) and
         abs(obj1.y-obj2.y)<8 and
         obj1.y-5>obj2.y)
end

function on_tile(obj,tile)
  return mget(obj.x/8,(obj.y+8)/8)==tile
end

-- print
function print_score(num)
  local str=tostr(num)
  print(str,32-(#str*2)+cam.x,1,7) 
end
 

-- no btn repeat trigger
do
  local state={0,0,0,0,0,0}
  
  function btn_update()
    for b=0,6 do
      if state[b]==0 
      and btn(b) then
        state[b]=1
      elseif state[b]==1 then
        state[b]=2
      elseif state[b]==2 and not btn(b) then
        state[b]=3
      elseif state[b]==3 then
        state[b]=0
      end
    end
  end

  function btnd(b)
    return state[b]==1
  end

  function btnu(b)
    return state[b]==3
  end
end

__gfx__
000000000aaaaaa00aaaaaa000000000333333330ffffff00ffffff0ccccccccb333333bb333333bb333333b0000300000000040000033000000300000000000
00000000aaaaaaa0aaaaaaa00aaaaaa0bb9bb9bb05fff5f005fff5f0cccccccc333bbbb33bbbbbb33bbbb333008838000000044000933900000f3b00000bbb80
00700700aaafcf00aaafcf00aaaaaaa0b999999b0eeeeef00eeeeef0cccccccc33bbbbbbbbbbbbbbbbbbbb33088e882000000a9009ff998000fbbb0000bbbbb0
00077000aaffcf00aaffcf00aaafcf00999999990ededef00ededef0cccccccc3bbbbbbbbbbbbbbbbbbbbbb308e888200000aa9009f999800bbbbbb000bbfcb0
000770000ffffe000ffffe00aaffcf00944444490eeeeef00eeeeef0cccccccc3bbbbbbbbbbbbbbbbbbbbbb308888820000aaa90099999800bbbbb3000bb8fb0
00700700fffffff00ffff0000ffffe0044444444ffffffff0ffffff0cccccccc3bbbbbbbbbbbbbbbbbbbbbb3088882200aaaa9000999988000bbb33000b222b0
000000000333300003f3300003333ff0444444440ffffff00ffffff0cccccccc3bbbbbbbbbbbbbbbbbbbbbb30022220009999000008888000003330000b222b0
00000000f0000f000f00f0000f00f00044444444000f00f000f00f00ccccccccb3bbbbbbbbbbbbbbbbbbbb3b00000000000000000000000000000000000eee00
33333333000000000000000006666660000000004499999999999944c333333cb3bbbbbbbbbbbbbbbbbbbb3b000000000000000000000000000000000ffffff0
bbbbbbbb0000000000000000677777760066660044999999999999443bbbbbb33bbbbbbbbbbbbbbbbbbbbbb30000000000000000000000000000000005fff5f0
b444444b000000000008888067777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3006666000066660000666600006666000eeeeef0
44444444000888800028222867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb306d6666006d66d6006d66660066566600ededef0
44444444208822280282888867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3066665600666666006666560066666600eeeeef0
4f444444028288880282828867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb306666660066666600666666006666660ffffffff
44444f4402828288dd82282867777776006666004499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb306d666600666566006d6666006d66d600ffffff0
44444444dd822828dd88888806666660000000004499999999999944bbbbbbbbb3bbbbbbbbbbbbbbbbbbbb3b00666600006666000066660000666600000f00f0
dccddccd003333000033330000000000000000000055500000555000c333333cb3bbbbbbbbbbbbbbbbbbbb3b000600000000600000000000000000000ffffff0
dddddddd0323333003233330033330000000000005565500055655003bbbbbb33bbbbbbbbbbbbbbbbbbbbbb30066600000066600005000000000050005fff5f0
dddddddd083333300833333032333300000660000516555005165550bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3066666000066666005550600006055500eeeeef0
dddddddd000333300003333088333300006776000aaa55660aaa5555bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3666650000005666600555660066555000ededef0
dddddd6d00333000003330000033330000677600aaaaa666aaaaa666bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb3066555000055566000056666666650000eeeeef0
dd6dd6dd033300000333000003330000000660000055566600555666bbbbbbbb33bbbbbbbbbbbbbbbbbbbb330060555005550600006666600666660066ffff66
d6dddddd033303330333330033330003000000000005555500055566bbbbbbbb333bbbbbbbbbbbbbbbbbb3330000050000500000000666000066600000ffff00
dddddddd003333300033333303333333000000000000005500000055bbbbbbbb3333333333333333333333330000000000000000000060000006000000f000f0
00000000000000000000000000000000000000000aaa66660aaa0666333333dddccddccddccddccddd33333300000000000000000666666666666660ffffff00
0000000000888800008888000000000000000000aaaa5666aaaa5666bbbbbb3dddddddddddddddddd3bbbbbb000000000000000067777777777777765fff5f00
0055550008288280082882800666666006666660a5aa5a00a5aa5a66b444445dddddddddddddddddd544444b000ee000000880006777777777777776eeeeef00
0566665008888880088888806777777667767776aaa55a00aaa55a664444445dddddddddddddddddd544444400e88e00008ee8006777777777777776ededef00
05666650088ee880088ee8806777777667776776000aaa66000aaa664444445ddddddd6ddddddd6dd544444400e88e00008ee8006777777777777776eeeeef00
05666650088ee88008888880677777766776777600555566005555004f44445ddd6dd6dddd6dd6ddd54444f4000ee0000008800066777777777777666ffff600
0333663008888880088888806ffffff66fff6ff60aaaa6660aaaa00044444f5dd6ddddddd6ddddddd5f44444000000000000000006677766667776606ffff600
333333330808808000800800066666600666666065550000655500004444445dddddddddddddddddd5444444000000000000000000666660066666000f00f000
__map__
0909190a1919081919081919190a070707070707070707070707070707080909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
191919191919191919191919191a070707070707070707070707070707181919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2829282a07070707070707282a2a070707070707070707070707070707282929000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516070707070707070707151607070707070707070707070707070707071516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15160707070707073d3e07151607070707070707070707070707070707071516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516070707070707070707151617171717171717171717171717171717351516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15160733073d3e07070707151619191b19111919111919111930191919191516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010371010101010103a101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
