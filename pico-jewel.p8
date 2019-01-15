pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- helpers
function is_empty(arr)
  for key, value in pairs(arr) do
    return false
  end
  return true
end

-- states:
-- -1 - game over
--  0 - play - move cursor
--  1 - selected
--  2 - switch
--  3 - matching
--  4 - removing
--  5 - falling
--  6 - board filled - rematch
--
height = 7
width = 5
maxtime = 60

board = {}
clear_matches = {}
state = 0
step = 0
girl_frame = 7
score = 0
timer = 0
timeleft = 0

cursor = { frame=16, y=1, x=0 }
selected = {}

debug = ""

function create()
  local y = 0
  local x = 0

  for y=0, height do
    board[y] = {}

    for x=0, width do
      board[y][x] = flr(rnd(4)) + 1
    end
  end
end

function draw()
  local y = 0
  local x = 0

  for y=0, height do
    for x=0, width do
      spr(board[y][x], 8*x, 8*y)

      if not is_empty(clear_matches) and clear_matches[y][x] == 0 then
        spr(17, 8*x, 8*y)
      end
    end
  end
end

function copy_board()
  local copy = {}
  for y, row in pairs(board) do
    copy[y] = {}
    for x, value in pairs(row) do
      copy[y][x] = value
    end
  end
  return copy
end

function check_row(tmp_board, count, color, x, y)
  if tmp_board[y] == nil or tmp_board[y][x] != color then
    return 0
  end

  tmp_board[y][x] = -1

  return check_row(tmp_board, count, color, x + 1, y) +
         check_row(tmp_board, count, color, x - 1, y) + 1
end

function check_col(tmp_board, count, color, x, y)
  if tmp_board[y] == nil or tmp_board[y][x] != color then
    return 0
  end

  tmp_board[y][x] = -1

  return check_col(tmp_board, count, color, x, y + 1) +
         check_col(tmp_board, count, color, x, y - 1) + 1
end

function remove_matches(board, remove_board)
  for y, row in pairs(remove_board) do
    for x, color in pairs(row) do
      if color == 0 then
        board[y][x] = 0
        score += 10
      end
    end
  end
end

function remove_all_matches()
  clear_matches = copy_board()
  girl_frame = 13

  for y = 0, height do
    for x = 0, width do
      if match_at(x, y) then
        state = 4
        step = 1
        return false
      end
    end
  end

  return true
end

function add_to_clear(board)
  for y, row in pairs(board) do
    for x, color in pairs(row) do
      if color == -1 and clear_matches[y] != nil then
        clear_matches[y][x] = 0
      end
    end
  end
end

function fill_empty()
  for y = height, 0, -1 do
    for x = 0, width do
      if board[y][x] == 0 then
        if y != 0 then
          board[y][x] = board[y-1][x]
          board[y-1][x] = 0
        else
          board[y][x] = flr(rnd(4)) + 1
        end
      end
    end
  end
end

function is_full()
  for y = 0, height do
    for x = 0, width do
      if board[y][x] == 0 then
        return false
      end
    end
  end
  return true
end

function switch()
  sfx(0)
  local tmp = board[cursor.y][cursor.x]
  board[cursor.y][cursor.x] = board[selected.y][selected.x]
  board[selected.y][selected.x] = tmp
end

function match_at(x, y)
  local color = board[y][x]
  local row_board = copy_board()
  local col_board = copy_board()
  local has_matches = false

  row_matches = check_row(row_board, 0, color, x, y)
  col_matches = check_col(col_board, 0, color, x, y)

  if col_matches > 2 then
    add_to_clear(col_board)
    has_matches = true
  end

  if row_matches > 2 then
    add_to_clear(row_board)
    has_matches = true
  end

  return has_matches
end

function restart()
  timer = time()
  create()
  clear_matches = {}
  state = 0
  cursor = { frame=16, y=1, x=0 }
  score = 0
end

function _init()
  poke(0x5f2c, 3)
  -- mouse
  -- poke(0x5f2d, 1)
  music(0)
  restart()
  state = -1
end

