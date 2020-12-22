# Standard code for finding main directory.
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled.")
    return
end

# For GUI.
require File.join(main_directory,"utils","nx_utils")
# Timings.
require File.join(main_directory,'utils','timer')
# Progress messages.
require File.join(main_directory,'utils','utils')
# Actual script.
require File.join(main_directory,'inapp-scripts','number-of-descendants','number_of_descendants')

gui_title = "Number of Descendants"

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.addTab("main_tab", "Main")

# Add a text field for the custom metadata name.
main_tab.appendTextField("metadata_key", "Custom metadata name", "NumberOfDescendants")
main_tab.getControl("metadata_key").setToolTipText("The metadata field items receive will have this name.")


# Checks the input before closing the dialog.
dialog.validateBeforeClosing do |values|
    
    unless NXUtils.assert_non_empty_field(values, "metadata_key", "custom metadata name")
        next false
    end
    
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
    
    metadata_key = values["metadata_key"]
    
    timer = Timing::Timer.new

    timer.start('total')
    
    items = current_selected_items

    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end

        NumberOfDescendants::number_of_descendants(current_case, progress_dialog, timer, items, metadata_key, utilities.bulk_annotater)

        timer.stop('total')
        
        timer.print_timings
        
        progress_dialog.set_completed
        finish_message = 'Script finished.'
        CommonDialogs.show_information(finish_message, gui_title)
        Utils.print_progress(finish_message)
    end

    
    
    # Tell the user the script has finished.
    CommonDialogs.show_information("Script finished." , gui_title)
    
    puts("Script finished.")
else
    puts("Script cancelled.")
end
