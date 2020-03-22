script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','..','setup.nuixscript','get_main_directory')

main_directory = get_main_directory(false)

unless main_directory
    puts('Script cancelled.')
    return
end

require File.join(main_directory,'utils','nx_utils')
# Progress messages.
require File.join(main_directory,'utils','utils')
# Timings.
require File.join(main_directory,'utils','timer')

require File.join(main_directory,'avian-inapp-scripts','find_unidentified_emails.nuixscript','find_unidentified_emails')

gui_title = 'Find Unidentified Emails'

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab('main_tab', 'Main')


main_tab.append_text_field('allowed_start_offset', 'Allowed start offset', '10')
main_tab.get_control('allowed_start_offset').set_tool_tip_text('Number of non-whitespace characters allowed before "from".')

main_tab.append_text_field('start_area_size', 'Start area size', '400')
main_tab.get_control('start_area_size').set_tool_tip_text('Size of the area from the start of the items content in which the email information must appear.')

main_tab.append_text_field('email_tag', 'Email tag', 'UnidentifiedEmail')
main_tab.get_control('email_tag').set_tool_tip_text('The tag given to all found emails.')


# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    
    # Make sure allowed start offset is not empty.
    if values['allowed_start_offset'].strip.empty?
        CommonDialogs.show_warning('Please provide an allowed start offset.', gui_title)
        next false
    else 
        allowed_start_offset = Integer(values['allowed_start_offset'].strip) rescue false
        if not allowed_start_offset or allowed_start_offset < 0
            CommonDialogs.show_warning('Allowed start offset must be a positive integer.', gui_title)
            next false
        end
    end

    # Make sure start area size is not empty.
    if values['start_area_size'].strip.empty?
        CommonDialogs.show_warning('Please provide a start area size.', gui_title)
        next false
    else 
        start_area_size = Integer(values['start_area_size'].strip) rescue false
        if not start_area_size or start_area_size < 0
            CommonDialogs.show_warning('Start area size must be a positive integer.', gui_title)
            next false
        end
    end

    if values['email_tag'].strip.empty?
        CommonDialogs.show_warning('Please provide an email tag.', gui_title)
        next false
    end

    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

# If dialog result is false, the user has cancelled.
if dialog.dialog_result == true
    Utils.print_progress('Running script...')
    
    timer = Timing::Timer.new
    timer.start('total')
    
    # values contains the information the user inputted.
    values = dialog.to_map

    allowed_start_offset = Integer(values['allowed_start_offset'])
    start_area_size = Integer(values['start_area_size'])
    email_tag = values['email_tag']

    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
        progress_dialog.set_sub_progress_visible(false)
        
        FindUnidentifiedEmails::find_unidentified_emails(current_case, current_selected_items, progress_dialog, timer, allowed_start_offset, start_area_size, email_tag)

        timer.stop('total')
        
        timer.print_timings
        
        progress_dialog.set_main_status_and_log_it('Script finished. Found ' + emails.length.to_s + ' emails.')

        CommonDialogs.show_information('Script finished.', gui_title)
        progress_dialog.set_completed
    end

    puts('Script finished.')
else
    puts('Script cancelled.')
end
