
local store = require('autopilot.store')
local res = require('resources')

local M = {}

function M.now() return os.clock() end
function M.say(msg) windower.add_to_chat(207, ('[AP] %s'):format(msg)) end
function M.me() return windower.ffxi.get_player() end
function M.my_mob() local p = M.me(); if not p then return nil end; return windower.ffxi.get_mob_by_index(p.index) end
function M.party() return windower.ffxi.get_party() end
function M.dist(a,b) if not a or not b or not a.x or not b.x then return 99 end local dx=(a.x-b.x) local dy=(a.y-b.y) return math.sqrt(dx*dx+dy*dy) end
function M.cmd(s) windower.send_command('input '..s) end
function M.ready(key, gap) local t=M.now() local lastt=store.last[key] or 0 return (t-lastt)>=(gap or 0) end

function M.find_party_member(name) if not name or name=='' then return nil end local pt=M.party(); if not pt then return nil end for i=0,5 do local key=i==0 and 'p0' or ('p'..i) local m=pt[key] if m and m.name and m.name:lower()==name:lower() then return m end end return nil end

function M.follow_leader() local settings=store.settings if not settings.follow or settings.leader=='' then return end local t=M.now() if t-store.last.follow<2.5 then return end local leader_m=windower.ffxi.get_mob_by_name(settings.leader) local me_m=M.my_mob() if leader_m and me_m then local d=M.dist(leader_m, me_m) if d>settings.follow_distance+1.0 then M.cmd(('/follow %s'):format(settings.leader)) store.last.follow=t end end end

local _spell_by_name, _ja_by_name = {}, {}
for id, s in pairs(res.spells or {}) do if s and s.english then _spell_by_name[s.english:lower()] = s end end
for id, a in pairs(res.job_abilities or {}) do if a and a.english then _ja_by_name[a.english:lower()] = a end end
function M.find_spell(name) return name and _spell_by_name[name:lower()] end
function M.find_ja(name) return name and _ja_by_name[name:lower()] end

local function ids() local p=M.me(); if not p then return 0,0,0,0 end local mj=p.main_job_id or p.mjob_id or 0 local sj=p.sub_job_id or p.sjob_id or 0 local ml=p.main_job_level or p.mlevel or p.level or 1 local sl=p.sub_job_level or p.slevel or math.floor(ml/2) return mj,ml,sj,sl end
local function level_ok(levels, job_id, lvl) return levels and job_id and lvl and levels[job_id] and (lvl >= levels[job_id]) end
function M.spell_available(spell) if not spell then return false end local mj,ml,sj,sl=ids() local learned=windower.ffxi.get_spells() if learned and learned[spell.id] then else if not (level_ok(spell.levels, mj, ml) or level_ok(spell.levels, sj, sl)) then return false end end local rec=windower.ffxi.get_spell_recasts() or {} local r=rec[spell.id] if r and r>0 then return false end return true end
function M.ja_available(ja) if not ja then return false end local mj,ml,sj,sl=ids() if not (level_ok(ja.levels, mj, ml) or level_ok(ja.levels, sj, sl)) then return false end local rec=windower.ffxi.get_ability_recasts() or {} local r=rec[ja.recast_id or -1] if r and r>0 then return false end return true end

local buff_name_to_id = {} for id,b in pairs(res.buffs or {}) do if b and b.english then buff_name_to_id[b.english:lower()] = id end end
function M.has_buff(name) local p=M.me(); if not p or not p.buffs then return false end local id=buff_name_to_id[(name or ''):lower()] if not id then return false end for _,bid in ipairs(p.buffs) do if bid==id then return true end end return false end
local function has_any(names) for _,n in ipairs(names or {}) do if M.has_buff(n) then return true end end return false end
function M.can_cast() return not has_any({'Silence','Mute','Stun','Sleep','Terror','Petrification','Charm'}) end
function M.can_ja()   return not has_any({'Amnesia','Stun','Sleep','Terror','Petrification','Charm'}) end
function M.can_ws()   return not has_any({'Stun','Sleep','Terror','Petrification','Charm'}) end

