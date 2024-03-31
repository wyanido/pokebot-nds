# PokéBot NDS
<img src='https://i.imgur.com/lHaYC4z.png' width='600px'>

This repository is dedicated to creating a multi-purpose automated tool for the mainline DS Pokémon games. The bot can perform most monotonous tasks in these games, with all languages supported.

Reported [Issues](https://github.com/wyanido/pokebot-nds/issues) and donations are very appreciated, as making this project widely compatible as the sole developer takes a lot of time and work.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/B0B7RMWPP)

## Getting Started
#### Prerequisites
You'll need to install [node.js](https://nodejs.org/en), and have a recent version of [BizHawk](https://github.com/TASEmulators/BizHawk/releases/latest) or [DeSmuME](https://github.com/TASEmulators/desmume/releases/latest) in order to use this tool. 

#### Installation
**Recommended**: Install [Github Desktop](https://desktop.github.com/) and locally clone this repository to stay up to date with the latest versions of the bot.
_(You can also clone the [dev branch](https://github.com/wyanido/pokebot-nds/tree/dev) to preview upcoming features)_

Alternatively, download [the latest release](https://github.com/wyanido/pokebot-nds/releases/latest) as a .zip archive and extract it anywhere you like.

#### Setup
1. Start the dashboard with `start-dashboard.bat`, or run these commands inside the `dashboard/` folder:
    - `npm i`
    - `npm start`
2. Use the dashboard's Config tab to customise the bot behaviour for your current task. 
3. Open your emulator's Lua Console, and load `pokebot-nds.lua`.
    - **BizHawk**: `Tools > Lua Console`
    - **DeSmuME**: `Tools > Lua Scripting > New Lua Script Window`

The game will then be connected to the dashboard, which you can view info for on the Dashboard tab. The bot will immediately start acting according to your Config, and log any encounters to the dashboard.

## Bot Modes
|  						| DPPt | HGSS | BW | B2W2 | 
|--						| :-: | :-: | :-: | :-: |
| Starter resets 		| ✅ | ✅ | ✅ | ✅ |
| Random encounters		| ✅ | ✅ | ✅ | ✅ |
| Phenomenon encounters		|  |  | ✅ | ✅ |
| Gift resets 			| ✅ | ✅ | ✅ | ✅ |
| Static encounters 	| ✅ | ✅ | ✅ | ✅ |
| Fishing			   	| ✅ | ✅ | ✅ | ✅ |
| Egg hatching			| ✅ | ✅ | ✅ | ✅ |
| Headbutt Trees 		|  | ✅ |  |  |
| Thundurus/Tornadus dex resets 			|  |  | ✅ |  |
| Hidden Grottos 	|  |  |  | ✅ |

#### Additional Features
|  						| DPPt | HGSS | BW | B2W2 | 
|--						| :-: | :-: | :-: | :-: |
| Auto-catching			| ✅ | ✅ | ✅ | ✅ |
| Auto-battling			| ✅ | ✅ | ✅ | ✅ |
| Thief farming			| ✅ | ✅ | ✅ | ✅ |
| Pickup farming		| ✅ | ✅ | ✅ | ✅ |
| Voltorb Flip		|  | ✅ |  |  |

## Special Thanks

- The contributors of [BizHawk](https://github.com/TASEmulators/BizHawk) and [DeSmuME](https://github.com/TASEmulators/DeSmuME) for providing a basis to make this project possible
- [40 Cakes](https://github.com/40Cakes) for the [Gen III PokéBot](https://github.com/40Cakes/pokebot-gen3) that originally inspired this project
- [evandixon](https://projectpokemon.org/home/profile/183-evandixon/) for demystifying the [NDS Pokemon format](https://projectpokemon.org/home/docs/gen-5/bw-save-structure-r60)