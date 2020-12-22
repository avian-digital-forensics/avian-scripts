# Standard code for finding main directory.
script_directory = File.dirname(__FILE__)
require_relative File.join("..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled because no main directory could be found.")
    return
end

# For GUI.
require File.join(main_directory,"utils","nx_utils")
# Timings.
require File.join(main_directory,"utils","timer")
# Progress messages.
require File.join(main_directory,"utils","utils")


gui_title = 'Tag Messages Sent to Sender'

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab("main_tab", "Main")

dialog.validate_before_closing do |values|
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

    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
        progress_dialog.set_sub_progress_visible(false)

        timer.start('find_items_with_communication')
        # Find all items in case with a Communication.
        items = currentCase.search("has-communication:1")
        timer.stop('find_items_with_communication')

        progress_dialog.log_message("Found: " + items.length.to_s + " items with communication.")

        base_tag = "SentToSender"
        to_suffix = "To"
        cc_suffix = "Cc"
        bcc_suffix = "Bcc"

        numTo = 0
        numCc = 0
        numBcc = 0

        timer.start('process_items')
        progress_dialog.set_main_status_and_log_it('Processing items...')
        progress_dialog.set_main_progress(0,items.size)
        # Process every item with communication
        for item,item_index in items.each_with_index
            communication = item.communication
            from = communication.from[0]
            # Tag if the From is also in the To.
            if communication.to.any?{ |to| to && from && to.address == from.address }
                item.addTag(base_tag + to_suffix)
                numTo += 1
            end
            # Tag if the From is also in the Cc.
            if communication.cc.any?{ |cc| cc && from && cc.address == from.address }
                item.addTag(base_tag + cc_suffix)
                numCc += 1
            end
            # Tag if the From is also in the Bcc.
            if communication.bcc.any?{ |bcc| bcc && from && bcc.address == from.address }
                item.addTag(base_tag + bcc_suffix)
                numBcc += 1
            end
            progress_dialog.increment_main_progress
			progress_dialog.set_sub_status("#{item_index+1}/#{items.size}")
        end
        timer.stop('process_items')

        # Write result to console.
        progress_dialog.log_message("Found " + numTo.to_s + " items with from in to.")
        progress_dialog.log_message("Found " + numCc.to_s + " items with from in cc.")
        progress_dialog.log_message("Found " + numBcc.to_s + " items with from in bcc.")

        timer.stop('total')

        timer.print_timings()

        script_finished_message = "Script finished. Found " + numTo.to_s + " items with from in to. Found " + numCc.to_s + " items with from in cc. Found " + numBcc.to_s + ' items with from in bcc.'
        # Write result to GUI.
        progress_dialog.log_message(script_finished_message)
        CommonDialogs.show_information(script_finished_message, 'Tag Messages to Self')
    end
else
    Utils.print_progress('Script cancelled.')
end
