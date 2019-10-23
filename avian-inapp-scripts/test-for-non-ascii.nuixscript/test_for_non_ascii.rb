script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled.")
    return
end

require File.join(main_directory,"utils","nx_utils")

gui_title = "Test for non-ASCII"

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
    
    items = current_selected_items
    
    if items.length > 1
        CommonDialogs.show_error("Please select only one item and run this script again.")
        puts("Please select only one item and run this script again.")
    else
        item = items[0]
        non_ascii = non_ascii_characters(item.name)
        
        if non_ascii.length == 0
            CommonDialogs.show_information("Name of item contains only ASCII characters")
        else
            CommonDialogs.show_information("Name of item contains the following non-ASCII characters: " + non_ascii.to_s)
        end
        
        puts("Script finished.")
    end
else
    puts("Script cancelled.")
end


def non_ascii_characters(string)
    if string.ascii_only
        return []
    elsif string.length == 1
        return [string[0]]
    else
        return non_ascii_characters(string[0..string.length/2-1])+non_ascii_characters(string[string.length/2..-1])
    end
end
