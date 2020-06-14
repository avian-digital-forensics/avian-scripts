script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

gui_title = 'Find and Fix Unidentified Emails'
# SCRIPT_NAME should be of the form inapp_gui_template2.
unless script = Script::create_inapp_script(setup_directory, gui_title, 'unidentified_emails', current_case, utilities)
    return
end

require File.join(script.main_directory,'avian-inapp-scripts','unidentified-emails.nuixscript','find_unidentified_emails')

require File.join(script.main_directory,'avian-inapp-scripts','unidentified-emails.nuixscript','fix_unidentified_emails')

# Add find tab.
script.dialog_add_tab('find_tab', 'Find Unidentified Emails')

script.dialog_append_check_box('find_tab', 'find_unselected_items', 'Run on unselected items',
        'Whether to run the script only on selected items, or to run the script on the result of a preliminary search.')

script.dialog_append_text_field('find_tab', 'allowed_start_offset', 'Allowed start offset', 
        'Number of non-whitespace characters allowed before "from".')

script.dialog_append_text_field('find_tab', 'start_area_line_num', 'Start area size', 
        'The number of lines from the start of the items content in which the email information must appear.')

script.dialog_append_text_field('find_tab', 'email_tag', 'Email tag', 
        'The tag given to all found emails. "Avian|" will automatically be added as prefix.')

# Add fix tab.
script.dialog_add_tab('fix_tab', 'Fix Unidentified Emails')

script.dialog_append_check_box('fix_tab', 'fix_unselected_items', 'Run on unselected items',
        'Whether to run the script only on selected items, or to ignore selection.')

script.dialog_append_check_box('fix_tab', 'fix_rfc_items', 'Run on RFC mails',
        'Whether to run the script on all (selected) RFC mails or only items identified by the Find Unidentified Emails script.')
        
script.dialog_append_check_box('fix_tab', 'export_printed_images', 'Export printed images',
        'Whether to export printed images for items whose types change. This can then be used by a WSS to keep the images on reload.')

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

    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

    timer = script.timer
    
    find_unselected_items = script.settings['find_unselected_items']
    allowed_start_offset = Integer(script.settings['allowed_start_offset'])
    start_area_line_num = Integer(script.settings['start_area_line_num'])
    email_tag = script.settings['email_tag']

    fix_unselected_items = script.settings['fix_unselected_items']
    fix_rfc_items = script.settings['fix_rfc_items']
    email_mime_type = 'message/rfc822'

    export_printed_images = script.settings['export_printed_images']

    bulk_annotater = utilities.get_bulk_annotater
        
    # Find which items to run on.
    if find_unselected_items
        progress_dialog.set_main_status_and_log_it('Making preliminary search...')
        items = FindUnidentifiedEmails::preliminary_search(current_case, progress_dialog, timer)
    else
        progress_dialog.log_message('Using selection. Skipping preliminary search.')
        items = current_selected_items
    end
    
    num_emails = FindUnidentifiedEmails::find_unidentified_emails(current_case, items, progress_dialog, timer, allowed_start_offset, start_area_line_num, email_tag, bulk_annotater)
    
    progress_dialog.log_message('Found ' + num_emails.to_s + ' emails.')

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

    progress_dialog.set_main_status_and_log_it('Identifying which items to process...')

    # Create set of items to be processed.
    items = Set[]
    rfc_tag = script.to_script_tag('RFC822')
    if fix_unselected_items
        items.merge(current_case.search("tag:\"Avian|#{email_tag}\""))
        if fix_rfc_items
            rfc_items = FixUnidentifiedEmails::find_rfc_mails(current_case)
            script.create_temporary_tag(rfc_tag, rfc_items, 'RFC822 items', progress_dialog)
            items.merge(current_case.search('tag:"' + rfc_tag + '"'))
        end
    else
        selected_items_tag = script.to_script_tag('SelectedItems')
        script.create_temporary_tag(selected_items_tag, current_selected_items, 'selected items', progress_dialog)
        items.merge(current_case.search("tag:\"Avian|#{email_tag}\" AND tag:\"#{selected_items_tag}\""))
        if fix_rfc_items
            rfc_items = FixUnidentifiedEmails::find_rfc_mails(current_case)
            script.create_temporary_tag(rfc_tag, rfc_items, 'RFC822 items', progress_dialog)
            items.merge(current_case.search("tag:\"#{rfc_tag}\" AND tag:\"#{selected_items_tag}\""))
        end
    end

    # Find the case data directory.
    case_data_dir = SettingsUtils::case_data_dir(script.main_directory, current_case.name, current_case.guid)

    progress_dialog.log_message('Found ' + items.size.to_s + ' items to process.')
    timer.start('fix_unidentified_emails')
    FixUnidentifiedEmails::fix_unidentified_emails(case_data_dir, current_case, items, progress_dialog, timer, utilities, communication_field_aliases, start_area_line_num, rfc_tag, address_regexps, email_mime_type, export_printed_images) { |string| string.split(/[,;]\s/).map(&:strip) }
    timer.stop('fix_unidentified_emails')

    # No script finished message.
    ''
end
