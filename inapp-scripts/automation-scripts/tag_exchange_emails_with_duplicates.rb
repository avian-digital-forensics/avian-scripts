module TagExchangeEmailsWithDuplicates
    extend self
    
    def run(nuix_case, utilities, settings_hash, progress_handler)
        main_directory = settings_hash[:main_directory]
        require File.join(main_directory, 'inapp-scripts', 'tag-exchange-emails-with-duplicates', 'tag_exchange_emails_with_duplicates')
        require File.join(main_directory,'utils','timer')

        timer = Timing::Timer.new
        timer.start('total')

        archived_prefix = settings_hash['archived_prefix']
        archived_tag = settings_hash['archived_tag']
        archived_has_duplicate_tag = settings_hash['archived_has_duplicate_tag']
        archived_missing_duplicate_tag = settings_hash['archived_missing_duplicate_tag']
        has_missing_attachments_tag = settings_hash['has_missing_attachments_tag']
        exclude_archived_items_with_duplicates = settings_hash['exclude_archived_items_with_duplicates']

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

        # Log if emails without archived duplicates were found.
        if num_without_duplicate > 0
            progress_handler.log_message("Archived emails without a duplicate: " + num_without_duplicate.to_s)
        end
        # Log if missing attachments were detected.
        if num_missing_attachments > 0
            progress_handler.log_message("Missing attachments: " + num_missing_attachments.to_s)
        end

        timer.stop('total')
    end
end
