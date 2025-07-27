-----------------------------------------------------------------------------
-- Gen 4 script for hunting roaming Pokemon.
-- Place the bot in front of a roaming Pokemon, such as Mesprit, and 
-- it will interact with it and reset until its data is initialised to be shiny.
-- Author: wyanido
-----------------------------------------------------------------------------
hint_config_default("ot_override", false)
hint_config_default("tid_override", "000000")
hint_config_default("sid_override", "000000")

function main()
    local data
    local a_cooldown = 0
    local is_unencrypted = _ROM.version ~= "PT" -- Only Platinum encrypts roamer data after generating it 

    while not data do
        data = pokemon.read_data(pointers.roamer, is_unencrypted)

        if a_cooldown == 0 then
            press_button_async("A")
            a_cooldown = math.random(5, 20)
        else
            a_cooldown = a_cooldown - 1
        end

        wait_frames(1)
    end

    local mon = pokemon.parse_data(data, true)

    if _CONFIG.ot_override then
        mon.otSID = tonumber(_CONFIG.sid_override) -- SID is not generated during initial encounter. This will prevent false flagging.
        mon.otID = tonumber(_CONFIG.sid_override) -- Sets the ID as well for those who are overriding it from their usual TID.
    end

    local is_target = pokemon.log_encounter(mon)
    
    if mon.name == "Unown" then
        abort("Please clear the journal and then save to resume.") -- The journal is read as 'Unown'. This will stop pointless resets.
    end
    
    if is_target then
        abort(mon.name .. " is a target!")
    else
        soft_reset()
    end
end
