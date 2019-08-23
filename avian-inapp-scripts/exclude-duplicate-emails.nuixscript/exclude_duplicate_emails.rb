script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

if not main_directory
    puts("Script cancelled.")
    return
end

require File.join(main_directory,"utils","nx_utils")


dialog = NXUtils.create_dialog("Tag Exchange Addresses with Duplicates")

# Add main tab.
main_tab = dialog.addTab("main_tab", "Main")

# Add text field for store A prefix.
main_tab.appendTextField("store_a_prefix", "Exchange server email prefix", "This message has been archived.")
main_tab.getControl("store_a_prefix").setToolTipText("All emails containing this text will be treated as exchange server emails.")

# Add text field for store A tag.
main_tab.appendTextField("store_a_tag", "Exchange server email tag", "ExchangeServerEmail")
main_tab.getControl("store_a_tag").setToolTipText("All emails containing the above prefix will receive this tag.")

# Add text field for tag for exchange server emails with an archived duplicate.
main_tab.appendTextField("has_archive_duplicate_tag", "Has archived duplicate", "HasArchivedDuplicate")
main_tab.getControl("has_archive_duplicate_tag").setToolTipText("All exchange server emails that have an archived duplicate will receive this tag.")

# Add text field for tag for exchange server emails without an archived duplicate.
main_tab.appendTextField("has_no_archive_duplicate_tag", "Has no archived duplicate", "HasNoArchivedDuplicate")
main_tab.getControl("has_no_archive_duplicate_tag").setToolTipText("All exchange server emails that do NOT have an archived duplicate will receive this tag.")

# Checks the input before closing the dialog.
dialog.validateBeforeClosing do |values|
    # Make sure primary address is not empty.
    if not (NXUtils.assert_non_empty_field(values, "store_a_prefix", "exchange server email prefix") and 
            NXUtils.assert_non_empty_field(values, "store_a_tag", "exchange server email tag") and 
            NXUtils.assert_non_empty_field(values, "has_archive_duplicate_tag", "has archived duplicate") and 
            NXUtils.assert_non_empty_field(values, "has_no_archive_duplicate_tag", "has no archived duplicate"))
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
    
    # values contains the information the user inputted.
    values = dialog.toMap
    
    # If item text starts with this, the item is from store A.
    store_a_prefix = values["store_a_prefix"]
    
    # All exchange server emails will receive this tag.
    store_a_tag = values["store_a_tag"]
    
    # All exchange server emails with an archived duplicate will receive this tag.
    has_archive_duplicate_tag = values["has_archive_duplicate_tag"]
    
    # All exchange server emails without an archived duplicate will receive this tag.
    has_no_archive_duplicate_tag = values["has_no_archive_duplicate_tag"]
    
    # Returns the ID of the specified email.
    def find_email_id(email)
        raise ArgumentError, "Email doesn't have a Mapi-Smtp-Message-Id property. GUID: " + email.guid unless email.properties.key?("Mapi-Smtp-Message-Id")
        return email.properties["Mapi-Smtp-Message-Id"]
    end
    
    # Tag all exchange server emails.
    for email in current_case.search('kind:email AND content:"' + store_a_prefix + '"')
        email.add_tag(store_a_tag)
    end
    
    # All ID's used by archived emails.
    archive_id_set = Set.new(current_case.search('kind:email AND NOT tag:' + store_a_prefix)){ |archived_email| find_email_id(archived_email) }
    
    num_without_duplicate = 0
    
    # Give all exchange server emails tags for whether there is an archived duplicate.
    for email in current_case.search('tag:' + store_a_prefix)
        if archive_id_set.include?(find_email_id(email))
            email.add_tag(has_archive_duplicate_tag)
        else
            email.add_tag(has_no_archive_duplicate_tag)
            num_without_duplicate += 1
        end
    end
    
    puts("Exchange server emails without an archived duplicate: " + num_without_duplicate)
    puts("They have been tagged with '" + has_no_archive_duplicate_tag + "'")
    
    CommonDialogs.show_information("Script finished. A total of " + num_without_duplicate + " exchange server emails without an archived duplicate were found. They have been tagged with '" + has_no_archive_duplicate_tag + "'", "Tag Exchange Addresses with Duplicates")
    
    puts("Script finished.")
end