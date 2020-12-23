# Gets the main Avian scripts directory path.
# First checks if it is in the file 'root_directory.txt' in the setup script's directory, otherwise asks user.
# If force_user_input is true, always asks user.
# If the user is asked, the result is written to 'root_directory.txt'.
# If the user cancels, returns nil.
def get_root_directory(force_user_input)
    root_directory = ""

    script_directory = File.dirname(__FILE__)
    # The path to the setup script's directory.
    setup_script_directory = File.join(script_directory,"..","setup.nuixscript")
    # The file that should contain the path to the main directory.
    root_directory_file_path = File.join(setup_script_directory,"root_directory.txt")
    if File.file?(root_directory_file_path)
        contents = File.read(root_directory_file_path)
        if File.file?(File.join(contents, "/wss_dispatcher.rb"))
            root_directory = contents
        end
    end

    # If main directory path is not in file or user input is forced, get main directory path from user.
    if root_directory == "" or force_user_input
        require File.join(script_directory,"..",'setup.nuixscript',"resources","Nx.jar")
        puts('Getting main script directory from user.')

        ## Create GUI.
        dialog = com.nuix.nx.dialogs.TabbedCustomDialog.new("Avian Main Script Directory")

        # Add main tab.
        main_tab = dialog.add_tab("main_tab", "Main")

        main_tab.append_directory_chooser("root_directory", "Avian main script directory")

        # Add information about the script.
        main_tab.append_information("script_description", "", "Please select the Avian main script directory. Not the one you copied into the Nuix directory, but the one you downloaded.")

        # Checks the input before closing the dialog.
        dialog.validate_before_closing do |values|
            input = values["root_directory"].strip
            if input.empty? # Make sure path is not empty.
                com.nuix.nx.dialogs.CommonDialogs.show_warning("Please provide a non-empty output path.", "No Output Path")
                next false
            elsif not File.file?(File.join(input, "/wss_dispatcher.rb")) # Make sure it is the right directory.
                com.nuix.nx.dialogs.CommonDialogs.show_warning("Wrong output directory selected. The directory required is the one with the file 'wss_dispatcher.rb'.")
                next false
            end
            # Everything is fine; close the dialog.
            next true
        end

        dialog.display
        
        if dialog.get_dialog_result == true
            root_directory = dialog.to_map["root_directory"]
            File.open(root_directory_file_path, "w") { |file| file.write(root_directory) }
        else
            root_directory = nil
        end
    end

    # Ensure that the main directory's inapp script directory also has a root_directory.txt file.
    if root_directory
        # The path to the root_directory.txt file in the main directory's inapp script directory.
        root_directory_root_directory_file_path = File.join(root_directory, 'inapp-scripts', 'avian-workstation-scripts', 'setup.nuixscript', 'root_directory.txt')
        if File.file?(root_directory_root_directory_file_path)
            contents = File.read(root_directory_root_directory_file_path)
            unless contents == root_directory
                raise 'The path in the root_directory\'s root_directory.txt is incorrect. This should be impossible.'
            end
        else
            File.open(root_directory_root_directory_file_path, "w") { |file| file.write(root_directory) }
        end
    end

    return root_directory
end
