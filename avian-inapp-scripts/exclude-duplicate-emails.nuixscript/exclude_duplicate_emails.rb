script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

if not main_directory
    puts("Script cancelled.")
    return
end

require File.join(main_directory,"utils","nx_utils")


dialog = NXUtils.create_dialog("Template")

# Add main tab.
main_tab = dialog.addTab("main_tab", "Main")

# TODO: ADD GUI HERE


# Checks the input before closing the dialog.
dialog.validateBeforeClosing do |values|
    
    # TODO: ADD CHECKS HERE
    
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
    
    # The total number of removed emails.
    num_removed_emails = 0;
    
    # If item text starts with this, the item is from store A.
    store_a_string = "This email has been archived"
    
    # Returns the ID of the specified email.
    def find_email_id(email)
        raise ArgumentError, "Email doesn't have a Mapi-Smtp-Message-Id property." unless email.properties.key?("Mapi-Smtp-Message-Id")
        return email.properties["Mapi-Smtp-Message-Id"]
    end
    
    # Returns whether the specified email is from store A.
    def store_a?(email)
        return email.text_object.to_string.starts_with?(store_a_string)
    end
    
    # A hash with email ID's as keys and emails as values.
    id_hash = {}
    # A hash with email ID's as keys and whether the email is from store A as values.
    id_include = {}
    
    # Walk through each email in the current case and build the hash and exclude items.
    for email in current_case.search("kind:email")
        id = find_email_id(email)
        # If an email with this ID has already been found.
        if id_hash.key?(id)
            # Found out whether the already found email is from store A.
            if not id_include.key?(id)
                id_include[id] = store_a?(id_hash[id])
            end
            
            # If the already found email is from store A.
            if id_include[id]
                # Replace it with the new email.
                id_hash[id] = email
                # Delete the id from id_include.
                # It is no longer known whether the email stored for that ID is from store A.
                id_include.delete(id)
            else
                # If the already found email is NOT from store A, the new email can be excluded.
                email.exclude("Duplicate. Other email has same Mapi-Smtp-Message-Id")
            end
        else
            # No other email with this ID has been seen.
            # Insert it into the hash.
            id_hash[id] = email
        end
    end
    
    puts("Script finished.")
    puts("Emails excluded: " + num_removed_emails)
end