function M.use_spell(name, target, key, cd) if not M.can_cast() then return false end local s=M.find_spell(name); if not M.spell_available(s) then return false end if not M.ready(key, cd or 0) then return false end M.cmd((' /ma \"%s\" %s'):format(s.english, target)) store.last[key] = M.now() return true end
function M.use_ja(name, target, key, cd) if not M.can_ja() then return false end local a=M.find_ja(name); if not M.ja_available(a) then return false end if not M.ready(key, cd or 0) then return false end M.cmd(('/ja \"%s\" %s'):format(a.english, target)) store.last[key] = M.now() return true end

function M.best_cure() local p=M.me(); if not p then return 'Cure' end local order={'Cure IV','Cure III','Cure II','Cure'} local mp=(p.vitals and p.vitals.mp) or 0 for _,n in ipairs(order) do local s=M.find_spell(n) if s and M.spell_available(s) and (s.mp_cost or 0) <= mp then return s.english end end return 'Cure' end

M.RANGES = { WS = 4.5, BASH = 3.5, PROVOKE = 25.0, FLASH = 16.0 }
function M.get_target() return windower.ffxi.get_mob_by_target('t') or nil end
function M.in_range(mob, maxr) local me_m=M.my_mob() if not me_m or not mob then return false end return M.dist(me_m, mob) <= (maxr or 4.0) end

function M.pick_ws_name() local settings=store.settings if not (settings.auto_ws_by_weapon) then return settings.ws end if settings.ws and settings.ws:lower() ~= 'auto' then return settings.ws end local p=M.me(); if not p or not p.skills then return settings.ws or 'Savage Blade' end local sword=p.skills.sword or p.skills.Sword or 0 local gs=p.skills['great sword'] or p.skills.great_sword or p.skills.Greatsword or 0 local club=p.skills.club or p.skills.Club or 0 local polearm=p.skills.polearm or p.skills.Polearm or 0 if sword>=gs and sword>=club and sword>=polearm then return 'Savage Blade' end if gs>=club and gs>=polearm then return 'Resolution' end if polearm>=club then return 'Impulse Drive' end return 'Judgment' end

function M.smoothing_block(t, tgt) local settings=store.settings if not (settings.smooth and settings.smooth.enable) then return false end local me_m=M.my_mob() if me_m and me_m.x and me_m.y then local lp=store.vars.last_pos if lp.x and lp.y then local dd=math.sqrt((me_m.x-lp.x)^2 + (me_m.y-lp.y)^2) if dd>0.4 then lp.t=t end if dd>0.4 and (t-lp.t) < (settings.smooth.move_delay or 0.35) then return true end else lp.t=t end lp.x,lp.y = me_m.x, me_m.y end local tid=tgt and tgt.id or nil if tid and tid ~= store.vars.last_target_id then store.vars.last_target_id = tid store.vars.last_target_switch = t return true end if store.vars.last_target_switch ~= 0 and (t - store.vars.last_target_switch) < (settings.smooth.target_switch_delay or 0.6) then return true end return false end

local HEALER_SHORT = { WHM=true, RDM=true, SCH=true, GEO=true }
function M.is_healer_member(m) if not m then return false end local short = (m.main_job or m.job or m.mjob or '') if (not short or short == '') and m.main_job_id and res.jobs and res.jobs[m.main_job_id] and res.jobs[m.main_job_id].english_short then short = res.jobs[m.main_job_id].english_short end short=(short or ''):upper() return HEALER_SHORT[short] == true end
function M.find_best_healer_candidate() local pt=M.party(); if not pt then return nil end local mep=M.me() local best=nil for i=0,5 do local key=i==0 and 'p0' or ('p'..i) local m=pt[key] if m and m.name and (not mep or m.name:lower() ~= mep.name:lower()) and M.is_healer_member(m) then if not best or (m.hpp or 100) < (best.hpp or 100) then best = m end end end return best end

return M
