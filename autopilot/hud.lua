
local store = require('autopilot.store')
local util  = require('autopilot.util')
local texts = require('texts')

local M = {}

local function hate_info()
  local tt = windower.ffxi.get_mob_by_target('tt')
  if not tt or not tt.name then return 0.0, '(none)' end
  local mep = util.me()
  if mep and mep.name and tt.name:lower() == mep.name:lower() then return 1.0, 'YOU' end
  if util.find_party_member(tt.name) then return 0.7, tt.name end
  return 0.3, tt.name
end

local function render_bar(level, width)
  width = width or 20
  if level < 0 then level = 0 elseif level > 1 then level = 1 end
  local filled = math.floor(level * width + 0.5)
  return '['..string.rep('█', filled)..string.rep('·', width - filled)..']'
end

local function cs(r,g,b) return string.char(92)..'cs('..r..','..g..','..b..')' end
local function cr() return string.char(92)..'cr' end
local function color_for_level(x)
  if x >= 0.99 then return 50,220,90
  elseif x >= 0.70 then return 255,210,60
  else return 255,120,80 end
end
local function colorize_bar(level, width)
  local r,g,b = color_for_level(level)
  local bar = render_bar(level, width)
  local s = store.settings
  return (s.hud and s.hud.color) and (cs(r,g,b)..bar..cr()) or bar
end

local function spell_cd_left(name)
  local s = util.find_spell(name); if not s then return nil end
  local rec = windower.ffxi.get_spell_recasts() or {}
  local r = rec[s.id]; if r and r > 0 then return r end
  return nil
end
local function ja_cd_left(name)
  local a = util.find_ja(name); if not a then return nil end
  local rec = windower.ffxi.get_ability_recasts() or {}
  local r = rec[a.recast_id or -1]; if r and r > 0 then return r end
  return nil
end
local function approx_left(key, cd, now_t)
  local last_t = store.last[key] or 0
  local left = (cd or 0) - (now_t - last_t)
  if left < 0 then left = 0 end
  return left
end
local function cd_token(label, left, full, width)
  full = math.max(full or 1, 1)
  local ratio_ready = 1 - math.min(left/full, 1)
  local bar = colorize_bar(ratio_ready, width or 8)
  local secs = left > 0 and (('%ds'):format(math.ceil(left))) or 'READY'
  return ('%s%s %s'):format(bar, label, secs)
