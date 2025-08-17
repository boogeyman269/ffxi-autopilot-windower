
local M = {
  settings = nil,
  last = {
    tick = 0, action = 0, ws = 0, heal = 0, follow = 0,
    flash = 0, provoke = 0, sentinel = 0, rampart = 0, bash = 0,
    reprisal = 0, enlight = 0, majesty = 0, cure = 0, invincible = 0,
    berserk = 0, defender = 0, warcry = 0, aggressor = 0,
  },
  hud = { handle = nil, last = 0 },
  opener = { target_id = nil, step = 0, started = 0 },
  vars = {
    no_top_hate_since = 0,
    cover_follow_until = 0, cover_follow_name = nil,
    last_pos = {x=nil,y=nil,t=0},
    last_target_id = nil, last_target_switch = 0,
  },
}
return M