function _update()
  if state == -1 then
    cursor = { frame=16, y=1, x=0 }
    if btnp(5) then
      restart()
    end
    return
  end

  step += 1
  timeleft = maxtime - flr(time() - timer)

  if btnp(0) then
    cursor.x -= 1

    if cursor.x == -1 then
      cursor.x = width
    end
  end

  if btnp(1) then
    cursor.x += 1

    if cursor.x == (width + 1) then
      cursor.x = 0
    end
  end

  if btnp(2) then
    cursor.y -= 1

    if cursor.y == -1 then
      cursor.y = height
    end
  end

  if btnp(3) then
    cursor.y += 1

    if cursor.y == (height + 1) then
      cursor.y = 0
    end
  end

  if btnp(4) then
    if is_empty(selected) then
      clear_matches = copy_board()
      selected = { x=cursor.x, y=cursor.y }
      cursor.frame = 17
    else
      switch()

      match_at(cursor.x, cursor.y)
      match_at(selected.x, selected.y)

      girl_frame = 11
      -- init removal state
      state = 4
      step = 1

      selected = {}
      cursor.frame = 16
    end
  end

  if step % 10 == 0 and state == 4 then
    state = 5
    remove_matches(board, clear_matches)
    clear_matches = {}
  end

  if step % 4 == 0 and state == 5 then
    fill_empty()

    if is_full() then
      if remove_all_matches() then
        state = 0
      else
        sfx(1)
      end
    end
  end

  if step % 20 == 0 then
    if state == 0 then
      if girl_frame == 7 then
        girl_frame = 9
      else
        girl_frame = 7
      end
    end
  end

  if timeleft == 0 then
    state = -1
  end
end

function _draw()
  cls()

  local right = (width + 1) * 8
  local bottom = (height - 2) * 8

  color(7)
  -- rectfill(0, 0, right, (height+1)*8)
  rectfill(right, 0, right + 16, bottom - 1)
  line(right, 0, right, bottom + 23)
  spr(girl_frame, right + 1, bottom, 2, 3)
  line(right+17, 0, right+17, bottom + 23)
  color(14)
  print("scr:", right+1, 1)
  print(score, right+1, 8)

  print("tim:", right+1, 20)
  print(timeleft, right+1, 28)


  -- draw mouse
  -- spr(0,stat(32)-1,stat(33)-1)

  spr(cursor.frame, cursor.x * 8, cursor.y * 8)
  draw()

  -- cursor
  if state == 0 then
    -- selected
    if not is_empty(selected) then
      spr(cursor.frame, selected.x * 8, selected.y * 8)
    end
  end

  if state == -1 then
    rectfill(0, 0, right-1, 7)
    rectfill(0, (height/2)*8+4, right-1, (height+1)*8)
    color(7)
    print("pico jewel", 1, 1)
    print("game over", 1, (height/2)*8+5)
    print("press \151", 1, 58)
  end

  print(debug, 20, 20)
end

