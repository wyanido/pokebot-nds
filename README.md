# pokebot-nds
 
This repository is dedicated to creating a DS-era extension of https://github.com/40Cakes/pokebot-bizhawk. Reported issues or contributions in any form are heavily appreciated, as making this project widely compatible takes a lot of work.

## Setup
The lua script comes with a dashboard which is heavily recommended, but also entirely optional. You can either run the Electron project directly from the `dashboard-build` folder, or download `dashboard.tar.gz` as a standalone executable from [Releases](https://github.com/wyanido/pokebot-nds/releases/latest). Make sure the dashboard is running before you enable `pokebot-nds.lua` in the BizHawk's Lua Console.

The dashboard relies on net sockets which aren't enabled in BizHawk by default, so it's important that EmuHawk is executed with the arguments `--socket_ip=127.0.0.1 --socket_port=51055`. You can do this either via a command line, or create a shortcut to EmuHawk.exe with the arguments added to the end of the 'target' field.

When downloading a newer version of the bot without a dedicated dashboard.tar.gz release, drag the files from `dashboard-build` into `resources>app` in the extracted dashboard folder to ensure compatibility with the other components.

### Features
|  						| BW | B2W2 | 
|--						| :-: | :-: |
| Starter resets 		| ✅ | ➖ |
| Random encounters		| ✅ | ➖ |
| Auto-catching			| ✅ | ➖ |
| Auto-battling			| ✅ | ➖ |
| Pickup farming		| ✅ | ➖ |
| Gift resets 			| ✅ | ➖ |
| Egg hatching			| ✅ | ➖ |
| Static encounters 	| ➖ | ➖ |
| Thief farming			| ✅ | ➖ |
| Dust cloud farming	| ➖ | ➖ |
| Phenomenon encounters	| ➖ | ➖ |
| Thundurus/Tornadus dex resets	| ➖ | n/a |
| Hidden Grotto farming	| n/a | ➖ |
| Thief farming		   	| ➖ | ➖ |
| Fishing			   	| ➖ | ➖ |

_* Currently only English (USA, Europe) copies are supported._

While a basis for Gen IV support exists within the project, support for these games is not currently planned. The inconsistent RAM addresses make it impractical to track every necessary game state and event.

## To-do list
- [x] Dashboard with stats
- [x] Config page on dashboard
- [x] Customisable target traits
