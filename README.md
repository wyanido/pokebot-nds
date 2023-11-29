# Pokébot NDS
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/B0B7RMWPP)

This repository is dedicated to creating a multi-purpose automated tool for the mainline DS Pokémon games. Reported [issues](https://github.com/wyanido/pokebot-nds/issues) or contributions in any form are heavily appreciated, as making this project widely compatible takes a lot of work.

## Special Thanks

- All the contributors of [BizHawk](https://github.com/TASEmulators/BizHawk) emulator for making this project possible
- [40 Cakes](https://github.com/40Cakes) for the [Gen III PokéBot](https://github.com/40Cakes/pokebot-gen3) that originally inspired this project
- [evandixon](https://projectpokemon.org/home/profile/183-evandixon/) for demystifying the [NDS Pokemon format](https://projectpokemon.org/home/docs/gen-5/bw-save-structure-r60)
- [VigiL](https://github.com/907VigiL) for extending many of the Gen V methods to work in Gen IV

## Getting Started
<img src="https://cdn.discordapp.com/attachments/1150551936341389382/1150552817120071680/dashboard.png" width="700"/>

#### Prerequisites
You'll need to install [node.js](https://nodejs.org/en) and the latest version of [BizHawk](https://github.com/TASEmulators/BizHawk) in order to use this tool. 

#### Installation
Download [the latest release](https://github.com/wyanido/pokebot-nds/releases/latest) and extract the folder anywhere you like.

_(You can also optionally clone the [dev branch](https://github.com/wyanido/pokebot-nds/tree/dev) to preview upcoming features)_

#### Setup
Ensure the dashboard is always running by using `start-dashboard.bat` before you start BizHawk or enable the script in the Lua Console. 

The dashboard relies on net sockets to communicate with BizHawk, which aren't enabled in the emulator by default. 
Execute BizHawk with the arguments `--socket_ip=127.0.0.1 --socket_port=51055` to enable them. The two easiest ways to do this are:

**Via the command prompt**
* e.g. `EmuHawk.exe --socket_ip=127.0.0.1 --socket_port=51055`
* or if you're using powershell `.\EmuHawk.exe --socket_ip=127.0.0.1 --socket_port=51055`

**Or creating a shortcut**
* Append the same arguments (`--socket_ip=127.0.0.1 --socket_port=51055`) to the end of the 'Target' field after the file path.

![](https://i.imgur.com/IvTNbWz.png)

Once complete, you can safely open the emulator and add `pokebot-nds.lua` to BizHawk in Tools>Lua Console. Start the script to enable the bot behaviour.


## Features

_Currently only English (USA, Europe) copies are supported._
|  						| DPPt | HGSS | BW | B2W2 | 
|--						| :-: | :-: | :-: | :-: |
| Manual (Assisted)     | ✅ | ✅ | ✅ | ✅ |
| Starter resets 		| ❔ | ✅ | ✅ | ✅ |
| Random encounters		| ✅ | ✅ | ✅ | ✅ |
| Auto-catching			| ➖ | ➖ | ✅ | ✅ |
| Auto-battling			| ➖ | ➖ | ✅ | ✅ |
| Pickup farming		| ➖ | ➖ | ✅ | ✅ |
| Gift resets 			| ➖ | ➖ | ✅ | ✅ |
| Egg hatching			| ➖ | ➖ | ✅ | ✅ |
| Static encounters 	| ➖ | ✅ | ✅ | ✅ |
| Thief farming			| ➖ | ➖ | ✅ | ✅ |
| Fishing			   	| ➖ | ➖ | ✅ | ✅ |
| Dust cloud farming	|  |  | ✅ | ✅ |
| Phenomenon encounters	|  |  | ✅ | ✅ |
| PokéRadar			   	| ➖ |  |  |  |
| Headbutt encounters			   	|  | ➖ |  |  |
| Voltorb Flip			   	|  | ✅ |  |  |
| Thundurus/Tornadus dex resets	|  |  | ➖ |  |
| Hidden Grotto farming	|  |  |  | ➖ |
