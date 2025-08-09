-----------------------------------------------------------------------------
-- HGSS script for playing Voltorb Flip optimally by cheating.
-- Author: wyanido
-----------------------------------------------------------------------------
local board_pointer = mdword(0x2111938) + 0x45FCC

local function proceed_text()
    while mdword(board_pointer - 0x4) ~= 0xA0 or mdword(board_pointer - 0x14) ~= 0 do 
        progress_text()
    end
end

local function flip_tile(x, y) 
    touch_screen_at(x * 30 - 10, y * 30 - 10) 
end

function main()
    board_pointer = mdword(0x2111938) + 0x45FCC

    -- The game corner doesn't let you play while holding the maximum of 50k coins
    local coin_count = mword(board_pointer - 0x69BA8)
    if coin_count == 50000 then abort("Can't earn any more coins") end

    proceed_text()

    local tile_index = 0

    -- Iterate through board and flip safe tiles
    for y = 1, 5, 1 do
        for x = 1, 5, 1 do
            local tile_pointer = board_pointer + tile_index * 12
            local tile_type = mdword(tile_pointer)
            local is_flipped = mdword(tile_pointer + 8)

            if (tile_type == 2 or tile_type == 3) and is_flipped == 0 then -- a tile_type of 4 is Voltorb
                -- Tap tile until game registers the flip
                while is_flipped == 0 do
                    is_flipped = mdword(tile_pointer + 8)

                    proceed_text()

                    flip_tile(x, y)
                    wait_frames(4)
                end

                press_button("A")
                wait_frames(8)
            end

            tile_index = tile_index + 1
        end
    end

    press_sequence("A", 9)
end
