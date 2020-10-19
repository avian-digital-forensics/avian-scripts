require 'set'

# Standard code for finding main directory.
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled.")
    return
end

# For GUI.
require File.join(main_directory,"utils","nx_utils")
# Timings.
require File.join(main_directory,"utils","timer")
# Progress messages.
require File.join(main_directory,"utils","utils")



        
# Returns the ID of the specified email.
def find_email_id(email)
	if email.properties.key?('Mapi-Smtp-Message-Id')
		return email.properties["Mapi-Smtp-Message-Id"]
	else
		return nil
	end
end


## Setup GUI.
gui_title = "Tag Exchange Emails with Duplicates"

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab("main_tab", "Main")

# Add text field for store A prefix.
main_tab.append_text_field("store_a_prefix", "Exchange server email prefix", "This message has been archived.")
main_tab.get_control("store_a_prefix").set_tool_tip_text("All emails containing this text will be treated as exchange server emails.")

# Add text field for store A tag.
main_tab.append_text_field("store_a_tag", "Exchange server email tag", "ExchangeServerEmail")
main_tab.get_control("store_a_tag").set_tool_tip_text("All emails containing the above prefix will receive this tag.")

# Add text field for tag for exchange server emails with an archived duplicate.
main_tab.append_text_field("has_archived_duplicate_metadata_name", "Has archived duplicate", "HasArchivedDuplicate")
main_tab.get_control("has_archived_duplicate_metadata_name").set_tool_tip_text("All exchange server emails will receive a custom metadata field with this name saying whether they have an archived duplicate.")

# Add text field for tag for exchange server emails with missing attachments.
main_tab.append_text_field("has_missing_attachments_metadata_name", "Has missing attachments", "HasMissingAttachmentsMetadataName")
main_tab.get_control("has_missing_attachments_metadata_name").set_tool_tip_text("All exchange server emails that do not have a archived duplicate will receive a custom metadata field with this name saying whether they have attachments.")

main_tab.append_check_box("exclude_items_with_archived_duplicates", "Exclude items with archived duplicates", TRUE)
main_tab.get_control('exclude_items_with_archived_duplicates').set_tool_tip_text('Whether to exclude items with archived duplicates.')

# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    # Make sure required fields are not empty.
    unless NXUtils.assert_non_empty_field(values, "store_a_prefix", "exchange server email prefix") and 
            NXUtils.assert_non_empty_field(values, "store_a_tag", "exchange server email tag") and 
            NXUtils.assert_non_empty_field(values, "has_archived_duplicate_metadata_name", "has archived duplicate") and
            NXUtils.assert_non_empty_field(values, "has_missing_attachments_metadata_name", "has missing attachments metadata name")
        next false
    end
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

