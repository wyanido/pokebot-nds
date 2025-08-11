-----------------------------------------------------------------------------
-- Gen 4 script for hunting roaming Pokemon.
-- Place the bot in front of a roaming Pokemon, such as Mesprit, and 
-- it will interact with it and reset until its data is initialised to be shiny.
-- Author: wyanido
-----------------------------------------------------------------------------
function main()
    local mon
    local a_cooldown = 0
    local is_unencrypted = _ROM.version ~= "PT" -- Only Platinum encrypts roamer data after generating it 

    while not mon do
        mon = pokemon.parse_data(pointers.roamer, is_unencrypted)

        if a_cooldown == 0 then
            press_button_async("A")
            a_cooldown = math.random(5, 20)
        else
            a_cooldown = a_cooldown - 1
        end

        wait_frames(1)
    end

    if config.ot_override then
        mon.OT.SID = tonumber(config.sid_override) -- SID is not generated during initial encounter. This will prevent false flagging.
        mon.OT.TID = tonumber(config.sid_override) -- Sets the ID as well for those who are overriding it from their usual TID.
    end

    local is_target = pokemon.is_target(mon)
    pokemon.log_encounter(mon)
    
    if mon.Species.Name == "Unown" then
        abort("Please clear the journal and then save to resume.") -- The journal is read as 'Unown'. This will stop pointless resets.
    end
    
    if is_target then
        abort(mon.Species.Name .. " is a target!")
    else
        soft_reset()
    end
end
