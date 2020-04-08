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

require File.join(main_directory,'avian-inapp-scripts','unidentified-emails','fix-unidentified-emails.nuixscript','fix_unidentified_emails')

gui_title = 'Fix Unidentified Emails'

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab('main_tab', 'Main')

# List of possible email MIME-type options.
email_mime_types = ['application/pcm-email', 
                    'application/pdf-mail', 
                    'application/vnd.hp-trim-email', 
                    'application/vnd.lotus-domino-xml-mail-document', 
                    'application/vnd.lotus-notes-document', 
                    'application/vnd.ms-entourage-message', 
                    'application/vnd.ms-outlook-item', 
                    'application/vnd.ms-outlook-mac-email', 
                    'application/vnd.ms-outlook-note', 
                    'application/vnd.rim-blackberry-email', 
                    'application/vnd.rim-blackberry-sms', 
                    'application/vnd.rimarts-becky-email', 
                    'application/x-microsoft-restricted-permission-message', 
                    'message/rfc822', 
                    'message/rfc822-headers', 
                    'message/x-scraped']

# The options for the MIME-type.
email_mime_type_options = {}
for email_mime_type in email_mime_types
    email_mime_type_options[email_mime_type] = email_mime_type
end

# Add radio buttons for MIME-type choice.
main_tab.append_radio_button_group('Email MIME-type', 'email_mime_type', email_mime_type_options)
main_tab.get_control('email_mime_type').set_tool_tip_text('The MIME-type given to all items found to be emails that are not already seen as such by NUIX.')


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

    email_mime_type = values['email_mime_type']
    
    communication_field_aliases = {
        :date => ['date', 'Date', 'dato', 'Dato', 'sendt', 'Sendt', 'modtaget', 'Modtaget'],
        :subject => ['subject', 'Subject', 'emne', 'Emne'],
        :from => ['from', 'From', 'fra', 'Fra', 'afsender', 'Afsender'],
        :to => ['to', 'To', 'til', 'Til', 'modtager', 'Modtager'],
        :cc => ['cc', 'Cc'],
        :bcc => ['bcc', 'Bcc']
    }
    
    start_area_size = 400
    
	address_regexps = [
		/\'?\"?(.*?)\'?\"?\s*\[(.*)\]$/,	# Addresses like Example Exampleson [example@ex.com]
		/\'?\"?(.*?)\'?\"?\s*\<(.*)\>$/,	# Addresses like Example Exampleson <example@ex.com>
		/\'?\"?()(.*@.*?)\'?\"?$/,  		# Addresses like example@ex.com or 'example@ex.com'
		/\'?\"?()(.*?)\'?\"?$/      		# Addresses like Example Exampleson or 'Example Exampleson'
	]

    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
        progress_dialog.set_sub_progress_visible(false)

        # Find the case data directory.
        case_data_dir = SettingsUtils::case_data_dir(main_directory, current_case)
		
		# Add tags so RFC822 items don't have their text searched.
		progress_dialog.set_main_status_and_log_it('Adding tag to RFC822 items...')
		timer.start('add_rfc822_tag')
		rfc822_tag = 'Avian|UnidentifiedEmails|RFC822'
		bulk_annotater = utilities.get_bulk_annotater
		bulk_annotater.add_tag(rfc822_tag, FixUnidentifiedEmails::find_rfc_mails(current_case))
		timer.stop('add_rfc822_tag')

        FixUnidentifiedEmails::fix_unidentified_emails(case_data_dir, current_case, current_selected_items, progress_dialog, timer, communication_field_aliases, start_area_size, rfc822_tag, address_regexps, email_mime_types) { |string| string.split(/[,;]\s/).map(&:strip) }
        
		# Remove RFC822 tags.
		progress_dialog.set_main_status_and_log_it('Removing RFC822 tags...')
		timer.start('remove_rfc822_tag')
		bulk_annotater.remove_tag(rfc822_tag, current_case.search("tag:#{rfc822_tag}"))
        timer.stop('remove_rfc822_tag')
        
        timer.stop('total')
        timer.print_timings

        finish_string = 'Script finished'
        
        progress_dialog.set_main_status_and_log_it(finish_string)
        
        CommonDialogs.show_information(finish_string, gui_title)
        progress_dialog.set_completed
    end
    
    Utils.print_progress('Script finished.')
else
    Utils.print_progress('Script cancelled.')
end
