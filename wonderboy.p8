pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- init

game=1
title=2
gameover=3
winner=4

state=title

function _init()	
		poke(0x5f2c, 3)
  debug=""
  music(1)
  
  game_init()
end

function _update()
 step+=1
 btn_update()
 
 if state==game then
   game_update()
 elseif state==title then
   gameover_update()
 elseif state==gameover then
   gameover_update()
 elseif state==winner then
   winner_update()
 end
end

function _draw()
  cls()
  
  if state==game then
    game_draw()
  elseif state==title then
    title_draw()
  elseif state==gameover then
    gameover_draw()
  elseif state==winner then
    winner_draw() 
  end
  
  print(debug,cam.x,cam.y,7)
end

-->8
-- states

-- winner
do
  local xscroll=0
  local cf=0
 
 	function winner_update()
    cam.x=0
    cam.y=0
    camera(0,0)
	   xscroll=(xscroll+1)%32
	  
	   if step%10==0 then
	     cf=(cf+1)%2
	   end
	 end
	
 	function winner_draw()
	   map(120,0,0-xscroll,0,8,8)
	   map(120,0,32-xscroll,0,8,8)
	   spr(1+cf,34,48)
	   spr(37+cf,22,48,1,1,0)
	   print("a winner is you!",1,10,7)
	   print_score(score)
	 end
end

function title_draw()
  map(0,8,0,0,8,8)
end

function gameover_update()
  cam.x=0
  cam.y=0  
  camera(0,0)

  if btnp(❎) or btnp(🅾️) then
    reload(0x2000, 0x2000, 0x1000)
    game_init()
    state=game
  end
end

function gameover_draw()
  print("game over",14,24,7)
  print_score(score)
  spr(31,28,34,1,1)
end
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

  objects={}
  player={}
  axes={}
  enemies={}

  player_init()
  axe_init()
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
  map(0,0,0,0,256,8)
  enemy_draw()
  object_draw()
  axe_draw()
  player_draw()
  print_score(score)
end
-->8
-- player

player={}

function player_init()
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
end

function player_update()
  player.dy+=gravity
  player.dx*=friction

  -- on water
  if on_tile(player,56) then
    player.hp-=1
    player.jumping=true
  end
  
  if player.hp<=0 then
  		if not player.dead then
  		  player.dead=true
  		  sfx(19)
  		  if not player.jumping then
  		    player.dy-=player.boost/2
  		  end
  		end
    player.f=1
    player.y+=player.dy
    player.fy=true
    
    -- gameover
    if player.y>100 then
      state=gameover
    end
  
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
    sfx(17)
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
  elseif player.x>896 then
    player.x=896
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
  elseif btn(❎) and player.axes then
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
		
do
		local limit=2
		  
		function add_axe()  
		  -- limit axes
		  if count(axes) >= limit then
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
		  
		  sfx(15)
		  add(axes,axe)
		end
		
		function axe_init()
		  axes={}
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
end
-->8
-- enemies

enemies={}

