while true do
    joypad.set(input)
    process_frame()
    clear_unheld_inputs()
    main()
end