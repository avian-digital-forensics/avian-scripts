script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','..','setup.nuixscript','get_main_directory')

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

require File.join(main_directory,'utils','utils')

require File.join(main_directory,'avian-inapp-scripts','unidentified-emails','find-unidentified-emails.nuixscript','find_unidentified_emails')

require File.join(main_directory,'avian-inapp-scripts','unidentified-emails','fix-unidentified-emails.nuixscript','fix_unidentified_emails')


gui_title = 'Find and Fix Unidentified Emails'

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab('main_tab', 'Main')

main_tab.append_check_box('process_unselected_rfc_mails', 'Process unselected RFC mails', true)
main_tab.get_control('process_unselected_rfc_mails').set_tool_tip_text('Whether to process all RFC mail items in the case or only those in the selection.')

main_tab.append_text_field('allowed_start_offset', 'Allowed start offset', '10')
main_tab.get_control('allowed_start_offset').set_tool_tip_text('Number of non-whitespace characters allowed before "from".')

main_tab.append_text_field('start_area_line_num', 'Start area size', '15')
main_tab.get_control('start_area_line_num').set_tool_tip_text('The number of lines from the start of the items content in which the email information must appear.')

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
    if values['start_area_line_num'].strip.empty?
        CommonDialogs.show_warning('Please provide a start area size.', gui_title)
        next false
    else 
        start_area_line_num = Integer(values['start_area_line_num'].strip) rescue false
        if not start_area_line_num or start_area_line_num < 0
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
if dialog.dialog_result
    Utils.print_progress('Running script...')
    
    # values contains the information the user inputted.
    values = dialog.to_map

    timer = Timing::Timer.new
    timer.start('total')

    process_unselected_rfc_mails = values['process_unselected_rfc_mails']
    allowed_start_offset = Integer(values['allowed_start_offset'])
    start_area_line_num = Integer(values['start_area_line_num'])
    email_tag = values['email_tag']
    
    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
        progress_dialog.set_sub_progress_visible(false)
        
        bulk_annotater = utilities.get_bulk_annotater
        
        # Find which items to run on.
        progress_dialog.set_main_status_and_log_it('Making preliminary search...')
        if current_selected_items.size > 0 
            # If items are selected, run on those.
            progress_dialog.log_message('Using selection. Skipping preliminary search.')
            items = current_selected_items
        else
            # If not, do a specific search.
            items = FindUnidentifiedEmails::preliminary_search(current_case, progress_dialog, timer)
        end
		
        num_emails = FindUnidentifiedEmails::find_unidentified_emails(current_case, items, progress_dialog, timer, allowed_start_offset, start_area_line_num, email_tag, bulk_annotater)
        
        progress_dialog.log_message('Found ' + num_emails.to_s + ' emails.')
        progress_dialog.set_main_status_and_log_it('Identifying which items to process...')

        # Create set of items to be processed.
        items = current_case.search("tag:\"Avian|#{email_tag}\"").to_set
        if process_unselected_rfc_mails
            items.merge(FixUnidentifiedEmails::find_rfc_mails(current_case))
        end

        # Find the case data directory.
        case_data_dir = SettingsUtils::case_data_dir(main_directory, current_case)

        communication_field_aliases = {
            :date => ['date', 'Date', 'dato', 'Dato', 'sendt', 'Sendt', 'modtaget', 'Modtaget'],
            :subject => ['subject', 'Subject', 'emne', 'Emne'],
            :from => ['from', 'From', 'fra', 'Fra', 'afsender', 'Afsender'],
            :to => ['to', 'To', 'til', 'Til', 'modtager', 'Modtager'],
            :cc => ['cc', 'Cc'],
            :bcc => ['bcc', 'Bcc']
        }
    
        address_regexps = [
            /\'?\"?(.*?)\'?\"?\s*\[(.*)\]$/,	# Addresses like Example Exampleson [example@ex.com]
            /\'?\"?(.*?)\'?\"?\s*\<(.*)\>$/,	# Addresses like Example Exampleson <example@ex.com>
            /\'?\"?()(.*@.*?)\'?\"?$/,  		# Addresses like example@ex.com or 'example@ex.com'
            /\'?\"?()(.*?)\'?\"?$/      		# Addresses like Example Exampleson or 'Example Exampleson'
        ]
		
		# Add tags so RFC822 items don't have their text searched.
		progress_dialog.set_main_status_and_log_it('Adding tag to RFC822 items...')
		timer.start('add_rfc822_tag')
		rfc822_tag = 'Avian|UnidentifiedEmails|RFC822'
		bulk_annotater = utilities.get_bulk_annotater
		bulk_annotater.add_tag(rfc822_tag, FixUnidentifiedEmails::find_rfc_mails(current_case))
		timer.stop('add_rfc822_tag')

        progress_dialog.log_message('Found ' + items.size.to_s + ' items to process.')
        FixUnidentifiedEmails::fix_unidentified_emails(case_data_dir, current_case, items, progress_dialog, timer, communication_field_aliases, start_area_line_num, rfc822_tag, address_regexps) { |string| string.split(/[,;]\s/).map(&:strip) }

		# Remove RFC822 tags.
		progress_dialog.set_main_status_and_log_it('Removing RFC822 tags...')
		timer.start('remove_rfc822_tag')
		bulk_annotater.remove_tag(rfc822_tag, current_case.search("\"tag:#{rfc822_tag}\""))
        timer.stop('remove_rfc822_tag')

        timer.stop('total')
        
        timer.print_timings
        
        progress_dialog.set_main_status_and_log_it('Script finished.')

        CommonDialogs.show_information('Script finished.', gui_title)
        progress_dialog.set_completed
    end
    
    Utils.print_progress('Script finished.')
else
    Utils.print_progress('Script cancelled.')
end
