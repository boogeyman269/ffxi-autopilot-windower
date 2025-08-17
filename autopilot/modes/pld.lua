
local store = require('autopilot.store')
local util  = require('autopilot.util')
local M = {}

local function cover_logic(t, tgt)
  local s = store.settings
  if not s.pld.use_cover or not util.ready('cover', s.pld.cover_cd or 180) or util.has_buff('Cover') then return end
  local mode = (s.pld.cover_mode or 'highest_hate'):lower()
  local cover_name = nil
  if mode == 'highest_hate' and tgt then
    local tt = windower.ffxi.get_mob_by_target('tt')
    if tt and tt.name then
      local mep = util.me()
      if not (mep and mep.name and tt.name:lower() == mep.name:lower()) then
        if util.find_party_member(tt.name) then cover_name = tt.name end
      end
    end
  elseif mode == 'healer' then
    local cand = util.find_best_healer_candidate()
    if cand and cand.name then local cm = windower.ffxi.get_mob_by_name(cand.name) if cm and util.in_range(cm, s.pld.cover_distance or 10) then cover_name = cand.name end end
  end
  if not cover_name and s.leader ~= '' then local leader_pt = util.find_party_member(s.leader) if leader_pt and (leader_pt.hpp or 100) <= (s.pld.cover_hpp or 50) then cover_name = s.leader end end
  if cover_name then local cover_mob = windower.ffxi.get_mob_by_name(cover_name) if cover_mob and util.in_range(cover_mob, s.pld.cover_distance or 10) then util.use_ja('Cover', cover_name, 'cover', s.pld.cover_cd or 180) if s.pld.cover_stepin then store.vars.cover_follow_until = t + (s.pld.cover_step_time or 2.5) store.vars.cover_follow_name = cover_name end end end
end

