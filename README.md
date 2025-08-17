# ffxi-autopilot-windower

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Lua 5.1](https://img.shields.io/badge/Lua-5.1-blue.svg)](#)
[![Windower 4](https://img.shields.io/badge/Windower-4-lightgrey.svg)](#)
[![Release](https://img.shields.io/github/v/release/<YOUR_GH_USERNAME>/ffxi-autopilot-windower?include_prereleases&sort=semver)](#)
[![Issues](https://img.shields.io/github/issues/<YOUR_GH_USERNAME>/ffxi-autopilot-windower.svg)](https://github.com/<YOUR_GH_USERNAME>/ffxi-autopilot-windower/issues)
[![Downloads](https://img.shields.io/github/downloads/<YOUR_GH_USERNAME>/ffxi-autopilot-windower/total.svg)](#)

Helper to automate follow/assist/heal and a PLD/WAR tank loop on **private** FFXI servers.
Includes a colorized HUD (hate bar + per-action cooldown timers).

> ⚠️ Use only on private servers you own/control. Automation on retail FFXI can violate ToS.

## HUD Preview

![HUD screenshot](docs/hud-screenshot.png)

## Install
1. Download this repo or the release zip and extract.
2. Copy the `autopilot/` folder into your Windower `addons/` directory, so you have:
   `Windower/addons/autopilot/init.lua`.
3. In-game: `//lua load autopilot`

## Commands (short list)
```
start, stop, mode <assist|heal|follow|pld>,
leader <Name>, ws <Name|auto>, tp <N>, follow <on|off>,
stance <defensive|offensive|auto>, war <on|off>,
covermode <highest|healer|leader>, coverstep <on|off>,
hud <on|off>, hudpos <x> <y>, hudsize <n>,
hudcolor <on|off>, hudcd <on|off>,
hudbarwidth <n>, hudcdwidth <n>,
smooth <on|off>, smoothdelay <move> <target>,
status
```

## Recommended repository name
**ffxi-autopilot-windower**

After you create the GitHub repo, replace the badge placeholders:
- Find `<YOUR_GH_USERNAME>` and replace with your GitHub username.
- The badges will then point to the real issues/releases/downloads.

## Releases
- Tag your commit, e.g. `v0.1.0`, and push the tag. The included GitHub Action will zip `autopilot/` and attach it to the release.
