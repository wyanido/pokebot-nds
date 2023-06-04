# pokebot-gen-v
 
This is a _heavily_ WIP repository for creating a 5th generation spin on https://github.com/40Cakes/pokebot-bizhawk 

Add `pokebot-gen-v.lua` to the Lua Console in BizHawk to begin using it.

## Known Information
### Entity Positions
The position of every entity in the room is listed from address `0x252220` onwards in the Main RAM. 
- When a loading zone is triggered, all values are set to 0 and replaced with the new room's entities. 
- The player's index will always be the last item in the list after a loading zone. 
- When moving between maps that don't have a loading zone, the old map's entities are removed, but the player's index in the list remains the same. 
- When entities are removed from the current map, the indexes of other entities do not move to fill in the new gap, however new entities will fill in the first empty index in the list, filling in any gaps.