function M.run()
  util.follow_leader()
  local p = util.me(); if not p then return end
  local t = util.now()
  local tgt = util.get_target()
  local tt = windower.ffxi.get_mob_by_target('tt')
  if util.smoothing_block(t, tgt) then return end

  if tt and p and tt.name and p.name then
    if tt.name:lower() ~= p.name:lower() then if store.vars.no_top_hate_since == 0 then store.vars.no_top_hate_since = t end else store.vars.no_top_hate_since = 0 end
  end
  if store.vars.no_top_hate_since ~= 0 and (t - store.vars.no_top_hate_since) >= (store.settings.pld.hate_reset_window or 2.0) and store.opener.step == 0 then
    store.opener.step = 1; store.opener.started = t; store.vars.no_top_hate_since = 0
  end
  if store.vars.cover_follow_until and t < store.vars.cover_follow_until and store.vars.cover_follow_name then if (t - store.last.follow) > 1.0 then util.cmd(('/follow %s'):format(store.vars.cover_follow_name)) store.last.follow = t end end

  if store.settings.leader ~= '' and (t - store.last.action) > 1.0 then util.cmd(('/assist %s'):format(store.settings.leader)); store.last.action = t end
  if p.status ~= 1 and (t - store.last.action) > 1.0 then util.cmd('/attack on'); store.last.action = t end

  if tgt and (tgt.id ~= store.opener.target_id) then store.opener.target_id = tgt.id; store.opener.step = 1; store.opener.started = t end
  if not tgt then store.opener.target_id = nil; store.opener.step = 0 end
  if store.opener.step and store.opener.step > 0 then
    if store.opener.step == 1 and tgt and util.in_range(tgt, util.RANGES.FLASH) and store.settings.pld.use_flash and util.ready('flash', store.settings.pld.flash_cd or 25) then util.use_spell('Flash','<t>','flash', store.settings.pld.flash_cd or 25); store.opener.step = 2; return end
    if store.opener.step == 2 and tgt and util.in_range(tgt, util.RANGES.PROVOKE) and store.settings.pld.use_provoke and util.ready('provoke', store.settings.pld.provoke_cd or 30) then util.use_ja('Provoke','<t>','provoke', store.settings.pld.provoke_cd or 30); store.opener.step = 3; return end
    if store.opener.step == 3 and tgt and util.in_range(tgt, util.RANGES.BASH) and store.settings.pld.use_shield_bash and util.ready('bash', store.settings.pld.shield_bash_cd or 45) then util.use_ja('Shield Bash','<t>','bash', store.settings.pld.shield_bash_cd or 45); store.opener.step = 0; return end
    if (t - store.opener.started) > 10 then store.opener.step = 0 end
  end

  local hpp = (p.vitals and p.vitals.hpp) or 100
  if hpp <= (store.settings.pld.panic_hpp or 35) and store.settings.pld.use_sentinel and util.ready('sentinel', store.settings.pld.sentinel_cd or 300) then util.use_ja('Sentinel','<me>','sentinel', store.settings.pld.sentinel_cd or 300) end
  if hpp <= 20 and util.ready('invincible', 900) then util.use_ja('Invincible','<me>','invincible', 900) end

  local mp = (p.vitals and p.vitals.mp) or 0
  if mp >= (store.settings.min_mp or 60) and hpp <= (store.settings.pld.self_cure_hpp or 70) and util.ready('cure', store.settings.pld.cure_cd or 8.0) then local _cure = (store.settings.auto_cure_tier and (util.best_cure() or 'Cure')) or (store.settings.cure_spell or 'Cure IV') if _cure then util.use_spell(_cure,'<me>','cure', store.settings.pld.cure_cd or 8.0) end end

  cover_logic(t, tgt)

  if store.settings.pld.keep_reprisal and ((not store.settings.pld.buff_awareness) or not util.has_buff('Reprisal') or (store.settings.pld.buff_duration_aware and (t - store.last.reprisal) >= (store.settings.pld.reprisal_refresh or 50))) and util.ready('reprisal', store.settings.pld.reprisal_cd or 60) then util.use_spell('Reprisal','<me>','reprisal', store.settings.pld.reprisal_cd or 60) end
  if store.settings.pld.keep_enlight and ((not store.settings.pld.buff_awareness) or not util.has_buff('Enlight') or (store.settings.pld.buff_duration_aware and (t - store.last.enlight) >= (store.settings.pld.enlight_refresh or 110))) and util.ready('enlight', store.settings.pld.enlight_cd or 240) then util.use_spell('Enlight','<me>','enlight', store.settings.pld.enlight_cd or 240) end
  if store.settings.pld.keep_majesty and ((not store.settings.pld.buff_awareness) or not util.has_buff('Majesty') or (store.settings.pld.buff_duration_aware and (t - store.last.majesty) >= (store.settings.pld.majesty_refresh or 55))) and util.ready('majesty', store.settings.pld.majesty_cd or 60) then util.use_ja('Majesty','<me>','majesty', store.settings.pld.majesty_cd or 60) end

  if store.settings.war and store.settings.war.enable then
    if store.settings.war.use_warcry and util.ready('warcry', store.settings.war.warcry_cd or 300) then util.use_ja('Warcry','<me>','warcry', store.settings.war.warcry_cd or 300) end
    local stance = (store.settings.war.stance or 'defensive'):lower()
    if stance == 'auto' then stance = (hpp <= (store.settings.war.auto_defender_hpp or 85)) and 'defensive' or 'offensive' end
    if stance == 'defensive' then
      if store.settings.war.use_defender and util.ready('defender', store.settings.war.defender_cd or 300) then util.use_ja('Defender','<me>','defender', store.settings.war.defender_cd or 300) end
    else
      if store.settings.war.use_berserk and util.ready('berserk', store.settings.war.berserk_cd or 300) then util.use_ja('Berserk','<me>','berserk', store.settings.war.berserk_cd or 300) end
      if store.settings.war.use_aggressor and util.ready('aggressor', store.settings.war.aggressor_cd or 300) then util.use_ja('Aggressor','<me>','aggressor', store.settings.war.aggressor_cd or 300) end
    end
  end

  if tgt and util.in_range(tgt, util.RANGES.FLASH) and store.settings.pld.use_flash and util.ready('flash', store.settings.pld.flash_cd or 25) then util.use_spell('Flash','<t>','flash', store.settings.pld.flash_cd or 25) end
  if tgt and util.in_range(tgt, util.RANGES.PROVOKE) and store.settings.pld.use_provoke and util.ready('provoke', store.settings.pld.provoke_cd or 30) then util.use_ja('Provoke','<t>','provoke', store.settings.pld.provoke_cd or 30) end
  if store.settings.pld.use_rampart and util.ready('rampart', store.settings.pld.rampart_cd or 300) then util.use_ja('Rampart','<me>','rampart', store.settings.pld.rampart_cd or 300) end
  if tgt and util.in_range(tgt, util.RANGES.BASH) and store.settings.pld.use_shield_bash and util.ready('bash', store.settings.pld.shield_bash_cd or 45) then util.use_ja('Shield Bash','<t>','bash', store.settings.pld.shield_bash_cd or 45) end

  if tgt and util.in_range(tgt, util.RANGES.WS) and util.can_ws() then
    if p.vitals and p.vitals.tp and p.vitals.tp >= (store.settings.tp or 1000) and (t - store.last.ws) > 4.0 then
      local ws_name = util.pick_ws_name()
      util.cmd((" /ws \"%s\" <t>"):format(ws_name)); store.last.ws = t
    end
  end
end

return M
