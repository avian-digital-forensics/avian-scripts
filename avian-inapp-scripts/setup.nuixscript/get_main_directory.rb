# Gets the main Avian scripts directory path.
# First checks if it is in the file 'main_directory.txt' in the setup script's directory, otherwise asks user.
# If force_user_input is true, always asks user.
# If the user is asked, the result is written to 'main_directory.txt'.
# If the user cancels, returns nil.
def get_main_directory(force_user_input)
    main_directory = ""

    script_directory = File.dirname(__FILE__)
    # The path to the setup script's directory.
    setup_script_directory = File.join(script_directory,"..","setup.nuixscript")
    # The file that should contain the path to the main directory.
    main_directory_file_path = File.join(setup_script_directory,"main_directory.txt")
    if File.file?(main_directory_file_path)
        contents = File.read(main_directory_file_path)
        if File.file?(File.join(contents, "/wss_dispatcher.rb"))
            main_directory = contents
        end
    end

    # If main directory path is not in file or user input is forced, get main directory path from user.
    if main_directory == "" or force_user_input
        require File.join(setup_script_directory,"utils","nx_utils")

        ## Create GUI.
        dialog = TabbedCustomDialog.new("Avian Main Script Directory")

        # Add main tab.
        main_tab = dialog.add_tab("main_tab", "Main")

        main_tab.append_directory_chooser("main_directory", "Avian main script directory")

        # Add information about the script.
        main_tab.append_information("script_description", "", "Please select the Avian main script directory. Not the one you copied into the Nuix directory, but the one you downloaded.")

        # Checks the input before closing the dialog.
        dialog.validate_before_closing do |values|
            input = values["main_directory"].strip
            if input.empty? # Make sure path is not empty.
                CommonDialogs.show_warning("Please provide a non-empty output path.", "No Output Path")
                next false
            elsif not File.file?(File.join(input, "/wss_dispatcher.rb")) # Make sure it is the right directory.
                CommonDialogs.show_warning("Wrong output directory selected. The directory required is the one with the file 'wss_dispatcher.rb'.")
                next false
            end
            # Everything is fine; close the dialog.
            next true
        end

        dialog.display
        
        if dialog.get_dialog_result == true
            main_directory = dialog.to_map["main_directory"]
            File.open(main_directory_file_path, "w") { |file| file.write(main_directory) }
        else
            main_directory = nil
        end
    end
    return main_directory
end
