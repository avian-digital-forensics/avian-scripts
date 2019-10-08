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
require File.join(main_directory,"utils","timer")



        
# Returns the ID of the specified email.
def find_email_id(email)
    raise ArgumentError, "Email doesn't have a Mapi-Smtp-Message-Id property. GUID: " + email.guid unless email.properties.key?("Mapi-Smtp-Message-Id")
    return email.properties["Mapi-Smtp-Message-Id"]
end


## Setup GUI.
gui_title = "Tag Exchange Addresses with Duplicates"

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

# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    # Make sure primary address is not empty.
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
    puts("Running script...")
    
    timer = Timer::Timer.new
    
    timer.start("total")
    runs = 0
    while runs == 0
        runs += 1
        # values contains the information the user inputted.
        values = dialog.to_map
        
        # If item text starts with this, the item is from store A.
        store_a_prefix = values["store_a_prefix"]
        
        # All exchange server emails will receive this tag.
        store_a_tag = values["store_a_tag"]
        
        # All exchange server emails with an archived duplicate will receive this tag.
        has_archived_duplicate_metadata_name = values["has_archived_duplicate_metadata_name"]
        
        # Whether the exchange server email has missing attachments.
        has_missing_attachments_metadata_name = values["has_missing_attachments_metadata_name"]
        
        bulk_annotater = utilities.get_bulk_annotater
        
        puts("Finding exchange server emails...")
        timer.start("find_store_a")
        # Tag all exchange server emails.
        store_a_items = current_case.search('kind:email AND content:"' + store_a_prefix + '"')
        bulk_annotater.add_tag(store_a_tag, store_a_items)
        timer.stop("find_store_a")
        
        puts("Searching for archived emails...")
        timer.start("non_store_a_search")
        # All ID's used by archived emails.
        archive_id_set = Set.new(current_case.search('kind:email AND NOT tag:' + store_a_prefix)){ |archived_email| find_email_id(archived_email) }
        timer.stop("non_store_a_search")
        
        num_without_duplicate = 0
        num_missing_attachments = 0
        
        puts("Checking for exchange server emails without an archived duplicate...")
        timer.start("has_duplicate")
        # Give all exchange server emails custom metadata for whether there is an archived duplicate.
        # True if there is an archived duplicate:
        bulk_annotater.put_custom_metadata(has_archived_duplicate_metadata_name, TRUE, store_a_items.select{ |email| archive_id_set.include?(find_email_id(email)) }, nil)
        # And if there isn't:
        items_without_duplicate = store_a_items.select{ |email| not archive_id_set.include?(find_email_id(email)) }
        bulk_annotater.put_custom_metadata(has_archived_duplicate_metadata_name, FALSE, items_without_duplicate, nil)
        
        puts("    Checking for missing attachments...")
        timer.start("missing_attachments")
        num_without_duplicate = items_without_duplicate.length
            # If the item with missing duplicate has children:
            items_without_duplicate_with_children = items_without_duplicate.select{ |email| email.children.length > 0 }
            num_missing_attachments = items_without_duplicate_with_children.reduce(0) { |sum, email| sum + email.children.length }
            bulk_annotater.put_custom_metadata(has_missing_attachments_metadata_name, TRUE, items_without_duplicate_with_children, nil)
            # If the item with missing duplicate has no children:
            bulk_annotater.put_custom_metadata(has_missing_attachments_metadata_name, TRUE, items_without_duplicate.select{ |email| not email.children.length > 0 }, nil)
        timer.stop("missing_attachments")
        timer.stop("has_duplicate")
    end

    puts("Timings:")
    puts("    total: " + Timer.seconds_to_string(timer.total_time("total")/runs))
    puts("    find_store_a: " + Timer.seconds_to_string(timer.total_time("find_store_a")/runs))
    puts("    non_store_a_search: " + Timer.seconds_to_string(timer.total_time("non_store_a_search")/runs))
    puts("    has_duplicate: " + Timer.seconds_to_string(timer.total_time("has_duplicate")/runs))
    puts("    missing_attachments: " + Timer.seconds_to_string(timer.total_time("has_duplicate")/runs))
    
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
    timer.stop("total")
    
    # Tell the user the script has finished.
    CommonDialogs.show_information("Script finished.", gui_title)
    
    puts("Script finished.")
else
    puts("Script cancelled.")
end
