
-- addons/autopilot/init.lua
_addon.name    = 'autopilot'
_addon.author  = 'you'
_addon.version = '0.4'
_addon.command = 'ap'

local config = require('config')
local store = require('autopilot.store')
local defaults = require('autopilot.defaults')
local util = require('autopilot.util')
local hud = require('autopilot.hud')

store.settings = config.load(defaults)
hud.ensure()

local mode_assist = require('autopilot.modes.assist')
local mode_heal   = require('autopilot.modes.heal')
local mode_pld    = require('autopilot.modes.pld')

local settings = store.settings

windower.register_event('addon command', function(cmd, ...)
    cmd = (cmd or ''):lower()
    local args = {...}

    if cmd == 'start' then
        settings.enabled = true
        config.save(settings)
        util.say('Started.')
    elseif cmd == 'stop' then
        settings.enabled = false
        config.save(settings)
        util.say('Stopped.')
    elseif cmd == 'mode' then
        local m = (args[1] or settings.mode):lower()
        if m == 'assist' or m == 'heal' or m == 'follow' or m == 'pld' then
            settings.mode = m; util.say('Mode: '..m); config.save(settings)
        else util.say('Modes: assist | heal | follow | pld') end
    elseif cmd == 'leader' then
        settings.leader = args[1] or ''; util.say('Leader: '..(settings.leader ~= '' and settings.leader or '(none)')); config.save(settings)
    elseif cmd == 'ws' then
        settings.ws = table.concat(args, ' '); util.say('WS: '..settings.ws); config.save(settings)
    elseif cmd == 'tp' then
        local v = tonumber(args[1]); if v then settings.tp = v; util.say('TP: '..v); config.save(settings) end
    elseif cmd == 'follow' then
        local v = (args[1] or 'on'):lower(); settings.follow = (v ~= 'off'); util.say('Follow: '..(settings.follow and 'on' or 'off')); config.save(settings)
    elseif cmd == 'stance' then
        local v = (args[1] or (settings.war and settings.war.stance) or 'defensive'):lower()
        if v == 'defensive' or v == 'offensive' or v == 'auto' then
            settings.war = settings.war or {}; settings.war.stance = v; util.say('WAR stance: '..v); config.save(settings)
        else util.say('Stance: defensive | offensive | auto') end
    elseif cmd == 'war' then
        local v = (args[1] or 'on'):lower(); settings.war = settings.war or {}; settings.war.enable = (v ~= 'off'); util.say('WAR features: '..(settings.war.enable and 'on' or 'off')); config.save(settings)
    elseif cmd == 'covermode' then
        local v = (args[1] or (settings.pld and settings.pld.cover_mode) or 'highest_hate'):lower()
        if v == 'highest' then v = 'highest_hate' end
        if v == 'highest_hate' or v == 'leader' or v == 'healer' then settings.pld = settings.pld or {}; settings.pld.cover_mode = v; util.say('Cover mode: '..v); config.save(settings) else util.say('Covermode: highest | healer | leader') end
    elseif cmd == 'coverstep' then
        settings.pld = settings.pld or {}; local v = (args[1] or ((settings.pld.cover_stepin and 'on') or 'off')):lower(); settings.pld.cover_stepin = (v ~= 'off'); util.say('Cover step-in: '..(settings.pld.cover_stepin and 'on' or 'off')); config.save(settings)
    elseif cmd == 'hud' then
        settings.hud = settings.hud or {}; local v = (args[1] or ((settings.hud.enable and 'on') or 'off')):lower(); settings.hud.enable = (v ~= 'off'); util.say('HUD: '..(settings.hud.enable and 'on' or 'off')); config.save(settings); hud.ensure()
    elseif cmd == 'hudpos' then
        settings.hud = settings.hud or {}; local x = tonumber(args[1]); local y = tonumber(args[2]); if x and y then settings.hud.x = x; settings.hud.y = y; util.say(('HUD pos: %d,%d'):format(x,y)); config.save(settings); hud.ensure() else util.say('Usage: //ap hudpos <x> <y>') end
    elseif cmd == 'hudsize' then
        settings.hud = settings.hud or {}; local s = tonumber(args[1]); if s then settings.hud.size = s; util.say('HUD size: '..s); config.save(settings); hud.ensure() else util.say('Usage: //ap hudsize <n>') end
    elseif cmd == 'hudcolor' then
        settings.hud = settings.hud or {}; local v = (args[1] or ((settings.hud.color and 'on') or 'off')):lower(); settings.hud.color = (v ~= 'off'); util.say('HUD color: '..(settings.hud.color and 'on' or 'off')); config.save(settings)
    elseif cmd == 'hudcd' then
        settings.hud = settings.hud or {}; local v = (args[1] or ((settings.hud.cooldowns and 'on') or 'off')):lower(); settings.hud.cooldowns = (v ~= 'off'); util.say('HUD cooldowns: '..(settings.hud.cooldowns and 'on' or 'off')); config.save(settings)
    elseif cmd == 'hudbarwidth' then
        settings.hud = settings.hud or {}
        local n = tonumber(args[1])
        if n then
            settings.hud.bar_width = n
            util.say('Hate bar width: '..n)
            config.save(settings); hud.ensure()
        else
            util.say('Usage: //ap hudbarwidth <n>')
        end
    elseif cmd == 'hudcdwidth' then
        settings.hud = settings.hud or {}
        local n = tonumber(args[1])
        if n then
            settings.hud.cd_width = n
            util.say('Cooldown bar width: '..n)
            config.save(settings); hud.ensure()
        else
            util.say('Usage: //ap hudcdwidth <n>')
        end

    elseif cmd == 'smooth' then
        settings.smooth = settings.smooth or {}; local v = (args[1] or ((settings.smooth.enable and 'on') or 'off')):lower(); settings.smooth.enable = (v ~= 'off'); util.say('Smoothing: '..(settings.smooth.enable and 'on' or 'off')); config.save(settings)
    elseif cmd == 'smoothdelay' then
        settings.smooth = settings.smooth or {}; if args[1] and args[2] and tonumber(args[1]) and tonumber(args[2]) then settings.smooth.move_delay = tonumber(args[1]); settings.smooth.target_switch_delay = tonumber(args[2]); util.say(('Smoothing delays set: move=%.2fs target=%.2fs'):format(settings.smooth.move_delay, settings.smooth.target_switch_delay)); config.save(settings) else local which = (args[1] or ''):lower(); local val = tonumber(args[2]); if (which == 'move' or which == 'target') and val then if which == 'move' then settings.smooth.move_delay = val else settings.smooth.target_switch_delay = val end; util.say(('Smoothing %s delay: %.2fs'):format(which, val)); config.save(settings) else util.say('Usage: //ap smoothdelay <move> <target>  or  //ap smoothdelay move <sec> | target <sec>') end end
    elseif cmd == 'status' then
        util.say(('enabled=%s | mode=%s | leader=%s | follow=%s | ws=%s @%dTP | cure=%s <%d%%>')
            :format(tostring(settings.enabled), settings.mode, settings.leader, tostring(settings.follow), settings.ws, settings.tp, settings.cure_spell, settings.heal_threshold))
        util.say(('hudcolor=%s hudcd=%s | smooth=%s (move=%.2fs, target=%.2fs)'):format(
            settings.hud and tostring(settings.hud.color) or 'false',
            settings.hud and tostring(settings.hud.cooldowns) or 'false',
            settings.smooth and tostring(settings.smooth.enable) or 'false',
            settings.smooth and (settings.smooth.move_delay or 0) or 0,
            settings.smooth and (settings.smooth.target_switch_delay or 0) or 0))
    else
        util.say('Commands: start, stop, mode <assist|heal|follow|pld>, leader <Name>, ws <Name|auto>, tp <N>, follow <on|off>, stance <defensive|offensive|auto>, war <on|off>, covermode <highest|healer|leader>, coverstep <on|off>, hud <on|off>, hudpos <x> <y>, hudsize <n>, hudcolor <on|off>, hudcd <on|off>, hudbarwidth <n>, hudcdwidth <n>, smooth <on|off>, smoothdelay <move> <target>, status')
    end
end)

windower.register_event('prerender', function()
    local t = util.now()
    if t - store.last.tick < (settings.pulse or 0.25) then return end
    store.last.tick = t

    hud.ensure()
    hud.update()

    if not settings.enabled then return end

    if settings.mode == 'assist' then
        util.follow_leader()
        mode_assist.run()
    elseif settings.mode == 'heal' then
        mode_heal.run()
    elseif settings.mode == 'pld' then
        mode_pld.run()
    else
        util.follow_leader()
    end
end)
