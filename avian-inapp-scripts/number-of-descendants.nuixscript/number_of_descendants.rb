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

gui_title = "Number of Descendants"

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.addTab("main_tab", "Main")

# Add a text field for the custom metadata name.
main_tab.appendTextField("metadata_key", "Custom metadata name", "NumberOfDescendants")
main_tab.getControl("metadata_key").setToolTipText("The metadata field items receive will have this name.")


# Checks the input before closing the dialog.
dialog.validateBeforeClosing do |values|
    
    unless NXUtils.assert_non_empty_field(values, "metadata_key", "custom metadata name")
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
    
    metadata_key = values["metadata_key"]
    
    # Returns the number of descendants of the item.
    def num_descendants(item)
        return item.descendants.length
    end
    
    items = current_selected_items
    puts("Processing " + current_selected_items.length.to_s + " items...")
    
    # Add a custom metadata field to each item with the number of descendants.
    for item in items
        item.custom_metadata[metadata_key] = num_descendants(item)
    end
    
    # Tell the user the script has finished.
    CommonDialogs.show_information("Script finished." , gui_title)
    
    puts("Script finished.")
else
    puts("Script cancelled.")
end
