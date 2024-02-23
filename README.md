# Pokébot NDS
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/B0B7RMWPP)

This repository is dedicated to creating a multi-purpose automated tool for the mainline DS Pokémon games. Reported [issues](https://github.com/wyanido/pokebot-nds/issues) or contributions in any form are heavily appreciated, as making this project widely compatible takes a lot of work.

## Special Thanks

- All the contributors of [BizHawk](https://github.com/TASEmulators/BizHawk) emulator for making this project possible
- [40 Cakes](https://github.com/40Cakes) for the [Gen III PokéBot](https://github.com/40Cakes/pokebot-gen3) that originally inspired this project
- [evandixon](https://projectpokemon.org/home/profile/183-evandixon/) for demystifying the [NDS Pokemon format](https://projectpokemon.org/home/docs/gen-5/bw-save-structure-r60)
- [VigiL](https://github.com/907VigiL) for backporting the first Gen V methods to Gen IV

## Getting Started
<img src="https://i.imgur.com/lHaYC4z.png" width="700"/>

#### Prerequisites
You'll need to install [node.js](https://nodejs.org/en) and the latest version of [BizHawk](https://github.com/TASEmulators/BizHawk) in order to use this tool. 

#### Installation
**Recommended**: Install [Github Desktop](https://desktop.github.com/) and clone the repository to stay up to date with the latest versions of the bot.

Alternatively, download [the latest release](https://github.com/wyanido/pokebot-nds/releases/latest) as a .zip archive and extract it anywhere you like.

_(You can also clone the [dev branch](https://github.com/wyanido/pokebot-nds/tree/dev) to preview upcoming features)_

#### Setup
Run the dashboard with `start-dashboard.bat` before you add or enable pokebot-nds.lua in Tools>Lua Console. The game will connect to the dashboard once the script starts running.

## Features

_Currently only English (USA, Europe) copies are supported._
|  						| DPPt | HGSS | BW | B2W2 | 
|--						| :-: | :-: | :-: | :-: |
| Manual (Assisted)     | ✅ | ✅ | ✅ | ✅ |
| Starter resets 		| ✅ | ✅ | ✅ | ✅ |
| Random encounters		| ✅ | ✅ | ✅ | ✅ |
| Auto-catching			| ❔ | ➖ | ✅ | ✅ |
| Auto-battling			| ❔ | ➖ | ✅ | ✅ |
| Pickup farming		| ❔ | ➖ | ✅ | ✅ |
| Gift resets 			| ✅ | ✅ | ✅ | ✅ |
| Egg hatching			| ➖ | ➖ | ✅ | ✅ |
| Static encounters 	| ✅ | ✅ | ✅ | ✅ |
| Thief farming			| ➖ | ➖ | ✅ | ✅ |
| Fishing			   	| ✅ | ➖ | ✅ | ✅ |
| Dust cloud farming	|  |  | ✅ | ✅ |
| Phenomenon encounters	|  |  | ✅ | ✅ |
| PokéRadar			   	| ➖ |  |  |  |
| Headbutt encounters			   	|  | ➖ |  |  |
| Voltorb Flip			   	|  | ✅ |  |  |
| Thundurus/Tornadus dex resets	|  |  | ➖ |  |
| Hidden Grotto farming	|  |  |  | ➖ |
