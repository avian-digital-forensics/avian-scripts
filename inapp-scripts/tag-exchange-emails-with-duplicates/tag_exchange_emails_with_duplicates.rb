require 'set'

module TagExchangeEmailsWithDuplicates
    extend self

    # Returns the ID of the specified email.
    def find_email_id(email)
        if email.properties.key?('Mapi-Smtp-Message-Id')
            return email.properties["Mapi-Smtp-Message-Id"]
        else
            return nil
        end
    end

    def tag_exchange_emails_with_duplicates(nuix_case, progress_handler, timer, utilities, archived_prefix, archived_tag, archived_has_duplicate_tag, archived_missing_duplicate_tag, has_missing_attachments_tag, exclude_archived_items_with_duplicates)
        bulk_annotater = utilities.get_bulk_annotater
        
        progress_handler.set_main_status_and_log_it("Finding emails that have been archived...")
        timer.start("find_archived")
        # Tag all exchange server emails.
        archived_items = nuix_case.search('kind:email AND content:"' + archived_prefix + '"')
        bulk_annotater.add_tag(archived_tag, archived_items)
        timer.stop("find_archived")
        
        progress_handler.set_main_status_and_log_it("Searching for emails in archive...")
        timer.start("archive_search")
        non_archived_search = nuix_case.search('kind:email AND NOT tag:' + archived_prefix)
        timer.stop("archive_search")

        # Find ID's of emails that have not been archived.
        # This includes all emails in the archive.
        timer.start("find_non_archived_ids")
        progress_handler.set_main_status_and_log_it("Finding ID's of emails that have not been archived...")
        progress_handler.set_main_progress(0,non_archived_search.size)
        non_archived_emails_processed = 0
        progress_handler.set_sub_status("Non archived emails processed: " + non_archived_emails_processed.to_s + '/' + non_archived_search.size.to_s)
        non_archived_id_set = Set.new(non_archived_search) do |non_archived_email| 
            progress_handler.increment_main_progress
            non_archived_emails_processed += 1
            progress_handler.set_sub_status("Non archived emails processed: " + non_archived_emails_processed.to_s)
            if progress_handler.abort_was_requested
                progress_handler.log_message('Aborting script...')
                return
            end
            find_email_id(non_archived_email)
        end
		non_archived_id_set.delete?(nil)
        timer.stop("find_non_archived_ids")
        
        num_without_duplicate = 0
        num_missing_attachments = 0
        
        # Give all archived emails custom metadata for whether there is an archived duplicate.
        progress_handler.set_main_status_and_log_it("Checking for archived emails without a duplicate...")
        progress_handler.set_main_progress(0,archived_items.size)
        archived_items_processed = 0
        timer.start("has_duplicate")
        progress_handler.set_sub_status('Archived emails processed: ' + archived_items_processed.to_s)
        items_with_duplicate = []
        items_without_duplicate = []
        archived_items.each_with_index do |email, index|
            if non_archived_id_set.include?(find_email_id(email))
                items_with_duplicate << email
            else
                items_without_duplicate << email
            end
			archived_items_processed += 1
            progress_handler.increment_main_progress
            progress_handler.set_sub_status('Archived emails processed: ' + archived_items_processed.to_s + '/' + archived_items.size.to_s + '  Current item GUID: ' + email.guid.to_s)
            if progress_handler.abort_was_requested
                progress_handler.log_message('Aborting script...')
                return
            end
        end
        timer.stop("has_duplicate")

        # For items with archived duplicate:
        progress_handler.set_main_status_and_log_it('Add tag to emails that have been archived and have a duplicate...')
		progress_handler.set_main_progress(0, items_with_duplicate.size)
		items_processed = 0
		bulk_annotater.add_tag(archived_has_duplicate_tag, items_with_duplicate) do | item_event_info |
			items_processed += 1
			progress_handler.increment_main_progress
			progress_handler.set_sub_status('Archived emails with duplicates given tag: ' + items_processed.to_s + '/' + items_with_duplicate.size.to_s)
        end
        
        # Exclude items.
        if exclude_archived_items_with_duplicates
            progress_handler.set_main_status_and_log_it('Excluding archived emails with duplicates...')
            timer.start('exclude_items_with_duplicates')
			progress_handler.set_main_progress(0, items_with_duplicate.size)
			items_processed = 0
            bulk_annotater.exclude('Has an archived duplicate', items_with_duplicate) do | item_event_info |
				items_processed += 1
				progress_handler.increment_main_progress
				progress_handler.set_sub_status('Archived emails with duplicates excluded: ' + items_processed.to_s + '/' + items_with_duplicate.size.to_s)
			end
            timer.stop('exclude_items_with_duplicates')
        else
            progress_handler.log_message('Skipping exclusion.')
        end
        # And for those without:
        progress_handler.set_main_status_and_log_it('Add metadata to archived emails without an archived duplicate...')
        bulk_annotater.add_tag(archived_missing_duplicate_tag, items_without_duplicate)
        
        progress_handler.set_main_status_and_log_it('Checking for missing attachments...')
        timer.start("missing_attachments")
        num_without_duplicate = items_without_duplicate.length
        # If the item with missing duplicate has children:
        items_without_duplicate_with_children = items_without_duplicate.select{ |email| email.children.length > 0 }
        num_missing_attachments = items_without_duplicate_with_children.reduce(0) { |sum, email| sum + email.children.length }
        bulk_annotater.add_tag(has_missing_attachments_tag, items_without_duplicate_with_children)
        timer.stop("missing_attachments")

        return num_without_duplicate, num_missing_attachments
    end
end