# If dialog result is false, the user has cancelled.
if dialog.dialog_result == true
    Utils.print_progress("Running script...")
        
    # values contains the information the user inputted.
    values = dialog.to_map
    
    timer = Timing::Timer.new
    
    timer.start("total")
    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
        progress_dialog.set_sub_progress_visible(false)
        
        # If item text starts with this, the item is from store A.
        store_a_prefix = values["store_a_prefix"]
        
        # All exchange server emails will receive this tag.
        store_a_tag = "Avian|" + values["store_a_tag"]
        
        # All exchange server emails with an archived duplicate will receive this tag.
        has_archived_duplicate_metadata_name = values["has_archived_duplicate_metadata_name"]
        has_archived_duplicate_tag = 'Avian|' + values['has_archived_duplicate_metadata_name']
        
        # Whether the exchange server email has missing attachments.
        has_missing_attachments_metadata_name = values["has_missing_attachments_metadata_name"]

        # Whether to exclude items with archived duplicates.
        exclude_items_with_archived_duplicates = values['exclude_items_with_archived_duplicates']
        
        bulk_annotater = utilities.get_bulk_annotater
        
        progress_dialog.set_main_status_and_log_it("Finding exchange server emails...")
        timer.start("find_store_a")
        # Tag all exchange server emails.
        store_a_items = current_case.search('kind:email AND content:"' + store_a_prefix + '"')
        bulk_annotater.add_tag(store_a_tag, store_a_items)
        timer.stop("find_store_a")
        
        progress_dialog.set_main_status_and_log_it("Searching for archived emails...")
        timer.start("non_store_a_search")
        non_store_a_search = current_case.search('kind:email AND NOT tag:' + store_a_prefix)
        timer.stop("non_store_a_search")

        # Find ID's of archived emails.
        timer.start("non_store_a_find_ids")
        progress_dialog.set_main_status_and_log_it("Finding ID's of archived emails...")
        progress_dialog.set_main_progress(0,non_store_a_search.size)
        archived_emails_processed = 0
        progress_dialog.set_sub_status("Archived emails processed: " + archived_emails_processed.to_s + '/' + non_store_a_search.size.to_s)
        archive_id_set = Set.new(non_store_a_search) do |archived_email| 
            progress_dialog.increment_main_progress
            archived_emails_processed += 1
            progress_dialog.set_sub_status("Archived emails processed: " + archived_emails_processed.to_s)
            if progress_dialog.abort_was_requested
                progress_dialog.log_message('Aborting script...')
                return
            end
            find_email_id(archived_email)
        end
		archive_id_set.delete?(nil)
        timer.stop("non_store_a_find_ids")
        
        num_without_duplicate = 0
        num_missing_attachments = 0
        
        # Give all exchange server emails custom metadata for whether there is an archived duplicate.
        progress_dialog.set_main_status_and_log_it("Checking for exchange server emails without an archived duplicate...")
        progress_dialog.set_main_progress(0,store_a_items.size)
        store_a_items_processed = 0
        timer.start("has_duplicate")
        progress_dialog.set_sub_status('Exchange server emails processed: ' + store_a_items_processed.to_s)
        items_with_duplicate = []
        items_without_duplicate = []
        store_a_items.each_with_index do |email, index|
            if archive_id_set.include?(find_email_id(email))
                items_with_duplicate << email
            else
                items_without_duplicate << email
            end
			store_a_items_processed += 1
            progress_dialog.increment_main_progress
            progress_dialog.set_sub_status('Exchange server emails processed: ' + store_a_items_processed.to_s + '/' + store_a_items.size.to_s + '  Current item GUID: ' + email.guid.to_s)
            if progress_dialog.abort_was_requested
                progress_dialog.log_message('Aborting script...')
                return
            end
        end
        timer.stop("has_duplicate")

        # For items with archived duplicate:
        progress_dialog.set_main_status_and_log_it('Add metadata to exchange server emails with an archived duplicate...')
		progress_dialog.set_main_progress(0, items_with_duplicate.size)
		items_processed = 0
		bulk_annotater.put_custom_metadata(has_archived_duplicate_metadata_name, TRUE, items_with_duplicate) do | item_event_info |
			items_processed += 1
			progress_dialog.increment_main_progress
			progress_dialog.set_sub_status('Exchange server emails with duplicates given metadata: ' + items_processed.to_s + '/' + items_with_duplicate.size.to_s)
		end
		
        progress_dialog.set_main_status_and_log_it('Add tags to exchange server emails with an archived duplicate...')
		progress_dialog.set_main_progress(0, items_with_duplicate.size)
		items_processed = 0
		bulk_annotater.add_tag(has_archived_duplicate_tag, items_with_duplicate) do | item_event_info |
			items_processed += 1
			progress_dialog.increment_main_progress
			progress_dialog.set_sub_status('Exchange server emails with duplicates given metadata: ' + items_processed.to_s + '/' + items_with_duplicate.size.to_s)
		end
        if exclude_items_with_archived_duplicates
            progress_dialog.set_main_status_and_log_it('Excluding exchange server emails with duplicates...')
            timer.start('exclude_items_with_duplicates')
			progress_dialog.set_main_progress(0, items_with_duplicate.size)
			items_processed = 0
            bulk_annotater.exclude('Has an archived duplicate', items_with_duplicate) do | item_event_info |
				items_processed += 1
				progress_dialog.increment_main_progress
				progress_dialog.set_sub_status('Exchange server emails with duplicates excluded: ' + items_processed.to_s + '/' + items_with_duplicate.size.to_s)
			end
            timer.stop('exclude_items_with_duplicates')
        else
            progress_dialog.log_message('Skipping exclusion.')
        end
        # And for those without:
        progress_dialog.set_main_status_and_log_it('Add metadata to exchange server emails without an archived duplicate...')
        bulk_annotater.put_custom_metadata(has_archived_duplicate_metadata_name, FALSE, items_without_duplicate, nil)
        
        progress_dialog.set_main_status_and_log_it('Checking for missing attachments...')
        timer.start("missing_attachments")
        num_without_duplicate = items_without_duplicate.length
            # If the item with missing duplicate has children:
            items_without_duplicate_with_children = items_without_duplicate.select{ |email| email.children.length > 0 }
            num_missing_attachments = items_without_duplicate_with_children.reduce(0) { |sum, email| sum + email.children.length }
            bulk_annotater.put_custom_metadata(has_missing_attachments_metadata_name, TRUE, items_without_duplicate_with_children, nil)
            # If the item with missing duplicate has no children:
            bulk_annotater.put_custom_metadata(has_missing_attachments_metadata_name, TRUE, items_without_duplicate.select{ |email| not email.children.length > 0 }, nil)
        timer.stop("missing_attachments")


        timer.stop("total")

        timer.print_timings()
    
        # Tell the user if emails without archived duplicates were found.
        if num_without_duplicate > 0
            puts("Exchange server emails without an archived duplicate: " + num_without_duplicate.to_s)
            puts("They have been given a custom metadata field '" + has_archived_duplicate_metadata_name + "' with value FALSE.")
            CommonDialogs.show_information("A total of " + num_without_duplicate.to_s + " exchange server emails without an archived duplicate were found.")
        end
        if num_missing_attachments > 0
            puts("Missing attachments: " + num_missing_attachments.to_s)
            puts("The emails they are attached to have been given a custom metadata field '" + has_missing_attachments_metadata_name + "' with value TRUE.")
            CommonDialogs.show_information("A total of " + num_missing_attachments.to_s + " missing attachments were found.")
        end
    end
    
    # Tell the user the script has finished.
    CommonDialogs.show_information("Script finished.", gui_title)
    
    Utils.print_progress("Script finished.")
else
    Utils.print_progress("Script cancelled.")
end
