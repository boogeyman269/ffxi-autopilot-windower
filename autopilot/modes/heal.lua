
local store = require('autopilot.store')
local util  = require('autopilot.util')
local M = {}

local function first_wounded_party_member()
  local pt = util.party(); if not pt then return nil end
  local lowest = nil
  for i=0,5 do local key = i==0 and 'p0' or ('p'..i) local m = pt[key] if m and m.hpp and m.name then if m.hpp < store.settings.heal_threshold then lowest = m; break end end end
  return lowest
end

function M.run()
  local p = util.me(); if not p then return end
  local t = util.now()
  if (p.vitals and p.vitals.mp or 0) < store.settings.min_mp then return end
  if t - store.last.heal < 3.5 then return end
  local target = first_wounded_party_member()
  if target then local cure = (store.settings.auto_cure_tier and util.best_cure()) or store.settings.cure_spell if cure then util.use_spell(cure, target.name, 'cure', store.settings.pld.cure_cd or 8.0) end store.last.heal = t end
  util.follow_leader()
end
return M
