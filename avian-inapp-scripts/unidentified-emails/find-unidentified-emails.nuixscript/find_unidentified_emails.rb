module FindUnidentifiedEmails
    extend self

    # Returns the part of the item's text to be scanned for communication fields.
    # +item+:: the item to check for emailness.
    # +start_area_size+:: the size in characters of the area that will be searched for communication fields.
    # +timer+:: a Timer object used to measure running time of parts of the method.
    def metadata_text(item, start_area_size, timer)
        raise ArgumentError, 'Item must contain text' unless item.text_object
        item.text_object.sub_sequence(0, [start_area_size, item.text_object.length].min).to_s.strip
    end

    # Returns true if the item's text indicates that it is in fact an email.
    # Params:
    # +item+:: the item to check for emailness.
    # +allowed_start_offset+:: characters from the start of the text before "From" or "Fra" must appear.
    # +start_area_size+:: the size in characters of the area that will be searched for communication fields.
    # +timer+:: a Timer object used to measure running time of parts of the method.
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

    # Finds all items that seem to be emails that Nuix hasn't recognized as such.
    # Params:
    # +current_case+:: the current_case.
    # +items+:: the items to process.
    # +progress_dialog+:: the dialog on which progress will be shown.
    # +timer+:: a Timer object used to measure running time of parts of the method.
    # +allowed_start_offset+:: characters from the start of the text of an item before "From" or "Fra" must appear for the item to be an email.
    # +start_area_size+:: the size in characters of the area that will be searched for communication fields in any item's text.
    # +email_tag+:: the tag given to all found unidentified emails.
    # +bulk_annotater+:: the bulk annotater used to give tags.
    def find_unidentified_emails(current_case, items, progress_dialog, timer, allowed_start_offset, start_area_size, email_tag, bulk_annotater)

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

        progress_dialog.set_main_status_and_log_it('Tagging found emails...')
        timer.start('tag_emails')
        # Tag found emails.
        bulk_annotater.add_tag('Avian|' + email_tag, emails)
        timer.stop('tag_emails')
		
		return emails.size
    end
end