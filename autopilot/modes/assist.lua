
local store = require('autopilot.store')
local util  = require('autopilot.util')
local M = {}
function M.run()
  local p = util.me(); if not p then return end
  local t = util.now()
  if store.settings.leader ~= '' and (t - store.last.action) > 1.0 then util.cmd(('/assist %s'):format(store.settings.leader)); store.last.action = t end
  if p.status ~= 1 and (t - store.last.action) > 1.0 then util.cmd('/attack on'); store.last.action = t; return end
  if p.vitals and p.vitals.tp and p.vitals.tp >= store.settings.tp and (t - store.last.ws) > 4.0 then util.cmd((' /ws "%s" <t>'):format(store.settings.ws)); store.last.ws = t end
end
return M
