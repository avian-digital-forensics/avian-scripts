script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

if not main_directory
    puts("Script cancelled.")
    return
end

require File.join(main_directory,"utils","nx_utils")
require File.join(main_directory,"utils","key_list")

gui_title = # TODO: EDIT

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.addTab("main_tab", "Main")

# TODO: ADD GUI HERE

key_list = EntityKeyList("Test", "Jeg", ["Jeg", "jeg", "Mig", "mig", "Vi", "vi"])


# Checks the input before closing the dialog.
dialog.validateBeforeClosing do |values|
    
    # TODO: ADD CHECKS HERE
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

# If dialog result is false, the user has cancelled.
if dialog.getDialogResult == true
    puts("Running script...")
    
    # values contains the information the user inputted.
    values = dialog.toMap
    
    emails = current_case.search("kind:email")
    
    
    
    CommonDialogs.show_information("Script finished. , gui_title)#TODO: ADD USER MESSAGE 
    
    puts("Script finished.")
else
    puts("Script cancelled.")
end
