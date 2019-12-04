
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
# Logging.
require File.join(main_directory,"utils","utils")
# Timings.
require File.join(main_directory,"utils","timer")

gui_title = "Tag Weird Characters"

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab("main_tab", "Main")

main_tab.append_text_field('non_weird_characters', 'Accepted characters', "\u00C5\u00C6\u00D8\u00E5\u00E6\u00F8")
main_tab.get_control('non_weird_characters').set_tool_tip_text('These characters will not cause an item to be tagged.')

main_tab.append_text_field('tag_name', 'Tag name', 'NonASCIIName')
main_tab.get_control('tag_name').set_tool_tip_text('The name of the tag given. Will be prefixed with "Avian|"')


# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    
    # TODO: ADD CHECKS HERE
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

def weird_character?(char_code, accepted_char_codes)
    return char_code > 127 && !accepted_char_codes.include?(char_code)
end

# If dialog result is false, the user has cancelled.
if dialog.dialog_result == true
    puts("Running script...")
    
    timer = Timing::Timer.new
    
    # values contains the information the user inputted.
    values = dialog.to_map

    accepted_char_codes = values['non_weird_characters'].codepoints
    tag_name = values['tag_name']
    
    timer.start("total")
    
    ProgressDialog.for_block do |progress_dialog|
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
    
        items = current_case.search("")
        
        progress_dialog.set_main_status_and_log_it('Searching for items with weird characters...')
        progress_dialog.set_main_progress(0,items.size)
        timer.start("find_items")
        # Find items with weird characters.
        tag_items = items.select do |item|
            progress_dialog.increment_main_progress
            item.name.codepoints.any?{ |codepoint| weird_character?(codepoint, accepted_char_codes) }
        end
        timer.stop("find_items")
        
        bulk_annotater = utilities.get_bulk_annotater
        
        progress_dialog.set_main_status_and_log_it('Tagging items with weird characters...')
        timer.start("tag_items")
        bulk_annotater.add_tag(tag_name, tag_items)
        timer.stop("tag_items")
    
        timer.stop("total")
        
        script_finished_message = "Script finished. Found " + tag_items.size.to_s + " items with weird characters in name."
        progress_dialog.log_message(script_finished_message)
        CommonDialogs.show_information(script_finished_message, gui_title)
    
        timer.print_timings()

        progress_dialog.set_completed
    end
else
    puts("Script cancelled.")
end