__gfx__
00000000000000000000000000000000000000000000000000000000777770000777777777777000077777777777700007777777777770000777777700000000
00000000008888000099990000dddd00003333000044440000550000770000780000077777000078000007777700007800000777770000780000077700000000
00000000087eee80097aaa900d7cccd0037bbb30047fff400576000070eee0880eeee07770eee0880eeee07770eee0880eeee07770eee0880eeee07700000000
0000000008eeee8009aaaa900dccccd003bbbb3004ffff4005665500000ee0880eee0007000ee0880eee0007000ee0880eee0007000ee0880eee000700000000
0000000008eeee8009aaaa900dccccd003bbbb3004ffff40056666000a90008200009a070a90008200009a070a90008200009a070a90008200009a0700000000
0000000008eee88009aaa9900dcccdd003bbb33004fff440056666500aaaa0220aaaaa070aaaa0220aaaaa0707aaa0220aaaaa070aaaa0220aaaa70700000000
00000000008888000099990000dddd000033330000444400005566500a00000000000a070a00000000000a070a00000000000a070a00000000000a0700000000
00000000000000000000000000000000000000000000000000006550000f22fff22f0007000f22fff22f0007000f22fff22f0007000f22fff22f000700000000
077777700aaaaaa000000000000000000000000000000000000055500e0f72fff72f0e070e0f72fff72f0e070e0f72fff72f0e070e0f72fff72f0e0700000000
77000077aa0000aa00000000000000000000000000000000000000000e0f88fff88f0e070e0f88fff88f0e070e0f88fff88f0e070e0f88fff88f0e0700000000
70000007a000000a00000000000000000000000000000000000000000e0fffffffff0e070e0fffffffff0e070e0fffffffff0e070e0fffffffff0e0700000000
70000007a000000a00000000000000000000000000000000000000000e0feffff2ef0e070e0feffff2ef0e070e0fefffffef0e070e0fefffffef0e0700000000
70000007a000000a00000000000000000000000000000000000000000e0fff222ff0ee070e0fff222ff0ee070e0fff222ff0ee070e0ff22222f0000000000000
70000007a000000a00000000000000000000000000000000000000000ee0fffffff0ee0700e0fffffff0ee0000e0ff222ff0ee000000ff222ff00ff000000000
77000077aa0000aa00000000000000000000000000000000000000000eee0000000eee0770ee0000000eeee070ee0000000eeee00ff00fffff0e0ff000000000
077777700aaaaaa000000000000000000000000000000000000000000eeee00000eeee0770eee00000eeeee070eee00000eeeee00ff0e00000ee000000000000
77777777aaaaaaaa00000000000000000000000000000000000000000eeee0fff0eeee070eeee0fff0eeee000eeee0fff0eeee000000e0fff0e0eee000000000
77000077aa0000aa00000000000000000000000000000000000000000e0000fff0000e070e0000fff0000e000e0000fff0000e000ee000fff000ee0000000000
70000007a000000a0000000000000000000000000000000000000000000090fff09000070000a0fff0900007000090fff09000070eee0900090eee0700000000
70000007a000000a000000000000000000000000000000000000000000e090000090ee0770e090000090ee0770e090000090ee0700ee09a9990ee00700000000
70000007a000000a000000000000000000000000000000000000000070e099999990ee0770e0999999a0ee0770e09a999990ee07700e0000000e007700000000
70000007a000000a000000000000000000000000000000000000000070e000000000ee0770e000000000ee0770e000000000ee077700e08820ee077700000000
77000077aa0000aa000000000000000000000000000000000000000070eee08820eeee0770eee08880eeee0770eee08880eeee077770e00000ee077700000000
77777777aaaaaaaa000000000000000000000000000000000000000070eee00000eeee0770eee00000eeee0770eee00000eeee077770eeeeeeee077700000000
__label__
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
ee777777ee777777eeee7777eeee7777eeeeeeeeee777777ee777777ee77ee77ee777777ee77eeeeeeeeeeeeeeeeeeee7777eeee7777eeee77eeeeee77777777
ee777777ee777777eeee7777eeee7777eeeeeeeeee777777ee777777ee77ee77ee777777ee77eeeeeeeeeeeeeeeeeeee7777eeee7777eeee77eeeeee77777777
ee77ee77eeee77eeee77eeeeee77ee77eeeeeeeeeeee77eeee77eeeeee77ee77ee77eeeeee77eeeeeeeeeeeeeeeeeeee77ee777777ee777777ee77ee7777ee77
ee77ee77eeee77eeee77eeeeee77ee77eeeeeeeeeeee77eeee77eeeeee77ee77ee77eeeeee77eeeeeeeeeeeeeeeeeeee77ee777777ee777777ee77ee7777ee77
ee777777eeee77eeee77eeeeee77ee77eeeeeeeeeeee77eeee7777eeee77ee77ee7777eeee77eeeeeeeeeeeeeeeeeeee77eeeeee77ee777777eeee7777777777
ee777777eeee77eeee77eeeeee77ee77eeeeeeeeeeee77eeee7777eeee77ee77ee7777eeee77eeeeeeeeeeeeeeeeeeee77eeeeee77ee777777eeee7777777777
ee77eeeeeeee77eeee77eeeeee77ee77eeeeeeeeeeee77eeee77eeeeee777777ee77eeeeee77eeeeeeeeeeeeeeeeeeee777777ee77ee777777ee77ee7777ee77
ee77eeeeeeee77eeee77eeeeee77ee77eeeeeeeeeeee77eeee77eeeeee777777ee77eeeeee77eeeeeeeeeeeeeeeeeeee777777ee77ee777777ee77ee7777ee77
ee77eeeeee777777eeee7777ee7777eeeeeeeeeeee7777eeee777777ee777777ee777777ee777777eeeeeeeeeeeeeeee77eeee777777eeee77ee77ee77777777
ee77eeeeee777777eeee7777ee7777eeeeeeeeeeee7777eeee777777ee777777ee777777ee777777eeeeeeeeeeeeeeee77eeee777777eeee77ee77ee77777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
00777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000077eeeeee777777777777777777777777
00777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000077eeeeee777777777777777777777777
77778888888877770000333333330000000033333333000000008888888800000000888888880000000099999999000077ee77ee777777777777777777777777
77778888888877770000333333330000000033333333000000008888888800000000888888880000000099999999000077ee77ee777777777777777777777777
778877eeeeee8877003377bbbbbb3300003377bbbbbb3300008877eeeeee8800008877eeeeee8800009977aaaaaa990077ee77ee777777777777777777777777
778877eeeeee8877003377bbbbbb3300003377bbbbbb3300008877eeeeee8800008877eeeeee8800009977aaaaaa990077ee77ee777777777777777777777777
7788eeeeeeee88770033bbbbbbbb33000033bbbbbbbb33000088eeeeeeee88000088eeeeeeee88000099aaaaaaaa990077ee77ee777777777777777777777777
7788eeeeeeee88770033bbbbbbbb33000033bbbbbbbb33000088eeeeeeee88000088eeeeeeee88000099aaaaaaaa990077ee77ee777777777777777777777777
7788eeeeeeee88770033bbbbbbbb33000033bbbbbbbb33000088eeeeeeee88000088eeeeeeee88000099aaaaaaaa990077eeeeee777777777777777777777777
7788eeeeeeee88770033bbbbbbbb33000033bbbbbbbb33000088eeeeeeee88000088eeeeeeee88000099aaaaaaaa990077eeeeee777777777777777777777777
7788eeeeee8888770033bbbbbb3333000033bbbbbb3333000088eeeeee8888000088eeeeee8888000099aaaaaa99990077777777777777777777777777777777
7788eeeeee8888770033bbbbbb3333000033bbbbbb3333000088eeeeee8888000088eeeeee8888000099aaaaaa99990077777777777777777777777777777777
77778888888877770000333333330000000033333333000000008888888800000000888888880000000099999999000077777777777777777777777777777777
77778888888877770000333333330000000033333333000000008888888800000000888888880000000099999999000077777777777777777777777777777777
00777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777777777777777777777777
00777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777777777777777777777777777
000033333333000000009999999900000000dddddddd00000000dddddddd00000000888888880000000099999999000077777777777777777777777777777777
000033333333000000009999999900000000dddddddd00000000dddddddd00000000888888880000000099999999000077777777777777777777777777777777
003377bbbbbb3300009977aaaaaa990000dd77ccccccdd0000dd77ccccccdd00008877eeeeee8800009977aaaaaa990077777777777777777777777777777777
003377bbbbbb3300009977aaaaaa990000dd77ccccccdd0000dd77ccccccdd00008877eeeeee8800009977aaaaaa990077777777777777777777777777777777
0033bbbbbbbb33000099aaaaaaaa990000ddccccccccdd0000ddccccccccdd000088eeeeeeee88000099aaaaaaaa990077777777777777777777777777777777
0033bbbbbbbb33000099aaaaaaaa990000ddccccccccdd0000ddccccccccdd000088eeeeeeee88000099aaaaaaaa990077777777777777777777777777777777
0033bbbbbbbb33000099aaaaaaaa990000ddccccccccdd0000ddccccccccdd000088eeeeeeee88000099aaaaaaaa990077eeeeee77eeeeee77eeeeee77777777
0033bbbbbbbb33000099aaaaaaaa990000ddccccccccdd0000ddccccccccdd000088eeeeeeee88000099aaaaaaaa990077eeeeee77eeeeee77eeeeee77777777
0033bbbbbb3333000099aaaaaa99990000ddccccccdddd0000ddccccccdddd000088eeeeee8888000099aaaaaa9999007777ee777777ee7777eeeeee7777ee77
0033bbbbbb3333000099aaaaaa99990000ddccccccdddd0000ddccccccdddd000088eeeeee8888000099aaaaaa9999007777ee777777ee7777eeeeee7777ee77
000033333333000000009999999900000000dddddddd00000000dddddddd0000000088888888000000009999999900007777ee777777ee7777ee77ee77777777
000033333333000000009999999900000000dddddddd00000000dddddddd0000000088888888000000009999999900007777ee777777ee7777ee77ee77777777
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777ee777777ee7777ee77ee7777ee77
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777ee777777ee7777ee77ee7777ee77
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777ee7777eeeeee77ee77ee77777777
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777ee7777eeeeee77ee77ee77777777
00003333333300000000dddddddd0000000088888888000000003333333300000000888888880000000088888888000077777777777777777777777777777777
00003333333300000000dddddddd0000000088888888000000003333333300000000888888880000000088888888000077777777777777777777777777777777
003377bbbbbb330000dd77ccccccdd00008877eeeeee8800003377bbbbbb3300008877eeeeee8800008877eeeeee880077777777777777777777777777777777
003377bbbbbb330000dd77ccccccdd00008877eeeeee8800003377bbbbbb3300008877eeeeee8800008877eeeeee880077777777777777777777777777777777
0033bbbbbbbb330000ddccccccccdd000088eeeeeeee88000033bbbbbbbb33000088eeeeeeee88000088eeeeeeee880077777777777777777777777777777777
0033bbbbbbbb330000ddccccccccdd000088eeeeeeee88000033bbbbbbbb33000088eeeeeeee88000088eeeeeeee880077777777777777777777777777777777
0033bbbbbbbb330000ddccccccccdd000088eeeeeeee88000033bbbbbbbb33000088eeeeeeee88000088eeeeeeee880077eeeeee777777777777777777777777
0033bbbbbbbb330000ddccccccccdd000088eeeeeeee88000033bbbbbbbb33000088eeeeeeee88000088eeeeeeee880077eeeeee777777777777777777777777
0033bbbbbb33330000ddccccccdddd000088eeeeee8888000033bbbbbb3333000088eeeeee8888000088eeeeee88880077ee77ee777777777777777777777777
0033bbbbbb33330000ddccccccdddd000088eeeeee8888000033bbbbbb3333000088eeeeee8888000088eeeeee88880077ee77ee777777777777777777777777
00003333333300000000dddddddd0000000088888888000000003333333300000000888888880000000088888888000077ee77ee777777777777777777777777
00003333333300000000dddddddd0000000088888888000000003333333300000000888888880000000088888888000077ee77ee777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077ee77ee777777777777777777777777
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077ee77ee777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77eeeeee777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77eeeeee777777777777777777777777
eeee7777ee777777ee777777ee777777eeeeeeeeeeee7777ee77ee77ee777777ee777777eeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeee7777ee777777ee777777ee777777eeeeeeeeeeee7777ee77ee77ee777777ee777777eeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
ee77eeeeee77ee77ee777777ee77eeeeeeeeeeeeee77ee77ee77ee77ee77eeeeee77ee77eeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
ee77eeeeee77ee77ee777777ee77eeeeeeeeeeeeee77ee77ee77ee77ee77eeeeee77ee77eeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
ee77eeeeee777777ee77ee77ee7777eeeeeeeeeeee77ee77ee77ee77ee7777eeee7777eeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
ee77eeeeee777777ee77ee77ee7777eeeeeeeeeeee77ee77ee77ee77ee7777eeee7777eeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
ee77ee77ee77ee77ee77ee77ee77eeeeeeeeeeeeee77ee77ee777777ee77eeeeee77ee77eeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
ee77ee77ee77ee77ee77ee77ee77eeeeeeeeeeeeee77ee77ee777777ee77eeeeee77ee77eeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
ee777777ee77ee77ee77ee77ee777777eeeeeeeeee7777eeeeee77eeee777777ee77ee77eeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
ee777777ee77ee77ee77ee77ee777777eeeeeeeeee7777eeeeee77eeee777777ee77ee77eeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777777777777777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777700000000777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777777777700000000777777777777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777700000000778800000000007777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77777700000000778800000000007777
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700eeeeee00888800eeeeeeee0077
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700eeeeee00888800eeeeeeee0077
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77000000eeee00888800eeeeee000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77000000eeee00888800eeeeee000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700aa9900000088220000000099aa00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700aa9900000088220000000099aa00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700aaaaaaaa00222200aaaaaaaaaa00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700aaaaaaaa00222200aaaaaaaaaa00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700aa0000000000000000000000aa00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700aa0000000000000000000000aa00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77000000ff2222ffffff2222ff000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77000000ff2222ffffff2222ff000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ff7722ffffff7722ff00ee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ff7722ffffff7722ff00ee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ff8888ffffff8888ff00ee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ff8888ffffff8888ff00ee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ffffffffffffffffff00ee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ffffffffffffffffff00ee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ffeeffffffff22eeff00ee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ffeeffffffff22eeff00ee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ffffff222222ffff00eeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00ffffff222222ffff00eeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700eeee00ffffffffffffff00eeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700eeee00ffffffffffffff00eeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700eeeeee00000000000000eeeeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700eeeeee00000000000000eeeeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700eeeeeeee0000000000eeeeeeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700eeeeeeee0000000000eeeeeeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700eeeeeeee00ffffff00eeeeeeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700eeeeeeee00ffffff00eeeeeeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00000000ffffff00000000ee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee7700ee00000000ffffff00000000ee00
ee777777ee777777ee777777eeee7777eeee7777eeeeeeeeeeee7777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77000000009900ffffff009900000000
ee777777ee777777ee777777eeee7777eeee7777eeeeeeeeeeee7777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee77000000009900ffffff009900000000
ee77ee77ee77ee77ee77eeeeee77eeeeee77eeeeeeeeeeeeee7777ee77ee7777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee770000ee009900000000009900eeee00
ee77ee77ee77ee77ee77eeeeee77eeeeee77eeeeeeeeeeeeee7777ee77ee7777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee770000ee009900000000009900eeee00
ee777777ee7777eeee7777eeee777777ee777777eeeeeeeeee777777ee777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700ee009999999999999900eeee00
ee777777ee7777eeee7777eeee777777ee777777eeeeeeeeee777777ee777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700ee009999999999999900eeee00
ee77eeeeee77ee77ee77eeeeeeeeee77eeeeee77eeeeeeeeee7777ee77ee7777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700ee000000000000000000eeee00
ee77eeeeee77ee77ee77eeeeeeeeee77eeeeee77eeeeeeeeee7777ee77ee7777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700ee000000000000000000eeee00
ee77eeeeee77ee77ee777777ee7777eeee7777eeeeeeeeeeeeee7777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700eeeeee0088882200eeeeeeee00
ee77eeeeee77ee77ee777777ee7777eeee7777eeeeeeeeeeeeee7777777777eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700eeeeee0088882200eeeeeeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700eeeeee0000000000eeeeeeee00
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee777700eeeeee0000000000eeeeeeee00

