script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled.")
    return
end

require File.join(main_directory,"utils","nx_utils")
require File.join(script_directory,'JavaTest.jar')

java_import 'JavaTest'

gui_title = 'Java Test'

JavaTest.println("Laks")

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab("main_tab", "Main")

# TODO: ADD GUI HERE


# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    
    # TODO: ADD CHECKS HERE
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

# If dialog result is false, the user has cancelled.
if dialog.dialog_result == true
    puts("Running script...")
    
    # values contains the information the user inputted.
    values = dialog.to_map
    
    # TODO: ADD SCRIPT HERE.
    
    CommonDialogs.show_information("Script finished. ", gui_title)
    
    puts("Script finished.")
else
    puts("Script cancelled.")
end
