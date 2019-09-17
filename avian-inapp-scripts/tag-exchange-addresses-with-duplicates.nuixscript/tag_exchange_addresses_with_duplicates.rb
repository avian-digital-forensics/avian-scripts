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


## Setup GUI.
gui_title = "Tag Exchange Addresses with Duplicates"

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.addTab("main_tab", "Main")

# Add text field for store A prefix.
main_tab.appendTextField("store_a_prefix", "Exchange server email prefix", "This message has been archived.")
main_tab.getControl("store_a_prefix").setToolTipText("All emails containing this text will be treated as exchange server emails.")

# Add text field for store A tag.
main_tab.appendTextField("store_a_tag", "Exchange server email tag", "ExchangeServerEmail")
main_tab.getControl("store_a_tag").setToolTipText("All emails containing the above prefix will receive this tag.")

# Add text field for tag for exchange server emails with an archived duplicate.
main_tab.appendTextField("has_archived_duplicate_metadata_name", "Has archived duplicate", "HasArchivedDuplicate")
main_tab.getControl("has_archived_duplicate_metadata_name").setToolTipText("All exchange server emails will receive a custom metadata field with this name saying whether they have an archived duplicate.")

# Checks the input before closing the dialog.
dialog.validateBeforeClosing do |values|
    # Make sure primary address is not empty.
    unless NXUtils.assert_non_empty_field(values, "store_a_prefix", "exchange server email prefix") and 
            NXUtils.assert_non_empty_field(values, "store_a_tag", "exchange server email tag") and 
            NXUtils.assert_non_empty_field(values, "has_archived_duplicate_metadata_name", "has archived duplicate")
        next false
    end
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

# If dialog result is false, the user has cancelled.
if dialog.getDialogResult == true
    puts("Running script...")
    
    timer = Timer::Timer.new
    
    timer.start("total")
    runs = 0
    while timer.total_time("total") < 60
        runs += 1
        # values contains the information the user inputted.
        values = dialog.toMap
        
        # If item text starts with this, the item is from store A.
        store_a_prefix = values["store_a_prefix"]
        
        # All exchange server emails will receive this tag.
        store_a_tag = values["store_a_tag"]
        
        # All exchange server emails with an archived duplicate will receive this tag.
        has_archived_duplicate_metadata_name = values["has_archived_duplicate_metadata_name"]
        
        # Returns the ID of the specified email.
        def find_email_id(email)
            raise ArgumentError, "Email doesn't have a Mapi-Smtp-Message-Id property. GUID: " + email.guid unless email.properties.key?("Mapi-Smtp-Message-Id")
            return email.properties["Mapi-Smtp-Message-Id"]
        end
        
        puts("Finding exchange server emails...")
        timer.start("find_store_a")
        # Tag all exchange server emails.
        store_a_items = current_case.search('kind:email AND content:"' + store_a_prefix + '"')
        store_a_size = store_a_items.length
        one_percent = (store_a_size/100).floor
        puts(one_percent.to_s)
        cur_count = 0
        for email in store_a_items
            email.add_tag(store_a_tag)
            cur_count += 1
            if cur_count % one_percent == 0
                percent = cur_count / one_percent
                if percent % 5 == 0
                    puts(percent.to_s + "%")
                end
            end
        end
        timer.stop("find_store_a")
        
        timer.start("non_store_a_search")
        # All ID's used by archived emails.
        archive_id_set = Set.new(current_case.search('kind:email AND NOT tag:' + store_a_prefix)){ |archived_email| find_email_id(archived_email) }
        timer.stop("non_store_a_search")
        
        num_without_duplicate = 0
        
        timer.start("has_duplicate")
        # Give all exchange server emails custom metadata for whether there is an archived duplicate.
        for email in current_case.search('tag:' + store_a_prefix)
            if archive_id_set.include?(find_email_id(email))
                email.custom_metadata[has_archived_duplicate_metadata_name] = TRUE
            else
                email.custom_metadata[has_archived_duplicate_metadata_name] = FALSE
                num_without_duplicate += 1
            end
        end
        timer.stop("has_duplicate")
    end
    puts("Timings:")
    puts("    total: " + Timer::seconds_to_string(timer.total_time("total")/runs))
    puts("    find_store_a: " + Timer::seconds_to_string(timer.total_time("find_store_a")/runs))
    puts("    non_store_a_search: " + Timer::seconds_to_string(timer.total_time("non_store_a_search")/runs))
    puts("    has_duplicate: " + Timer::seconds_to_string(timer.total_time("has_duplicate")/runs))
    
    # Tell the user if emails without archived duplicates were found.
    if num_without_duplicate > 0
        puts("Exchange server emails without an archived duplicate: " + num_without_duplicate.to_s)
        puts("They have been a custom metadata field '" + has_archived_duplicate_metadata_name + "' with value FALSE.")
        CommonDialogs.show_information("A total of " + num_without_duplicate.to_s + " exchange server emails without an archived duplicate were found.")
    end
    
    timer.stop("total")
    
    # Tell the user the script has finished.
    CommonDialogs.show_information("Script finished.", gui_title)
    
    puts("Script finished.")
else
    puts("Script cancelled.")
end
