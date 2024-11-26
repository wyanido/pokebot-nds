-----------------------------------------------------------------------------
-- General bot methods for gen 6 games (XY, ORAS)
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------

function update_pointers()
    pointers = {
        map_header = 0x69F08EC,
        party_data = 0x74E7DA8,
        trainer_name = 0x74E7C74,
        -- Temporary
        battle_indicator = 0,
        trainer_id = 0
    }
end
