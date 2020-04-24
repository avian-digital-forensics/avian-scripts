script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

gui_title = 'Find and Fix Unidentified Emails'
# SCRIPT_NAME should be of the form inapp_gui_template2.
unless script = Script::create_inapp_script(setup_directory, gui_title, 'find_and_fix')
    return
end

require File.join(script.main_directory,'avian-inapp-scripts','unidentified-emails','find-unidentified-emails.nuixscript','find_unidentified_emails')

require File.join(script.main_directory,'avian-inapp-scripts','unidentified-emails','fix-unidentified-emails.nuixscript','fix_unidentified_emails')

# Add main tab.
script.dialog_add_tab('main_tab', 'Main')

script.dialog_append_check_box('main_tab', 'process_unselected_rfc_mails', 'Process unselected RFC mails', 
        'Whether to process all RFC mail items in the case or only those in the selection.')

script.dialog_append_text_field('main_tab', 'allowed_start_offset', 'Allowed start offset', 
        'Number of non-whitespace characters allowed before "from".')

script.dialog_append_text_field('main_tab', 'start_area_line_num', 'Start area size', 
        'The number of lines from the start of the items content in which the email information must appear.')

script.dialog_append_text_field('main_tab', 'email_tag', 'Email tag', 
        'The tag given to all found emails. "Avian|" will automatically be added as prefix.')

# Add email MIME-type tab.
script.dialog_add_tab('email_mime_type_tab', 'Email MIME-type')

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
default_email_mime_type = 'message/rfc822'
email_mime_type_description = 'All found emails that a not already of kind email will be given the following MIME-type. Every one of the options indicates a specific type of email that probably won\'t fit for all items, so just choose the best available option.'
script.dialog_append_vertical_radio_button_group('email_mime_type_tab', 'email_mime_type', email_mime_type_description, email_mime_type_options)

# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|

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

    if values['email_mime_type'] == ''
        CommonDialogs.show_warning('Please provide a MIME-type for the non-RFC emails.', gui_title)
        next false
    end

    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

    timer = script.timer
    
    process_unselected_rfc_mails = script.settings['process_unselected_rfc_mails']
    allowed_start_offset = Integer(script.settings['allowed_start_offset'])
    start_area_line_num = Integer(script.settings['start_area_line_num'])
    email_tag = script.settings['email_tag']
    email_mime_type = script.settings['email_mime_type']

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
    case_data_dir = SettingsUtils::case_data_dir(script.main_directory, current_case)

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
    FixUnidentifiedEmails::fix_unidentified_emails(case_data_dir, current_case, items, progress_dialog, timer, communication_field_aliases, start_area_line_num, rfc822_tag, address_regexps, email_mime_type) { |string| string.split(/[,;]\s/).map(&:strip) }

    # Remove RFC822 tags.
    progress_dialog.set_main_status_and_log_it('Removing RFC822 tags...')
    timer.start('remove_rfc822_tag')
    bulk_annotater.remove_tag(rfc822_tag, current_case.search("\"tag:#{rfc822_tag}\""))
    timer.stop('remove_rfc822_tag')
    
    # No script finished message.
    ''
end
