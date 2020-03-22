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
        /(.*\b)\s*\[(.*)\]/,        # Addresses like Example Exampleson [example@ex.com]
        /(.*\b)\s*\<(.*)\>/,        # Addresses like Example Exampleson <example@ex.com>
        /\'?\"?()(.*@.*\b)\'?\"?/,  # Addresses like example@ex.com or 'example@ex.com'
        /\'?\"?(.*\b)()\'?\"?/      # Addresses like Example Exampleson or 'Example Exampleson'
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

        FixUnidentifiedEmails::fix_unidentified_emails(case_data_dir, current_case, current_selected_items, progress_dialog, timer, communication_field_aliases, start_area_size, address_regexps) { |string| string.split(';').map(&:strip) }
        
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