end
local function build_cooldown_line(now_t)
  local s = store.settings
  if not (s.hud and s.hud.cooldowns) then return nil end
  local out = {}
  if s.pld and s.pld.use_flash then
    local left = spell_cd_left('Flash') or approx_left('flash', s.pld.flash_cd or 25, now_t); table.insert(out, cd_token('Fl', left, s.pld.flash_cd or 25, s.hud.cd_width))
  end
  if s.pld and s.pld.use_provoke then
    local left = ja_cd_left('Provoke') or approx_left('provoke', s.pld.provoke_cd or 30, now_t); table.insert(out, cd_token('Pr', left, s.pld.provoke_cd or 30, s.hud.cd_width))
  end
  if s.pld and s.pld.use_shield_bash then
    local left = ja_cd_left('Shield Bash') or approx_left('bash', s.pld.shield_bash_cd or 45, now_t); table.insert(out, cd_token('Ba', left, s.pld.shield_bash_cd or 45, s.hud.cd_width))
  end
  if s.pld and s.pld.use_sentinel then
    local left = ja_cd_left('Sentinel') or approx_left('sentinel', s.pld.sentinel_cd or 300, now_t); table.insert(out, cd_token('Se', left, s.pld.sentinel_cd or 300, s.hud.cd_width))
  end
  if s.pld and s.pld.use_rampart then
    local left = ja_cd_left('Rampart') or approx_left('rampart', s.pld.rampart_cd or 300, now_t); table.insert(out, cd_token('Ra', left, s.pld.rampart_cd or 300, s.hud.cd_width))
  end
  if s.pld and s.pld.keep_majesty then
    local left = ja_cd_left('Majesty') or approx_left('majesty', s.pld.majesty_cd or 60, now_t); table.insert(out, cd_token('Mj', left, s.pld.majesty_cd or 60, s.hud.cd_width))
  end
  if s.pld and s.pld.keep_reprisal then
    local left = spell_cd_left('Reprisal') or approx_left('reprisal', s.pld.reprisal_cd or 60, now_t); table.insert(out, cd_token('Rp', left, s.pld.reprisal_cd or 60, s.hud.cd_width))
  end
  if s.pld and s.pld.keep_enlight then
    local left = spell_cd_left('Enlight') or approx_left('enlight', s.pld.enlight_cd or 240, now_t); table.insert(out, cd_token('En', left, s.pld.enlight_cd or 240, s.hud.cd_width))
  end
  if s.war and s.war.enable then
    if s.war.use_warcry then local left = ja_cd_left('Warcry') or approx_left('warcry', s.war.warcry_cd or 300, now_t); table.insert(out, cd_token('Wc', left, s.war.warcry_cd or 300, s.hud.cd_width)) end
    if s.war.use_defender then local left = ja_cd_left('Defender') or approx_left('defender', s.war.defender_cd or 300, now_t); table.insert(out, cd_token('Df', left, s.war.defender_cd or 300, s.hud.cd_width)) end
    if s.war.use_berserk then local left = ja_cd_left('Berserk') or approx_left('berserk', s.war.berserk_cd or 300, now_t); table.insert(out, cd_token('Bk', left, s.war.berserk_cd or 300, s.hud.cd_width)) end
    if s.war.use_aggressor then local left = ja_cd_left('Aggressor') or approx_left('aggressor', s.war.aggressor_cd or 300, now_t); table.insert(out, cd_token('Ag', left, s.war.aggressor_cd or 300, s.hud.cd_width)) end
  end
  if #out == 0 then return nil end
  return 'CD: '..table.concat(out, '  ')
end

function M.ensure()
  local s = store.settings
  if not (s.hud and s.hud.enable) then if store.hud.handle then store.hud.handle:hide() end; return end
  if not store.hud.handle then
    store.hud.handle = texts.new('', {pos={x=s.hud.x or 20, y=s.hud.y or 60}, text={size=s.hud.size or 12}}); store.hud.handle:show()
  else
    store.hud.handle:pos(s.hud.x or 20, s.hud.y or 60); store.hud.handle:size(s.hud.size or 12); store.hud.handle:show()
  end
end

function M.update()
  local s = store.settings
  if not (s.hud and s.hud.enable) then return end
  local t = util.now(); if (t - store.hud.last) < 0.5 then return end; store.hud.last = t
  if not store.hud.handle then M.ensure() end; if not store.hud.handle then return end
  local p = util.me() or {}
  local tgt = util.get_target()
  local ws_name = util.pick_ws_name()
  local level, holder = hate_info()
  local hate_line = (s.hud and s.hud.hatebar)
    and ('Hate '..(s.hud.color and colorize_bar(level, s.hud.bar_width or 20) or render_bar(level, s.hud.bar_width or 20))..' '..holder)
    or ((level >= 0.999 and 'Hate: YOU') or ('Hate: '..holder))
  local cd_line = build_cooldown_line(t)
  local lines = {
    ('AP %s | Mode:%s'):format(s.enabled and 'ON' or 'OFF', s.mode),
    ('HP:%s%% MP:%s TP:%s'):format((p.vitals and p.vitals.hpp) or '-', (p.vitals and p.vitals.mpp) or '-', (p.vitals and p.vitals.tp) or '-'),
    ('Stance:%s  Cover:%s'):format(s.war and s.war.stance or '-', s.pld and (s.pld.cover_mode or '-') or '-'),
    ('WS:%s  Opener:%s'):format(ws_name or '?', store.opener.step or 0),
    hate_line,
    tgt and ('Target:%s'):format(tgt.name) or 'Target:(none)',
    cd_line,
  }
  local clean = {}; for _,L in ipairs(lines) do if L then table.insert(clean, L) end end
  store.hud.handle:text(table.concat(clean, '\n'))
end

return M
