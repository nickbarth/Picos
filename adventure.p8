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
  
  print(debug)
end

-->8
-- menu
-->8
-- game

function game_init()
  step=0
  gravity=0.3
  friction=0.85
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

player = {
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
pig=-1
rock=32
bolder=-1
fish=-1

function add_enemy(x,y,etype)
  local enemy={
    et=etype,
    f=etype,
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
  if etype==bee then
    enemy.dx=-0.5
    enemy.angle=0.3
  end
  
  add(enemies,enemy)
end

function enemy_init()
  for y=0,8 do
    for x=0,32 do
      local et=mget(x,y)
      if et==snail then
        add_enemy(x*8,y*8,snail)
        mset(x,y,25) -- grass
      elseif et==rock then
        add_enemy(x*8,y*8,rock)
        mset(x,y,25)
      elseif et==bee then
   					add_enemy(x*8,y*8,bee)
   					mset(x,y,23)
      end
    end
  end
end

function enemy_update()
  for enemy in all(enemies) do
    if enemy_wait(enemy) then
      -- no update
    elseif enemy.et==snail then
      snail_update(enemy)
    elseif enemy.et==rock then
      rock_update(enemy)
    elseif enemy.et==bee then
      bee_update(enemy)
    end
  end
end

function enemy_wait(self)
  return cam.x+63<self.x
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
  
  if self.dead then
    enemy_dead(self)
    return
  end
  
		if step%50 == 0 then
		  self.x-=1
		  self.cf=(self.cf+1)%2
		end
end

function rock_update(self)
  enemy_attack(self)
end

function bee_update(self)
  enemy_hit(self)
  enemy_attack(self)

  if self.dead then
    enemy_dead(self)
    return
  end
    
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
egg=1
axe=2
statue=3

function add_objects(x,y)
  local object={
    f=51,
    cf=0,
    x=x,
    y=y
  }
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
000000000aaaaaa00aaaaaa000000000333333330044999999994400ccccccccb333333bb333333bb333333b0003300000000000000000000000000000000000
00000000aaaaaaa0aaaaaaa00aaaaaa0bb9bb9bb0044999999994400cccccccc333bbbb33bbbbbb33bbbb3330033330000000000000000000000000000000000
00700700aaafcf00aaafcf00aaaaaaa0b999999b0044999999994400cccccccc33bbbbbbbbbbbbbbbbbbbb330999999000000000000000000000000000000000
00077000aaffcf00aaffcf00aaafcf00999999990044999999994400cccccccc3bbbbbbbbbbbbbbbbbbbbbb30999999000000000000000000000000000000000
000770000ffffe000ffffe00aaffcf00944444490044999999994400cccccccc3bbbbbbbbbbbbbbbbbbbbbb30099990000000000000000000000000000000000
00700700fffffff00ffff0000ffffe00444444440044999999994400cccccccc3bbbbbbbbbbbbbbbbbbbbbb30099990000000000000000000000000000000000
000000000333300003f3300003333ff0444444440044999999994400cccccccc3bbbbbbbbbbbbbbbbbbbbbb30009900000000000000000000000000000000000
00000000f0000f000f00f0000f00f000444444440044999999994400ccccccccb3bbbbbbbbbbbbbbbbbbbb3b0000000000000000000000000000000000000000
33333333000000000000000006666660000000004499999999999944c333333cb3bbbbbbbbbbbbbbbbbbbb3bb333333bb333333bb333333b0000000000000000
bbbbbbbb0000000000000000677777760066660044999999999999443bbbbbb33bbbbbbbbbbbbbbbbbbbbbb33333333333333333333333330000000000000000
b444444b000000000008888067777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb33333333333333333333333330000000000000000
44444444000888800028222867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb33333333333333333333333330000000000000000
44444444208822280282888867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb33333333333333333333333330000000000000000
4f444444028288880282828867777776067777604499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb33333333333333333333333330000000000000000
44444f4402828288dd82282867777776006666004499999999999944bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb33333333333333333333333330000000000000000
44444444dd822828dd88888806666660000000004499999999999944bbbbbbbbb3bbbbbbbbbbbbbbbbbbbb3b3333333b3333333b3333333b0000000000000000
00000000003333000033330000000000000000004449999999999444c333333cb3bbbbbbbbbbbbbbbbbbbb3b0006000000006000000000000000000000000000
000000000323333003233330000000000000000044499999999994443bbbbbb33bbbbbbbbbbbbbbbbbbbbbb30066600000066600005000000000050000000000
00555500083333300833333000000000000660004449999999999444bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb30666660000666660055506000060555000000000
05666650000333300003333000000000006776004449999999999444bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb36666500000056666005556600665550000000000
05666650003330000033300000000000006776004449999999999444bbbbbbbb3bbbbbbbbbbbbbbbbbbbbbb30665550000555660000566666666500000000000
05666650033300000333000000000000000660004449999999999444bbbbbbbb33bbbbbbbbbbbbbbbbbbbb330060555005550600006666600666660000000000
03336630033303330333330000000000000000004449999999999444bbbbbbbb333bbbbbbbbbbbbbbbbbb3330000050000500000000666000066600000000000
33333333003333300033333300000000000000004449999999999444bbbbbbbb3333333333333333333333330000000000000000000060000006000000000000
00000000000000000000000000000000000000000999077709990666000000000000000000000000000000000000000000000000000000000000000000000000
0000000000dddd000000000000000000000000009999966699999ddd000000000000000000000000000000000000000000000000000000000000000000000000
00000000055dd550000000000666666006666660959999dd95999966000000000000000000000000000000000000000000000000000000000000000000000000
000000000dddddd0000000006777777667767776aaa99900aaa99966000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddeedd000000000677777766777677600099477000994dd000000000000000000000000000000000000000000000000000000000000000000000000
000000000ddeedd00000000067777776677677760099446600994400000000000000000000000000000000000000000000000000000000000000000000000000
000000000dddddd0000000006ffffff66fff6ff609944ddd09944000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d0dd0d00000000006666660066666606ddd00006ddd0000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0909190a1919081919081919190a070707070707070707070707070707080909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
191919191919191919191919191a070707070707070707070707070707181919000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
282928282a2a181a282829292a2a070707070707070707070707070707282929000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516071516071516070715160707070707070707070707070707070707071516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516071516071516070715160707070707070707070707070707070707071516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516171516351516171715161717171717171717171717171717171717351516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1516191516191516191915161919191919111919111919111920191919191516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