__sfx__
0101000026550215501c5501c5501c5501f5502155021550025001f50002500205001f5001f500055000450004500045000550005500055000450004500045000450005500055000650006500065000850004500
01010000025500455006550095500a5500c5500d5500f55011550145501555016550185501a5501d5501f55020550225502455004500075000150006500035000750003500075000350003500025000250003500
011000000c0320c0000c0210c0310c0200c0010c0320c0220c0020c0320c0210c0010c0300c0210c0020c0320c0220c0020c0320c0220c0000c0320c0220c0020c0320c0220c0320c0220c0000c0320c0220c002
01080000114501145011440114401173111731117121171213450134501343013430137211372113712137120c4500c4500c4400c4400c7310c7310c7120c7120e4500e4500e4300e4300e7210e7210e7120e712
010800000c4500c4500c4400c4400c7310c7310c7120c7120f4500f4500f4300f4300f7210f7210f7120f71211450114501144011440117311173111712117120e4500e4500e4300e4300e7210e7210e7120e712
011000000c0530c0530c3030c3030c0530c0530c0030c0030c0530c0530c4030c0530c3030c2030c0530c2030c0530c0530c3030c3030c0530c0530c0030c0030c0530c0530c4030c0530c3030c2030c0530c203
011000000e0000e0000e0400e0200e0100e0000e0400e0200e0100e0000e0400e0200e0100e0000e0400e0200e0000e0000e0400e0200e0100e0000e0400e0200e0100e0000e0400e0200e0100e0000e0400e020
011000000c7500c7400c7210c711137501374013721137110f7500f7400f7210f7110e7500e7400e7210e7110c7500c7400c7210c7110e7500e7400e7210e711117501174011721117110c7500c7400c7210c711
01100000137501374013721137110e7500e7400e7210e711147501474014721147110c7500c7400c7210c711147501474014721147110e7500e7400e7210e711137501374013721137110c7500c7400c7210c711
011000000c0450e04510045110550e0551004511045130451005511045100550c0450e05510045110550c04511055100451105515045130551104510055150451005511045100550c0450e05510045110550c045
01100000111250c1250c125111250c1250c125111250c125111250c1250c125111250c1250c125111250c125111250c1250c125111250c1250c125111250c125111250c1250c125111250c1250c125111250c125
__music__
00 4905464a
00 49460509
00 47490509
00 440a0509
02 410a0509
