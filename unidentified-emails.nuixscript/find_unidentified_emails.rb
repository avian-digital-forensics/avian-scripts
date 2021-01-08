module FindUnidentifiedEmails
    extend self

    # Returns the part of the item's text to be scanned for communication fields.
    # +item+:: the item to check for emailness.
    # +start_area_line_num+:: the number of lines that will be searched for communication fields.
    # +timer+:: a Timer object used to measure running time of parts of the method.
    def metadata_text(item, start_area_line_num, timer)
        raise ArgumentError, 'Item must contain text' unless item.text_object

        lines = item.text_object.to_string.lines
        lines[0..[start_area_line_num, lines.size].min].join
    end

    # Returns true if the item's text indicates that it is in fact an email.
    # Params:
    # +item+:: the item to check for emailness.
    # +allowed_start_offset+:: characters from the start of the text before "From" or "Fra" must appear.
    # +start_area_line_num+:: the number of lines that will be searched for communication fields.
    # +timer+:: a Timer object used to measure running time of parts of the method.
    def is_email?(item, allowed_start_offset, start_area_line_num, timer)

        trimmed_content = metadata_text(item, start_area_line_num, timer)

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

    # Performs a search for all items in the case that might be relevant.
    # Params:
    # +current_case+:: the current_case.
    # +progress_dialog+:: the dialog on which progress will be shown.
    # +timer+:: a Timer object used to measure running time of parts of the method.
    # +scoping_query+:: Only run on items matching this query.
    def preliminary_search(current_case, progress_dialog, timer, scoping_query)
        progress_dialog.log_message('No selection. Performing preliminary search...')
        timer.start('preliminary_search')
        # Finds all items that have text containing 'From:' or 'Fra:' and aren't Outlook files.
        non_mail_mime_types = ['application/vnd.ms-outlook-*', 'application/pdf-mail', 'application/x-mime-html', 'image/vnd.ms-emf']
        # non_mail_mime_types.push('image/png')
        non_mail_mime_types_search = '(' + non_mail_mime_types.map{ |s| '(NOT mime-type:' + s + ')'}.join(' AND ') + ' AND (NOT kind:calendar))'
        search_term = non_mail_mime_types_search + ' AND content:((from AND \to AND subject) OR (fra AND til AND emne))'
        items = current_case.search(search_term)
        timer.stop('preliminary_search')
        progress_dialog.log_message('Preliminary search found ' + items.length.to_s + ' possible emails.')
        return items
    end

    # Finds all items that seem to be emails that Nuix hasn't recognized as such and gives them a specified tag.
    # Params:
    # +current_case+:: the current_case.
    # +items+:: the items to process.
    # +progress_dialog+:: the dialog on which progress will be shown.
    # +timer+:: a Timer object used to measure running time of parts of the method.
    # +allowed_start_offset+:: characters from the start of the text of an item before "From" or "Fra" must appear for the item to be an email.
    # +start_area_line_num+:: the number of lines that will be searched for communication fields.
    # +email_tag+:: the tag given to all found unidentified emails.
    # +bulk_annotater+:: the bulk annotater used to give tags.
    def find_unidentified_emails(current_case, items, progress_dialog, timer, allowed_start_offset, start_area_line_num, email_tag, bulk_annotater)

        progress_dialog.set_main_status_and_log_it('Identifying emails...')
        progress_dialog.set_main_progress(0,items.size)
        emails_found = 0
        progress_dialog.set_sub_status("Emails found: " + emails_found.to_s)
        timer.start('identify_emails')
        # Identify emails.
        emails = items.select do |item|
            progress_dialog.increment_main_progress
            result = FindUnidentifiedEmails::is_email?(item, allowed_start_offset, start_area_line_num, timer)
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

        progress_dialog.set_main_status_and_log_it('Tagging found emails...')
        timer.start('tag_emails')
        # Tag found emails.
        bulk_annotater.add_tag('Avian|' + email_tag, emails)
        timer.stop('tag_emails')
		
		return emails.size
    end
end
