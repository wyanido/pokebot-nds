-----------------------------------------------------------------------------
-- Bot method overrides for HGSS
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------

function update_pointers()
    local anchor = mdword(0x21D4158 + _ROM.offset)
    local foe_anchor = mdword(anchor + 0x6930)
    local bag_page_anchor = mdword(anchor + 0x348C4)
    
    pointers = {
        -- items_pocket
        -- medicine_pocket
        poke_balls_pocket = anchor - 0x232D4,
        -- tms_hms_pocket
        -- berries_pocket
        -- mail_pocket
        -- battle_items_pocket
        -- key_items_pocket 

        party_count = anchor - 0x23F44,
        party_data  = anchor - 0x23F40,
        
        foe_count   = foe_anchor + 0xC14,
        current_foe = foe_anchor + 0xC18,

        map_header  = anchor - 0x22DA4,
        trainer_x   = 0x21DA6F4 + _ROM.offset,
        trainer_y   = 0x21DA6F8 + _ROM.offset,
        trainer_z   = 0x21DA6FC + _ROM.offset,
        facing      = anchor + 0x1DC4,

        bike = anchor - 0x22D34,

        daycare_egg = anchor - 0x22804,

        battle_menu_state      = anchor + 0x230EC, -- 01 is FIGHT menu, 04 is Move Select, 08 is Bag,
        battle_menu_state2     = anchor + 0x40281,
        battle_indicator       = 0x21E76D2 + _ROM.offset,
        fishing_bite_indicator = 0x21DD853 + _ROM.offset,

        easy_chat_open           = anchor + 0x28644,
        easy_chat_category_sizes = anchor + 0x200C4,
        easy_chat_word_list      = anchor + 0x20124,
        battle_bag_page          = bag_page_anchor + 0x4E,
        trainer_name = anchor - 0x23F74,
        trainer_id   = anchor - 0x23F64,

        starter_data = anchor + 0x1BC00
        -- registered_key_item_1 = anchor - 0x231FC,
    }
end

--- Opens the menu and selects the specified option.
-- @param menu Name of the menu to open
function open_menu(menu)
    wait_frames(30)
    
    if menu == "Pokedex" then
        touch_screen_at(45, 35)
    elseif menu == "Pokemon" then
        touch_screen_at(45, 75)
    elseif menu == "Bag" then
        touch_screen_at(45, 115)
    elseif menu == "Trainer" then
        touch_screen_at(125, 35)
    elseif menu == "Save" then
        touch_screen_at(125, 75)
    elseif menu == "Options" then
        touch_screen_at(125, 115)
    end
    
    wait_frames(90)
end

--- Navigates to the Route 34 daycare and releases all hatched Pokemon in the party.
function release_hatched_duds()
    local function release(i)
        local x = 40 + 40 * ((i - 1) % 2)
        local y = 70 + 30 * math.floor((i - 1) / 2)
        
        touch_screen_at(x, y)
        wait_frames(30)
        touch_screen_at(228, 144)
        wait_frames(30)
        touch_screen_at(222, 109)
        wait_frames(100)
        press_button("B")
        wait_frames(15)
        press_button("B")
        wait_frames(15)
    end

    clear_all_inputs()
    
    -- Enter Daycare and release all Lv 1 Pokemon from party
    move_to({z=411})
    move_to({x=368})
    
    hold_button("Up")
    wait_frames(30)
    release_button("Up")
    wait_frames(90)
    
    hold_button("B")
    move_to({x=1,z=8})
    clear_all_inputs()

    -- Open PARTY PKMN menu
    wait_frames(20)
    press_sequence("A", 80, "A", 80, "A", 80, "A", 40)
    touch_screen_at(62, 94)
    wait_frames(150) -- Box loading time increases with data size
    touch_screen_at(46, 177)
    wait_frames(60)

    for i = 5, 1, -1 do
        if pokemon.is_hatched_dud(game.party()[i]) then 
            release(i)
        end
    end

    press_sequence("B", 40, "B", 20, "B", 150, "B", 90, "B", 90)

    -- Exit Daycare
    hold_button("B")
    move_to({x=3})
    move_to({z=12})
    wait_frames(60)
    clear_all_inputs()
    
    -- Return to long vertical path
    press_sequence(120, "Y", 5)
    move_to({x=358})
end

--- Returns the current stage of the battle as a simple string
function get_battle_state()
    if not game.in_battle() then
        return nil
    end

    if mbyte(pointers.battle_menu_state2) == 0x2F then
        return "New Move"
    end

    local state = mbyte(pointers.battle_menu_state)
    
    if state == 0x1 then
        return "Menu"
    elseif state == 0x4 then
        return "Fight"
    elseif state == 0x8 then
        return "Bag"
    elseif state == 0xA then
        return "Pokemon"
    end

    return nil
end
