-----------------------------------------------------------------------------
-- General bot methods for gen 6 games (XY, ORAS)
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------

function update_pointers()
    pointers = {
        map_header = 1,
        battle_indicator = 0,
        party_data = 0x74E7DA8
    }
end
