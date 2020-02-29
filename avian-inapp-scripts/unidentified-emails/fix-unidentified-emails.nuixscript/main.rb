script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','setup.nuixscript','get_main_directory')

main_directory = get_main_directory(false)

unless main_directory
    puts('Script cancelled because no main directory could be found.')
    return
end

# For GUI.
require File.join(main_directory,'utils','nx_utils')
# Timings.
require File.join(main_directory,'utils','timer')
# Progress messages.
require File.join(main_directory,'utils','utils')

require File.join(main_directory,'avian-inapp-scripts','fix_unidentified_emails.nuixscript','fix_unidentified_emails')

gui_title = # TODO: EDIT

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab('main_tab', 'Main')

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
if dialog.dialog_result
    Utils.print_progress('Running script...')
    
    # values contains the information the user inputted.
    values = dialog.to_map

    timer = Timing::Timer.new

    timer.start('total')
    
    address_splitter = lambda do |string|
        string.split(',')
    end

    FixUnidentifiedEmails::fix_unidentified_emails(current_case, current_selected_items, progress_dialog, timer, communication_field_aliases, start_area_size, &address_splitter, address_regexps)
    
    timer.stop('total')
    timer.print_timings
    
    CommonDialogs.show_information('Script finished.', gui_title)
    
    Utils.print_progress('Script finished.')
else
    Utils.print_progress('Script cancelled.')
end
