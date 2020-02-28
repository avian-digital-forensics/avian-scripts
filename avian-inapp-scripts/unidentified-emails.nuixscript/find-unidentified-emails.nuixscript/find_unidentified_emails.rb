module FindUnidentifiedEmails

    def metadata_text(item, start_area_size, timer)
        raise ArgumentError, 'Item must contain text' unless item.text_object
        item.text_object.sub_sequence(0, [start_area_size, item.text_object.length].min).to_s.strip
    end

    def is_email?(item, allowed_start_offset, start_area_size, timer)

        trimmed_content = metadata_text(item, start_area_size, timer)

        # Find email start.
        if trimmed_content[0..[allowed_start_offset+5, trimmed_content.length].min].include?('From')
            from_index = trimmed_content.index('From')
            english = true
        elsif trimmed_content[0..[allowed_start_offset+4, trimmed_content.length].min].include?('Fra')
            from_index = trimmed_content.index('Fra')
            english = false
        else
            return false
        end

        result = (english && trimmed_content.include?('To') && trimmed_content.include?('Subject')) || (!english && trimmed_content.include?('Til') && trimmed_content.include?('Emne'))
        return result
    end

    def find_unidentified_emails(current_case, current_selected_items, progress_dialog, timer, allowed_start_offset, start_area_size, email_tag)
        progress_dialog.set_main_status_and_log_it('Making preliminary search...')
        if current_selected_items.size > 0
            progress_dialog.log_message('Using selection. Skipping preliminary search.')
            items = current_selected_items
        else
            progress_dialog.log_message('No selection. Doing preliminary search.')
            timer.start('preliminary_search')
            # Finds all items that have text containing 'From:' or 'Fra:' and aren't Outlook files.
            non_mail_mime_types = ['application/vnd.ms-outlook-*', 'application/pdf-mail', 'application/x-mime-html', 'image/vnd.ms-emf']
            #non_mail_mime_types.push('image/png')
            non_mail_mime_types_search = '(' + non_mail_mime_types.map{ |s| '(NOT mime-type:' + s + ')'}.join(' AND ') + ')'
            search_term = non_mail_mime_types_search + ' AND content:((from AND \to AND subject) OR (fra AND til AND emne))'
            items = current_case.search(search_term)
            timer.stop('preliminary_search')
            progress_dialog.log_message('Preliminary search found ' + items.length.to_s + ' possible emails.')
        end

        progress_dialog.set_main_status_and_log_it('Identifying emails...')
        progress_dialog.set_main_progress(0,items.size)
        emails_found = 0
        progress_dialog.set_sub_status("Emails found: " + emails_found.to_s)
        timer.start('identify_emails')
        # Identify emails.
        emails = items.select do |item|
            progress_dialog.increment_main_progress
            result = FindUnidentifiedEmails::is_email?(item, allowed_start_offset, start_area_size, timer)
            if result
                emails_found += 1
                progress_dialog.set_sub_status("Emails found: " + emails_found.to_s)
            end
            if progress_dialog.abort_was_requested
                progress_dialog.log_message('Aborting script...')
                return
            end
            result
        end
        timer.stop('identify_emails')

        bulk_annotater = utilities.get_bulk_annotater

        progress_dialog.set_main_status_and_log_it('Tagging found emails...')
        timer.start('tag_emails')
        # Tag found emails.
        bulk_annotater.add_tag('Avian|' + email_tag, emails)
        timer.stop('tag_emails')
    end
end