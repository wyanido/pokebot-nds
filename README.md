# pokebot-gen-v
 
This is a _heavily_ WIP repository for creating a 5th generation spin on https://github.com/40Cakes/pokebot-bizhawk. Any contributions or reported issues are heavily appreciated, as making this project widely compatible takes a lot of work.

### Supported games
|  | Black | White | Black 2 | White 2 | 
|--| :--: | :--: | :--: | :--: |
| English | ✅ | ✅ | ❌ | ❌ |
| Japanese| ❔ | ❔ | ❌ | ❌ |

## Requirements
The lua script comes with a dashboard which is heavily recommended, but also entirely optional. You can either run the Electron project directly from the repository, or download the project from Releases where dashboard.tar.gz is a standalone program. Run the dashboard before you would otherwise enable `pokebot-gen-v.lua` in the Lua Console in BizHawk.

The dashboard relies on net sockets which aren't enabled in BizHawk by default, so it's important that EmuHawk is executed with the arguments `--socket_ip=127.0.0.1 --socket_port=51055`. Either do this via a command line, or create a shortcut to EmuHawk.exe with the arguments added to the end of the 'target' field.

## To-do list
- [x] Dashboard with stats
- [ ] Config page on dashboard
- [ ] Customisable target traits

### Game specific
#### Black/White
- [x] Starter resets
- [x] Random encounters
- [ ] Auto Catching
- [x] EXP grinding
- [x] Pickup item farming
- [ ] Phenomenon encounters
- [ ] Wild held item farming (Thief)
- [ ] Dust cloud item farming
- [x] Gift Pokemon resets (Dreamyard monkeys, Fossils)
- [x] Egg collecting and hatching
- [ ] Route 18 Larvesta hatch & resets
- [ ] Thundurus/Tornadus dex resets
- [ ] Swords of Justice resets
- [ ] Kyurem resets
- [ ] Fishing

#### Black 2/White 2
- [ ] Starter resets
- [ ] Random encounters
- [ ] Auto Catching
- [ ] EXP grinding
- [ ] Pickup item farming
- [ ] Phenomenon encounters
- [ ] Wild held item farming (Thief)
- [ ] Dust cloud item farming
- [ ] Static Pokemon resets (Braviary, Mandibuzz, Volcarona, Crustle, Jellicent)
- [ ] Hidden Grotto farming
- [ ] Gift Pokemon resets (Fossils, Magikarp)
- [ ] Egg collecting and hatching
- [ ] Swords of Justice resets
- [ ] Kyurem resets
- [ ] Latias/Latios resets
- [ ] Lake guardian resets
- [ ] Regi trio (and Regigigas) resets
- [ ] Cresselia resets
- [ ] Heatran resets
- [ ] Fishing