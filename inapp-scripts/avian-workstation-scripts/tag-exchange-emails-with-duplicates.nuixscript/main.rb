script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

gui_title = 'Tag Exchange Emails with Duplicates'

# gui_title is the name given to all GUI elements created by the InAppScript.
unless script = Script::create_inapp_script(setup_directory, gui_title, 'tag_exchange_emails_with_duplicates', current_case, utilities)
    STDERR.puts('Could not find main directory.')
    return
end

# Main directory path can be found in script.main_directory.
# Add requires here.
# Main logic.
require File.join(script.main_directory,'inapp-scripts','tag-exchange-emails-with-duplicates','tag_exchange_emails_with_duplicates')

# Setup GUI here.
# Fields added using InAppScript methods are saved automatically.
# The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
# To add default values, create a default settings file.
script.dialog_add_tab('main_tab', 'Main')

# Add text field for archived email prefix.
script.dialog_append_text_field('main_tab', 'archived_prefix', 'Archived email prefix', 
        'All emails containing this text will be treated as exchange server emails.')

# Add text field for archived email tag.
script.dialog_append_text_field('main_tab', 'archived_tag', 'Archived email tag', 
        'All emails containing the above prefix will receive this tag.')

# Add text field for tag for archived emails with duplicates.
script.dialog_append_text_field('main_tab', 'archived_has_duplicate_tag', 'Tag for archived emails with duplicates', 
        'All archived emails with duplicates will receive this tag.')

# Add text field for tag for archived emails missing a duplicate.
script.dialog_append_text_field('main_tab', 'archived_missing_duplicate_tag', 'Tag for archived emails missing a duplicate', 
        'All archived emails without duplicates will receive this tag.')
        
# Add text field for tag for archived emails missing a duplicate.
script.dialog_append_text_field('main_tab', 'has_missing_attachments_tag', 'Tag for archived emails with missing attachments', 
        'All archived emails with children but no duplicate receive this tag.')
        
# Add text field for tag for archived emails missing a duplicate.
script.dialog_append_check_box('main_tab', 'exclude_archived_items_with_duplicates', 'Whether to exclude archived emails with duplicates', 
        'All archived emails with duplicates will be excluded if this is set to true.')


# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|
    archived_prefix = script.settings['archived_prefix']
    archived_tag = script.settings['archived_tag']
    archived_has_duplicate_tag = script.settings['archived_has_duplicate_tag']
    archived_missing_duplicate_tag = script.settings['archived_missing_duplicate_tag']
    has_missing_attachments_tag = script.settings['has_missing_attachments_tag']
    exclude_archived_items_with_duplicates = script.settings['exclude_archived_items_with_duplicates']

    script.timer.start('total')
    num_without_duplicate, num_missing_attachments = TagExchangeEmailsWithDuplicates::tag_exchange_emails_with_duplicates(
            current_case, 
            progress_dialog, 
            script.timer, 
            utilities, 
            archived_prefix, 
            archived_tag, 
            archived_has_duplicate_tag, 
            archived_missing_duplicate_tag, 
            has_missing_attachments_tag, 
            exclude_archived_items_with_duplicates
    )

    # Tell the user if emails without archived duplicates were found.
    if num_without_duplicate > 0
        progress_dialog.log_message("Archived emails without a duplicate: " + num_without_duplicate.to_s)
        CommonDialogs.show_information("A total of " + num_without_duplicate.to_s + " archived emails without a duplicate were found.")
    end
    # Tell the user if missing attachments were detected.
    if num_missing_attachments > 0
        progress_dialog.log_message("Missing attachments: " + num_missing_attachments.to_s)
        CommonDialogs.show_information("A total of " + num_missing_attachments.to_s + " missing attachments were detected.")
    end

    script.timer.stop('total')
end
