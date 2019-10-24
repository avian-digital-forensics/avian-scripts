
# Standard code for finding main directory.
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled.")
    return
end

# GUI.
require File.join(main_directory,"utils","nx_utils")
# Timings.
require File.join(main_directory,"utils","timer")

gui_title = "Tag Weird Characters"

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

def weird_character?(char_code)
    return char_code > 127 && ![198, 216, 197, 230, 248, 229].include?(char_code)
end

# If dialog result is false, the user has cancelled.
if dialog.dialog_result == true
    puts("Running script...")
    
    timer = Timing::Timer.new
    
    # values contains the information the user inputted.
    values = dialog.to_map
    
    timer.start("total")
    
    items = current_case.search("")
    
    timer.start("find_items")
    tag_items = items.select{ |item| item.name.codepoints.any? { |char_code| weird_character?(char_code) } }
    timer.stop("find_items")
    
    tag = "Avian|NonASCIIName"
    
    bulk_annotater = utilities.get_bulk_annotater
    
    timer.start("tag_items")
    bulk_annotater.add_tag(tag, tag_items)
    timer.stop("tag_items")
    
    timer.stop("total")
    
    CommonDialogs.show_information("Script finished.", gui_title)
    
    timer.print_timings()
    
    puts("Script finished.")
else
    puts("Script cancelled.")
end
