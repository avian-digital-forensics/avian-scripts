script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

# GUI_TITLE is the name given to all GUI elements created by the InAppScript.
# SCRIPT_NAME should be of the form inapp_gui_template2.
unless script = Script::create_inapp_script(setup_directory, 'QC and Culling', 'qc_cull')
    STDERR.puts('Could not find main directory.')
    return
end

# For GUI.
require File.join(main_directory,'utils','nx_utils')
# Timings.
require File.join(main_directory,'utils','timer')
# Progress messages.
require File.join(main_directory,'utils','utils')
# Save and load script settings.
require File.join(main_directory,'utils','settings_utils')
# Number of descendants.
require File.join(main_directory,'avian-inapp-scripts','number-of-descendants.nuixscript','number_of_descendants')
# Search and tag.
require File.join(main_directory,'avian-inapp-scripts','qc-cull.nuixscript','search_and_tag')
# Report.
require File.join(main_directory,'avian-inapp-scripts','qc-cull.nuixscript','report')


dialog = NXUtils.create_dialog(gui_title)

# Load saved settings.
script_settings = SettingsUtils::load_script_settings(main_directory,'qc_cull')

# Add main tab.
script.dialog_add_tab('main_tab', 'Main')

# Add a text field for the custom metadata name for number of descendants.
script.dialog_append_text_field('main_tab', 'num_descendants_metadata_key', 'Number of descendants custom metadata name', 
        'All items will receive a custom metadata field with this key.')

# Add file chooser for search and tag.
script.dialog_append_open_file_chooser('main_tab', 'search_and_tag_file', 'Search and Tag File', 'JSON', 'json', 'This file will be loaded into the search and tag.')

# Add exclusion tab.
exclusion_tab = dialog.add_tab('exclusion', 'Culling')
# Add text fields for exclusion prefixes.
# Any items with tags with a prefix, will be excluded with the specified reason.
exclusion_prefix_num = 0
while script_settings[:exclusion].key?("exclusion_prefix_#{exclusion_prefix_num + 1}".to_sym)
    exclusion_prefix_num += 1
    script.dialog.append_text_field('exclusion', "exclusion_prefix_#{exclusion_prefix_num}", "Exclusion prefix #{exclusion_prefix_num}",
            'Any items with a tag with this prefix will be excluded with the associated reason.')
    script.dialog.append_text_field('exclusion', "exclusion_reason_#{exclusion_prefix_num}", "Exclusion reason #{exclusion_prefix_num}",
            'Any items with a tag with the associated prefix will be excluded with this reason.')
end



# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
    
    unless NXUtils.assert_non_empty_field(values, 'num_descendants_metadata_key', 'number of descendants custom metadata name')
        next false
    end

    for k in 1..exclusion_prefix_num
        if values["exclusion_prefix_#{k}"].strip.empty? != values["exclusion_reason_#{k}"].strip.empty?
            CommonDialogs.show_warning('If an exclusion prefix or reason is given, the other must be non-empty.')
            next false
        end
    end
    
    # Everything is fine; close the dialog.
    next true
end

script.run do |progress_dialog|
    # This next part takes the information the user inputted and updates the stored settings so the input will be remembered.
    num_descendants_metadata_key = values['num_descendants_metadata_key']

    exclude_tag_prefixes = {}
    for k in 1..exclusion_prefix_num
        prefix = values["exclusion_prefix_#{k}"]
        reason = values["exclusion_reason_#{k}"]
        unless prefix.empty?
            if reason.empty?
                STDERR.puts('Sum ting wong! sdfgonvr')
            end
            exclude_tag_prefixes[prefix] = reason
        end
    end

    search_and_tag_file = values["search_and_tag_file"]

    selected_item_tag = 'Avian|SELECTEDITEMS_INTERNAL'

    bulk_annotater = utilities.get_bulk_annotater
    
    

    items = current_selected_items

    # The actual QC process starts here.

    # Number of Descendants.
    NumberOfDescendants::number_of_descendants(current_case, progress_dialog, timer, items, num_descendants_metadata_key, bulk_annotater)
    
    # Give all selected items a unique tag.
    progress_dialog.set_main_status_and_log_it('Adding selected item tag...')
    timer.start('add_selected_items_tag')
    Utils::bulk_add_tag(utilities, progress_dialog, selected_item_tag, items)
    timer.stop('add_selected_items_tag')

    # Search and Tag.
    # Skipped if no .json files are specified.
    if search_and_tag_files.empty?
        progress_dialog.log_message('Skipping search and tag since no files are selected.')
    else
        QCCull::search_and_tag(current_case,progress_dialog,timer,search_and_tag_files,'tag:"' + selected_item_tag + '"')
    end

    # Culling.
    if exclude_tag_prefixes.empty?
        progress_dialog.log_message('Skipping exclude because no exclude tag prefixes were specified.')
    else
        timer.start('exclude_items')
        
        progress_dialog.set_main_status_and_log_it("Excluding items...")
        exclude_tag_prefixes.each do |prefix, reason|
            # Create a list of which tags in the case are exclusion tags.
            # All items with these tags will be excluded.
            progress_dialog.set_main_status_and_log_it("Finding exclusion tags with prefix '#{prefix}'...")
            timer.start('find_exclude_tags')
            exclude_tags = current_case.all_tags.select { |tag| tag.start_with?(prefix) }
            timer.stop('find_exclude_tags')


            # Finds all selected items with exclusion tags.
            progress_dialog.set_main_status_and_log_it('Finding exclusion items...')
            timer.start('find_exclude_items')
            # Create a search string matching all items with exclusion tags.
            exclude_search = exclude_tags.map { |tag| "tag:\"#{tag}\""}.join(' OR ')
            if exclude_search.empty?
                # If there are no exclusion tags, skip exclusion.
                progress_dialog.log_message("Skipping exclusion for prefix '#{prefix}' since no matching tags were found.")
                timer.stop('find_exclude_items')
            else
                # Add a clause to ensure that only selected items will match the search.
                exclude_search += " AND tag:\"#{selected_item_tag}\""
                # Perform the search.
                exclude_items = current_case.search(exclude_search)
                timer.stop('find_exclude_items')
    
                # Actually exclude the items.
                progress_dialog.set_main_status_and_log_it("Excluding items for prefix '#{prefix}'...")
                Utils::bulk_exclude(utilities, progress_dialog, exclude_items, reason)
            end
        end
        timer.stop('exclude_items')


    # Report.
    result_hash = {}
    # Encrypted files.
    QCCull::report_encrypted_items(current_case, result_hash)
    # Find report file.
    report_file_path = 'C:\Users\aga\Documents\scripts\avian-scripts\report.rtf'
    # Update report with results.
    QCCull::update_report(result_hash, report_file_path)

    # The tag marking that an item is selected was only meant for internal use, so let's remove it.
    # First from each individual item...
    progress_dialog.set_main_status_and_log_it('Removing selected item tag...')
    timer.start('remove_selected_items_tag')
    Utils::bulk_remove_tag(utilities, progress_dialog, selected_item_tag, items)
    timer.stop('remove_selected_items_tag')

    # ...and then from the case.
    if current_case.delete_tag(selected_item_tag)
        progress_dialog.log_message('Selected item tag succesfully removed.')
    else
        progress_dialog.log_message('Selected item tag not successfully removed. This may be because some items already had the tag. Tag: ' + selected_item_tag)
    end
end