do
		-- enemy types
		local snail=17
		local snail_b=18
		local snake=33
		local bee=53
		local rock=48
		local shot=59
		local squid=49
		local pig=5
		local bolder=27
		local boss=72
		
		-- functions
		function add_enemy(x,y,etype)
		  local enemy={
		    et=etype,
		    f=etype,
		    timer=0,
		    hp=1,
		    cf=0,
		    score=0,
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
		    enemy.score=10
		  elseif etype==bee then
		    enemy.dx=-0.5
		    enemy.angle=0.3
		    enemy.score=50
		  elseif etype==pig then
		    enemy.dx=-1
		    enemy.score=150
		  elseif etype==rock then
		    enemy.hp=99
		  elseif etype==bolder then
		    enemy.hp=99
		    enemy.dx=-2.5
		  elseif etype==shot then
		    enemy.dx=-1
		  elseif etype==boss then
		    enemy.hp=8
		    enemy.dx=-1
		    enemy.damaged=false
		    enemy.score=0
		  elseif etype==squid then
		    enemy.angle=1
		  		enemy.y+=8
		  		enemy.score=250
		  end
		  
		  add(enemies,enemy)
		end
		
		function enemy_init()
		  ememies={}
		  
		  for y=0,8 do
		    for x=0,256 do
		      local et=mget(x,y)
		    	  
								if et==snail
								or et==rock
								or et==bolder
								or et==pig
								or et==shot then
										add_enemy(x*8,y*8,et)
										mset(x,y,25) -- grass
								elseif et==snail_b  then
								  add_enemy(x*8,y*8,17)
								  mset(x,y,7) -- sky
								elseif et==bee then
										add_enemy(x*8,y*8,et)
										mset(x,y,23) -- mountain
								elseif et==squid then
										add_enemy(x*8,y*8,et)
										mset(x,y,56) -- water
								elseif et==boss then
										add_enemy(x*8,y*8,et)
										mset(x,y,39)
										mset(x+1,y,39)
										mset(x,y+1,39)
										mset(x+1,y+1,39)
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
		    elseif enemy.et==boss then
		      boss_update(enemy)
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
		        score+=self.score
		        sfx(18)
		      end
		      return true
		    end
		  end
		  return false
		end
		
		function boss_hit(self)
		  if self.damaged then
		    return
		  end
		  
		  local boss={
		    hp=99,
		    x=self.x+8,
		    y=self.y-4,
		  }
		  if enemy_hit(boss) then
			  	if self.hp<=0
				  and not self.dead then
				    self.dead=true
				  end
				  return true
			 end
			 return false
		end
		
		function enemy_attack(self)
			 if touched(player,self)
			 and self.hp>0 then
			   player.hp-=1
			 end
		end
		
		function boss_attack(self)
			 if collision(player,
			   {x=self.x+8,y=self.y+8},13)
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
		
		function boss_update(self)
		  boss_attack(self)
		  
				if step%10==0 then
				  self.x+=self.dx
				  self.cf=(self.cf+1)%2
				  self.damaged=false
				end
		
		  if boss_hit(self) then
		    self.hp-=1
		    self.damaged=true
		  end
				
				if step%50==0 then
				  add_enemy(self.x,self.y,shot)
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
		    
		    if enemy.et==boss then
			     local cf=enemy.cf*2
		      if enemy.damaged then
		        cf+=4
		      end
		      
		      spr(enemy.f+cf,enemy.x,enemy.y,1,1,enemy.fx,enemy.fy)
		      spr(enemy.f+1+cf,enemy.x+8,enemy.y,1,1,enemy.fx,enemy.fy)
		      spr(enemy.f+16+cf,enemy.x,enemy.y+8,1,1,enemy.fx,enemy.fy)
		      spr(enemy.f+17+cf,enemy.x+8,enemy.y+8,1,1,enemy.fx,enemy.fy)
		    else
		      spr(enemy.f+enemy.cf,enemy.x,enemy.y,1,1,enemy.fx,enemy.fy)
		    end
		  end
		end
end
-->8
-- objects

objects={}

do
		-- object types
		local egg=51
		local axe=44
		local cloud=61
		local apple=11
		local banana=12
		local orange=13
		local pear=14
		local doll=15
		local girl=37

  -- functions		
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
		  elseif otype==girl then
		    -- 
		  elseif otype==axe then
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
		  objects={}
		  
		  for y=0,8 do
		    for x=0,256 do
		      local ot=mget(x,y)
		
								if ot==cloud then
										mset(x,y,7) -- sky
										mset(x+1,y,7)
										add_object(x*8,y*8,ot)
								elseif ot==egg then
								  mset(x,y,7) -- sky
								  add_object(x*8,y*8,ot)
								elseif ot==girl then
								  mset(x,y,39) -- cave
								  add_object(x*8,y*8,ot)
								elseif ot==apple then
										mset(x,y,25) -- grass
										add_object(x*8,y*8,ot)
								elseif ot==banana
								or ot==orange
								or ot==pear
								or ot==doll
								or ot==axe
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
		    elseif object.ot==girl then
		      girl_update(object)
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
		    sfx(16)
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
		    sfx(16)
		  end
		end
		
		function girl_update(self)
		  if not self.collected
		  and collected(player,self) then
		    self.collected=true
		    score+=500
			   state=winner
			   sfx(16)
		  end
		  
		  if step%10==0 then
				  self.cf=(self.cf+1)%2
				end
		end
		
		function fruit_update(self)
		  if not self.collected
		  and collected(player,self) then
		    self.collected=true
		    score+=self.points
		    del(objects,self)
		    sfx(16)
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
end
-->8
-- shared

-- collisions
function ctest(obj1,obj2,dx,dy)
  return abs(obj1.x-obj2.x)<dx and
         abs(obj1.y-obj2.y)<dy
end

function collision(obj1,obj2,d)
  return ctest(obj1,obj2,d,d)
end

function attacked(obj1,obj2)
  return collision(obj1,obj2,5)
end

function touched(obj1,obj2)
 return collision(obj1,obj2,6)
end

function collected(obj1,obj2)
  return collision(obj1,obj2,5)
end

function standing(obj1,obj2)
  return ctest({
    x=obj1.x+4,
    y=obj1.y
  }, obj2, 10, 8) and
  obj1.y-4>obj2.y
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
000000000aaaaaa00aaaaaa000000000333333330ffffff00ffffff0cccccccccc33333333333333333333cc0000300000000040000033000000300000000000
00000000aaaaaaa0aaaaaaa00aaaaaa0bb9bb9bb05fff5f005fff5f0ccccccccc33bbbbb3bbbbbb3bbbbb33c008838000000044000933900000f3b00000bbb80
00700700aaafcf00aaafcf00aaaaaaa0b999999b0eeeeef00eeeeef0cccccccc33bbbbbbbbbbbbbbbbbbbb33088e882000000a9009ff998000fbbb0000bbbbb0
00077000aaffcf00aaffcf00aaafcf00999999990ededef00ededef0cccccccc3bbbbbbbbbbbbbbbbbbbbbb308e888200000aa9009f999800bbbbbb000bbfcb0
00077000affffe00affffe00aaffcf00944444490eeeeef00eeeeef0cccccccc3bbbbbbbbbbbbbbbbbbbbbb308888820000aaa90099999800bbbbb3000bb8fb0
00700700fffffff00ffff000affffe0044444444ffffffff0ffffff0cccccccc3bbbbbbbbbbbbbbbbbbbbbb3088882200aaaa9000999988000bbb33000b222b0
000000000333300003f3300003333ff0444444440ffffff00ffffff0cccccccc3bbbbbbbbbbbbbbbbbbbbbb30022220009999000008888000003330000b222b0
00000000f0000f000f00f0000f00f00044444444000f00f000f00f00ccccccccc3bbbbbbbbbbbbbbbbbbbb3c00000000000000000000000000000000000eee00
33333333000000000000000044444444d66666664499999999999944c333333cc3bbbbbbbbbbbbbbbbbbbb3c0000000000000000000000000000000000000000
bbbbbbbb0000000000000000444444446ddddddd44999999999999443bbbbbb33bbbbbbbbbbbbbbbbbbbbbb300000000000000000000000000000000aa000000
b444444b0000000000088880444444446d5555dd4499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb300666600006666000066660000666600aaffe000
444444440008888000282228444444446d5555554499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb306d6666006d66d6006d6666006656660aaf5ff3f
444444442088222802828888444444446d5555554499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb306666560066666600666656006666660aaf5ff30
4f4444440282888802828288444444446d5555554499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb306666660066666600666666006666660aaaffff0
44444f4402828288dd822828444444446dd555f54499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb306d666600666566006d6666006d66d60aaaaff3f
44444444dd822828dd888888444444446dd555554499999999999944bbbbbbbbc3bbbbbbbbbbbbbbbbbbbb3c006666000066660000666600006666000aaaa000
666666660033330000333300000000006dd5555500bbbb8800bbbb88555555553bbbbbbb3bbbbbbbbbbbbbb3000600000000600000000000000000000ffffff0
dddddddd0323333003233330033330006d555f550bbbbb880bbbbb88555555553bbbbbbb3bbbbbbbbbbbbbb3006660000006660000d0000000000d0005fff5f0
d55dd55d0833333008333330323333006d55555500fcfbbb00fcfbbb555555553bbbbbbb3bbbbbbbbbbbbbb306666600006666600ddd06000060ddd00eeeeef0
555555550003333000033330883333006dd5555500fcffbb00fcffbb555555553bbbbbbb3bbbbbbbbbbbbbb36666d000000d666600ddd660066ddd000ededef0
55f555550033300000333000003333006dd5555500efffbb00efffbb555555553bbbbbbb3bbbbbbbbbbbbbb3066ddd0000ddd660000d66666666d0000eeeeef0
555555f50333000003330000033300006d55f55500f222bb000222bb5555555533bbbbbb3bbbbbbbbbbbbb330060ddd00ddd0600006666600666660066ffff66
555555550333033303333300333300036d555555000eeebb000efebb55555555333bbbb333bbbbb33bbbb33300000d0000d00000000666000066600000ffff00
555555550033333000333333033333336dd5555500f000fb000f0fbb55555555c3333333333333333333333c0000000000000000000060000006000000f000f0
00000000000000000000000000000000000000000aaa66660aaa0666333333dddccddccddddddddddd33333300000000000000000666666666666660ffffff00
0000000000888800008888000000000000000000aaaa5666aaaa5666bbbbbb3dddddddddddddddddd3bbbbbb000000000000000067777777777777765fff5f00
0055550008288280082882800666666006666660a5aa5a00a5aa5a66b444445dddddddddddddddddd544444b000ee000000880006777777777777776eeeeef00
0566665008888880088888806777777667767776aaa55a00aaa55a664444445dddddddddddddddddd544444400e88e00008ee8006777777777777776ededef00
05666650088ee880088ee8806777777667776776000aaa66000aaa664444445ddddddd6dddddddddd544444400e88e00008ee8006777777777777776eeeeef00
05666650088ee88008888880677777766776777600555566005555004f44445ddd6dd6ddddddddddd54444f4000ee0000008800066777777777777666ffff600
0333663008888880088888806ffffff66fff6ff60aaaa6660aaaa00044444f5dd6ddddddddddddddd5f44444000000000000000006677766667776606ffff600
333333330808808000800800066666600666666065550000655500004444445dddddddddddddddddd5444444000000000000000000666660066666000f00f000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000099999000000000009999900000000000999990000000000099999000000
ccccccccccccccccccccbcccccccccccccaaaaaaaaaaaccccccccccccccccccc00009977799000000000997779900000000099eee9900000000099eee9900000
cccccccccccccccccccbbccccccccaaaaaaaaaaaaaaaaaaacccccccccccccccc0000977777900000000097777790000000009eeeee90000000009eeeee900000
ccccccccccccccccccbbbcccccccaaaaaaaaaaaaaaaaaaaaaaaccccccccccccc0000977877900000000097787790000000009ee2ee90000000009ee2ee900000
ccccccccccccccccbbbbbbcccbbbaaaaaaaaaaaaaaaaaaaaaaaaaccccccccccc00009977799000000000997779900000000099eee9900000000099eee9900000
cccccccccccbbbbbbbbbbbcbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccc0000998889900000000099888990000000009988899000000000998889900000
ccccc88888cbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccc0002228782222000000222999222200000022287822220000002229992222000
cccc88eee88bbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccc0009928882299900009992222229900000099288822999000099922222299000
cccc8e888e8bbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccc0099926662229900009922666229990000999266622299000099226662299900
cccc8e8eee8bbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccc0099265656599900009996565652990000992656565999000099965656529900
cccc8e8eee8bbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccc0099966666599900009996666659990000999666665999000099966666599900
cccc8e8eee8bbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccc0099956565599900009995656559990000999565655999000099956565599900
cccc88eee88bbbbbbbbb88888bbaaaaaaaaaaaaaaaaaaaaaaaaaaaaccccccccc0099955555522200000225555559990000999555555222000002255555599900
ccccc88888bbbbb8888888888bbaaaaaafaaafaaaa7aaaaaaaaaaaaccccccccc0002999225522200000225522999220000029992255222000002255229992200
ccccbbbbbbbbb888888888888bbaaaaaff7aa7ffaa7aaaaaaaaaaaaacccccccc0002999229992220000299922999222000029992299922200002999229992220
ccccbbbbbbbbb8888888888fffbaaaaaff7cc7ffaa7cc7aaaafaaaaacccccccc0002222229992222000299922222222200022222299922220002999222222222
cccbbbbbbbbbb8888ffffffff7faaaaaff7cc7fffa7cc7aaaaffaaaacccccccc0000999990999000999099999000000000000000000000000000000000000000
cccbbbbbbbbbbfffffffff7777fcaaaaff7777f5ff7777aaaaffaaaaaccccccc9999997999999000999999799999900000000000000000000000000000000000
ccbbbbbbbbbfbb7777ffff7cc7fcaaaafffffff5ffffffaaaaffaaaaaccccccc9999977799090000090997779999900000000000000000000000000000000000
ccbbbbbbbbbfbb77ccffff7ccffcaaaaffffffffffffffaaaafaaaaaaccccccc0909778779090000090977877909000000000000000000000000000000000000
ccbbbbbbbbbffb77ccfffffffffcaaaafffffffffffffffaaaaaaaaaaccccccc0909977799090000090997779909000000000000000000000000000000000000
cccbbbbbbbbffffffffffffffffcaaaafffffffffffffffaaaaaaaaaaccccccc0900999990090000090098889009000000000000000000000000000000000000
cccbbbbbbbbffffffffffffffffcaaaaffffffffffeffffaaaaaaaaaaacccccc0999999999990000099998789999000000000000000000000000000000000000
cccbbbbbbffffffffffffffffffcaaaafffffeeeeefffffaaaaaaaaaaacccccc0000988890000000000098889000000000000000000000000000000000000000
33cbbbbbfffffffffffffffffffcaaaaaffffffffffffffaaaaaaaaaaac333330000999990000000000099999000000000000000000000000000000000000000
333bbbbbfffffffffffeefffffccaaaaaffffffffffffffaaaaaaaaaaa3333330990999990990000099099999099000000000000000000000000000000000000
333bbbbbbfffffffffe77effff33aaaaaafffffffffffffaaaaaaaaaaa3333339999999999999900999999999999990000000000000000000000000000000000
333bbbbbbbffffffffe88effff33aaaaaaafffffffffffaaaaaaaaaaaa3333339999999999999900999999999999990000000000000000000000000000000000
333bbbbbbbbfffffffe88effff33aaa3aaaaafffffffffaaaaaaaaaaaaa333339999999999999900999999999999990000000000000000000000000000000000
333bbbbbbbbbfffffffeeffff333aaa3aaaaaaaaaaaaffaaaaaaaaaaaaa333330999999999999000099999999999900000000000000000000000000000000000
333bbbbbbbbbfffffffffff333333a333aaaaaaaaaaaffaaaaffffffaaa333339909900009909000090990000990900000000000000000000000000000000000
333bbbbbbbbbffffff33333333333a333aaaaaaffffffffffffffffffaa333330000000000009900990000000000990000000000000000000000000000000000
3333bbbbbbbbbfffffffff33333333333affffffffffffffffffffffffa333330000000000000000000000000000000000000000000000000000000000000000
33333bbbbbbbbffffffffffff33333333ffffffffffffffffffffffffff333330000000000000000000000000000000000000000000000000000000000000000
33333bbbbbbbbbffffffffffff333333ffffffffffffffffffffffffffff33330000000000000000000000000000000000000000000000000000000000000000
33333bbbbbbbbbffffffffffff33333fffffffffffffffffffffffffffff33330000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888000800080000000800000008000000080000000800000008888888880000000000000000000000000000000000000000000000000000000000000000
88888888070807080777770807700708077777080777770807777708888888880000000000000000000000000000000000000000000000000000000000000000
88888888070007080700070807070708070007080777770807000708888888880000000000000000000000000000000000000000000000000000000000000000
88888888070707080700070807007708070007080700000807777008888888880000000000000000000000000000000000000000000000000000000000000000
88888888007070080777770807000708077777080777770807000708888888880000000000000000000000000000000000000000000000000000000000000000
88888888800000880000000800080008000000080000000800080008888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888000000080000000800000008888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888077777080777770807000708888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888070007080700070807777708888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888077777080700070800000708888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888070007080777770807777708888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888077770080000000800000008888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888000000888888888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007770770077707770777000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007070707077707000700000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007770777070000070007000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007000707077707770777000777700000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccbbccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccbbccccccccccccccccccccccccccaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccbbbbccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccbbbbccccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccbbbbbbccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccbbbbbbccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccbbbbbbbbbbbbccccccbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccc
ccccccccccccccccccccccccccccccccbbbbbbbbbbbbccccccbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccccc
ccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbccbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccc
ccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbccbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccccc
cccccccccc8888888888ccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
cccccccccc8888888888ccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
cccccccc8888eeeeee8888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
cccccccc8888eeeeee8888bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
cccccccc88ee888888ee88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
cccccccc88ee888888ee88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
cccccccc88ee88eeeeee88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
cccccccc88ee88eeeeee88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
cccccccc88ee88eeeeee88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
cccccccc88ee88eeeeee88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
cccccccc88ee88eeeeee88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
cccccccc88ee88eeeeee88bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
cccccccc8888eeeeee8888bbbbbbbbbbbbbbbbbb8888888888bbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
cccccccc8888eeeeee8888bbbbbbbbbbbbbbbbbb8888888888bbbbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
cccccccccc8888888888bbbbbbbbbb88888888888888888888bbbbaaaaaaaaaaaaffaaaaaaffaaaaaaaa77aaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
cccccccccc8888888888bbbbbbbbbb88888888888888888888bbbbaaaaaaaaaaaaffaaaaaaffaaaaaaaa77aaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccccc
ccccccccbbbbbbbbbbbbbbbbbb888888888888888888888888bbbbaaaaaaaaaaffff77aaaa77ffffaaaa77aaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
ccccccccbbbbbbbbbbbbbbbbbb888888888888888888888888bbbbaaaaaaaaaaffff77aaaa77ffffaaaa77aaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc
ccccccccbbbbbbbbbbbbbbbbbb88888888888888888888ffffffbbaaaaaaaaaaffff77cccc77ffffaaaa77cccc77aaaaaaaaffaaaaaaaaaacccccccccccccccc
ccccccccbbbbbbbbbbbbbbbbbb88888888888888888888ffffffbbaaaaaaaaaaffff77cccc77ffffaaaa77cccc77aaaaaaaaffaaaaaaaaaacccccccccccccccc
ccccccbbbbbbbbbbbbbbbbbbbb88888888ffffffffffffffff77ffaaaaaaaaaaffff77cccc77ffffffaa77cccc77aaaaaaaaffffaaaaaaaacccccccccccccccc
ccccccbbbbbbbbbbbbbbbbbbbb88888888ffffffffffffffff77ffaaaaaaaaaaffff77cccc77ffffffaa77cccc77aaaaaaaaffffaaaaaaaacccccccccccccccc
ccccccbbbbbbbbbbbbbbbbbbbbffffffffffffffffff77777777ffccaaaaaaaaffff77777777ff55ffff77777777aaaaaaaaffffaaaaaaaaaacccccccccccccc
ccccccbbbbbbbbbbbbbbbbbbbbffffffffffffffffff77777777ffccaaaaaaaaffff77777777ff55ffff77777777aaaaaaaaffffaaaaaaaaaacccccccccccccc
ccccbbbbbbbbbbbbbbbbbbffbbbb77777777ffffffff77cccc77ffccaaaaaaaaffffffffffffff55ffffffffffffaaaaaaaaffffaaaaaaaaaacccccccccccccc
ccccbbbbbbbbbbbbbbbbbbffbbbb77777777ffffffff77cccc77ffccaaaaaaaaffffffffffffff55ffffffffffffaaaaaaaaffffaaaaaaaaaacccccccccccccc
ccccbbbbbbbbbbbbbbbbbbffbbbb7777ccccffffffff77ccccffffccaaaaaaaaffffffffffffffffffffffffffffaaaaaaaaffaaaaaaaaaaaacccccccccccccc
ccccbbbbbbbbbbbbbbbbbbffbbbb7777ccccffffffff77ccccffffccaaaaaaaaffffffffffffffffffffffffffffaaaaaaaaffaaaaaaaaaaaacccccccccccccc
ccccbbbbbbbbbbbbbbbbbbffffbb7777ccccffffffffffffffffffccaaaaaaaaffffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaacccccccccccccc
ccccbbbbbbbbbbbbbbbbbbffffbb7777ccccffffffffffffffffffccaaaaaaaaffffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaacccccccccccccc
ccccccbbbbbbbbbbbbbbbbffffffffffffffffffffffffffffffffccaaaaaaaaffffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaacccccccccccccc
ccccccbbbbbbbbbbbbbbbbffffffffffffffffffffffffffffffffccaaaaaaaaffffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaacccccccccccccc
ccccccbbbbbbbbbbbbbbbbffffffffffffffffffffffffffffffffccaaaaaaaaffffffffffffffffffffeeffffffffaaaaaaaaaaaaaaaaaaaaaacccccccccccc
ccccccbbbbbbbbbbbbbbbbffffffffffffffffffffffffffffffffccaaaaaaaaffffffffffffffffffffeeffffffffaaaaaaaaaaaaaaaaaaaaaacccccccccccc
ccccccbbbbbbbbbbbbffffffffffffffffffffffffffffffffffffccaaaaaaaaffffffffffeeeeeeeeeeffffffffffaaaaaaaaaaaaaaaaaaaaaacccccccccccc
ccccccbbbbbbbbbbbbffffffffffffffffffffffffffffffffffffccaaaaaaaaffffffffffeeeeeeeeeeffffffffffaaaaaaaaaaaaaaaaaaaaaacccccccccccc
3333ccbbbbbbbbbbffffffffffffffffffffffffffffffffffffffccaaaaaaaaaaffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaacc3333333333
3333ccbbbbbbbbbbffffffffffffffffffffffffffffffffffffffccaaaaaaaaaaffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaacc3333333333
333333bbbbbbbbbbffffffffffffffffffffffeeeeffffffffffccccaaaaaaaaaaffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaa333333333333
333333bbbbbbbbbbffffffffffffffffffffffeeeeffffffffffccccaaaaaaaaaaffffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaa333333333333
333333bbbbbbbbbbbbffffffffffffffffffee7777eeffffffff3333aaaaaaaaaaaaffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaa333333333333
333333bbbbbbbbbbbbffffffffffffffffffee7777eeffffffff3333aaaaaaaaaaaaffffffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaa333333333333
333333bbbbbbbbbbbbbbffffffffffffffffee8888eeffffffff3333aaaaaaaaaaaaaaffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaaaa333333333333
333333bbbbbbbbbbbbbbffffffffffffffffee8888eeffffffff3333aaaaaaaaaaaaaaffffffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaaaa333333333333
333333bbbbbbbbbbbbbbbbffffffffffffffee8888eeffffffff3333aaaaaa33aaaaaaaaaaffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaaaaaa3333333333
333333bbbbbbbbbbbbbbbbffffffffffffffee8888eeffffffff3333aaaaaa33aaaaaaaaaaffffffffffffffffffaaaaaaaaaaaaaaaaaaaaaaaaaa3333333333
333333bbbbbbbbbbbbbbbbbbffffffffffffffeeeeffffffff333333aaaaaa33aaaaaaaaaaaaaaaaaaaaaaaaffffaaaaaaaaaaaaaaaaaaaaaaaaaa3333333333
333333bbbbbbbbbbbbbbbbbbffffffffffffffeeeeffffffff333333aaaaaa33aaaaaaaaaaaaaaaaaaaaaaaaffffaaaaaaaaaaaaaaaaaaaaaaaaaa3333333333
333333bbbbbbbbbbbbbbbbbbffffffffffffffffffffff333333333333aa333333aaaaaaaaaaaaaaaaaaaaaaffffaaaaaaaaffffffffffffaaaaaa3333333333
333333bbbbbbbbbbbbbbbbbbffffffffffffffffffffff333333333333aa333333aaaaaaaaaaaaaaaaaaaaaaffffaaaaaaaaffffffffffffaaaaaa3333333333
333333bbbbbbbbbbbbbbbbbbffffffffffff3333333333333333333333aa333333aaaaaaaaaaaaffffffffffffffffffffffffffffffffffffaaaa3333333333
333333bbbbbbbbbbbbbbbbbbffffffffffff3333333333333333333333aa333333aaaaaaaaaaaaffffffffffffffffffffffffffffffffffffaaaa3333333333
33333333bbbbbbbbbbbbbbbbbbffffffffffffffffff3333333333333333333333aaffffffffffffffffffffffffffffffffffffffffffffffffaa3333333333
33333333bbbbbbbbbbbbbbbbbbffffffffffffffffff3333333333333333333333aaffffffffffffffffffffffffffffffffffffffffffffffffaa3333333333
3333333333bbbbbbbbbbbbbbbbffffffffffffffffffffffff3333333333333333ffffffffffffffffffffffffffffffffffffffffffffffffffff3333333333
3333333333bbbbbbbbbbbbbbbbffffffffffffffffffffffff3333333333333333ffffffffffffffffffffffffffffffffffffffffffffffffffff3333333333
3333333333bbbbbbbbbbbbbbbbbbffffffffffffffffffffffff333333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333333
3333333333bbbbbbbbbbbbbbbbbbffffffffffffffffffffffff333333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333333
3333333333bbbbbbbbbbbbbbbbbbffffffffffffffffffffffff3333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333333
3333333333bbbbbbbbbbbbbbbbbbffffffffffffffffffffffff3333333333ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33333333
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888880000008800000088000000000000008800000000000000880000000000000088000000000000008800000000000000888888888888888888
88888888888888880000008800000088000000000000008800000000000000880000000000000088000000000000008800000000000000888888888888888888
88888888888888880077008800770088007777777777008800777700007700880077777777770088007777777777008800777777777700888888888888888888
88888888888888880077008800770088007777777777008800777700007700880077777777770088007777777777008800777777777700888888888888888888
88888888888888880077000000770088007700000077008800770077007700880077000000770088007777777777008800770000007700888888888888888888
88888888888888880077000000770088007700000077008800770077007700880077000000770088007777777777008800770000007700888888888888888888
88888888888888880077007700770088007700000077008800770000777700880077000000770088007700000000008800777777770000888888888888888888
88888888888888880077007700770088007700000077008800770000777700880077000000770088007700000000008800777777770000888888888888888888
88888888888888880000770077000088007777777777008800770000007700880077777777770088007777777777008800770000007700888888888888888888
88888888888888880000770077000088007777777777008800770000007700880077777777770088007777777777008800770000007700888888888888888888
88888888888888888800000000008888000000000000008800000088000000880000000000000088000000000000008800000088000000888888888888888888
88888888888888888800000000008888000000000000008800000088000000880000000000000088000000000000008800000088000000888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888880000000000000088000000000000008800000000000000888888888888888888888888888888888888888888
88888888888888888888888888888888888888880000000000000088000000000000008800000000000000888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077777777770088007777777777008800770000007700888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077777777770088007777777777008800770000007700888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077000000770088007700000077008800777777777700888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077000000770088007700000077008800777777777700888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077777777770088007700000077008800000000007700888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077777777770088007700000077008800000000007700888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077000000770088007777777777008800777777777700888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077000000770088007777777777008800777777777700888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077777777000088000000000000008800000000000000888888888888888888888888888888888888888888
88888888888888888888888888888888888888880077777777000088000000000000008800000000000000888888888888888888888888888888888888888888
88888888888888888888888888888888888888880000000000008888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888880000000000008888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000777777007777000077777700777777007777770000007777777700000000000000000000000000000000000000
00000000000000000000000000000000000000777777007777000077777700777777007777770000007777777700000000000000000000000000000000000000
00000000000000000000000000000000000000770077007700770077777700770000007700000000007700007700000000000000000000000000000000000000
00000000000000000000000000000000000000770077007700770077777700770000007700000000007700007700000000000000000000000000000000000000
00000000000000000000000000000000000000777777007777770077000000000077000000770000007700007700000000000000000000000000000000000000
00000000000000000000000000000000000000777777007777770077000000000077000000770000007700007700000000000000000000000000000000000000
00000000000000000000000000000000000000770000007700770077777700777777007777770000007777777700000000000000000000000000000000000000
00000000000000000000000000000000000000770000007700770077777700777777007777770000007777777700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
07070707070707070707070707070707080909090a090909090909090a0909090a0909090a0909090909090a09090909090909090909090a070707070707070707070707070707070707070707070707070707070707070707070707070707070707070707142020202020202020202020242424242424240909090909090909
07070707070707070707070707070707181919191a191919191919191a1919191a1919191a1919191919191a19191919191919191919191a070707070707070707070707070707070707070707070707070707070707070707070707070707070707070739242727272727272727272727242424242424241919191919191919
07070707070707070707070707070707282929292a292929292929292a2929292a2929292a2829292929292a29292929292929292929292a07070707070707070707070707070707070707070707070707070f070707070707070707070707070707073939242727272727272727272727242424242424242a2929292a292929
0707070707070707070707070707070707151607070707071516070707071516070715160707151607070707071516071516070715160707070707070707070707070707070707070707070707070707070707070707070d07070707070707070707393939242727272727272727272727242424242424240707151607071516
070707070e07070707070707070707070715160707070d0715160707070e15160707151607071516070707070d15160715160707151607070c0707073d3e070707070707070707070d070e07073d3e070707073d3e073d3e07070707070707070739393939242727272727272727272727242424242424240707151607071516
17171717171717171717170a07070707071516171717171715161717171715161717151617171516173517173515163515161717151617350a070707070707070708171717171717171717170a070707070707070707070707070707070707073939393939242727272727272727484927242424242424240707151607071516
19190b19191919191919111a073307070715161119113019151619111911090919191516190b0909191919193009091915160b19191919191a3d3e070707070707180b1905191905190519051a0707073d3e07070707070707070707071207393939393939242727272727272727585925242424242424240707151607071516
101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101037383831383838313a10101010101010101010103738383138383138383838383831313a101010202020202020202020202020202020202020202424242424241010101010101010
4041424344454647000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051525354555657000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626364656667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7071727374757677000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8081828384858687000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9091929394959697000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a0a1a2a3a4a5a6a7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b0b1b2b3b4b5b6b7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010f00001f3201f3251c3201c3251f3201f3251c3201f320366151f3201c3201c3251f3201f3251c3201c3251e3201e3251a3201a3251e3201e3251a3201e320366151e3201a3201a3251e3201e3251a3201a325
010f00000412004120366153661500120001203661500000041200412036615366150012000125366150000002120021203661536615001200012036615000000212002120366153661500120001253061500000
010f00003661500000306150000036615000003061500000306150000030615000003661500000306150000036615000003061500000366150000030615000003061500000306150000036615000003661500000
010f00003061500000041200412530615000000012000125000000000004120041253061500000306150000030615000000212002125306150000000120001250000000000021200212530615000003061500000
010f00001f3201f3251c3201c3251f3201f3251c3201f320366151f3201c3201c3251f3201f3251c3201c3251e3201e3251a3201a3251e3201e3251a3201e3203061500000306150000030615000003061500000
010f00000414004140366253662500140001403662500000041400414036625366250014000145366250000002140021403662536625001400014500140021403662500000366253662536625000003662500000
010f00003661500000306150000036615000003061500000306150000030615000003661500000306150000036615000003061500000366150000036615000000000000000000000000000000000003061500000
010f00003061500000041200412530615000000012000125000000000004120041253061500000306150000030615000000212002125306150000030615000000000000000000000000000000000000000000000
010f00001c3201c32519320193251c3201c325193201c320366151c32019320000001c3201c32519320193251e3201e3251a3201a3251e3201e3251a3201e320366151e3201a320000001e3201e3251a3201a325
010f00000012000120366153661501120011203661500000041200412036615366150112001125366150000002120021203661536615061200612036615000000912009120366153661506120061253061500000
010f00003061500000001200012530615000000112001125000000000004120041253061500000306150000030615000000212002125306150000006120061250000000000091200912530615000003061500000
010f00001c3201c32519320193251c3201c325193201c320366151c32019320000001c3201c32519320193251e3201e3251a3201a3251e3201e3251a3201e3203061500000306150000030615000003061500000
010f00000012000120366153661501120011203661500000071200712036615366150612006125306150000002120021203661536615001200012500120021203661500000366153661536615000003661500000
010f00003661500000306150000036615000003061500000306150000030615000003661500000366150000036615000003061500000366150000036615000000000000000000000000000000000003061500000
010f00003061500000001200012530615000000112001125000000000007120071253061500000306150000030615000000212002125306150000030615000000000000000000000000000000000000000000000
010100000d720227202572027720287202872025720227201f7201172004720027200072015720117200d72008720260002400024000020000300004000050002d00006000060000700006000060000100003000
000100002d0502a05028050280502a0502c0502d0502d0502d0502d0502d0502d0502d0502e0002e0002e00027000270003800034000000000000000000000000000000000000000000000000000000000000000
000100000f020100201102012020130201402014020150201702018020190201b0201d02020030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001c7501c7501c7501c7501c7501c7501c7501c7501c7501b7501775015750137501275011750107500f7500e7500e7500e7500f7500f75000000000000000000000000000000000000000000000000000
00010000267502675024750217501f7501f75020750217502175023750247502475023750217501e7501e7501f7502075020750207501f7501e7501c7501a7501875017750167501475013750127501175000000
__music__
01 00410243
00 04450647
00 00410243
00 04450647
00 0849024a
00 0b4c0d4e
00 0849024a
02 0b4c0d4e
