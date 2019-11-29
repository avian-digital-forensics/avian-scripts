script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','setup.nuixscript','get_main_directory')

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

def is_email?(item, allowed_start_offset, start_area_size)
    raise ArgumentError, 'Item must contain text' unless item.text_object
    trimmed_content = item.text_object.to_s[0..start_area_size].strip

    # Find email start.
    if trimmed_content[0..allowed_start_offset+5].include?('From')
        from_index = trimmed_content.index('From')
        english = true
    elsif trimmed_content[0..allowed_start_offset+4].include?('Fra')
        from_index = trimmed_content.index('Fra')
        english = false
    elsif
        return false
    end

    return english and trimmed_content.include?('To') and trimmed_content.include?('Subject') or
        not english and trimmed_content.include?('Til') and trimmed_content.include?('Emne')
end

gui_title = 'Find Unidentified Emails'

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab('main_tab', 'Main')


main_tab.append_text_field('allowed_start_offset', 'Allowed start offset', '10')
main_tab.get_control('allowed_start_offset').set_tool_tip_text('Number of non-whitespace characters allowed before "from".')


# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    
    # Make sure primary address is not empty.
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

    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end

        progress_dialog.set_main_status_and_log_it('Making preliminary search...')
        timer.start('preliminary_search')
        # Finds all items that have text containing 'From:' or 'Fra:' and aren't Outlook files.
        items = current_case.search("NOT mime-type:application/vnd.ms-outlook-* AND content:/from:|fra:/")
        timer.stop('preliminary_search')

        progress_dialog.set_main_status_and_log_it('Identifying emails...')
        timer.start('identify_emails')
        # Identify emails.
        emails = items.filter(:is_email?)
        timer.stop('identify_emails')

        bulk_annotater = utilities.get_bulk_annotater

        progress_dialog.set_main_status_and_log_it('Tagging found emails...')
        timer.start('tag_emails')
        # Tag found emails.
        bulk_annotater.add_tag('Avian|' + values['email_tag'])
        timer.stop('tag_emails')

        timer.stop('total')
        
        timer.print_timings
        
        progress_dialog.set_main_status_and_log_it('Script finished. Found ' + emails.length + ' emails.')

        CommonDialogs.show_information('Script finished.', gui_title)
    end

    puts('Script finished.')
else
    puts('Script cancelled.')
end
