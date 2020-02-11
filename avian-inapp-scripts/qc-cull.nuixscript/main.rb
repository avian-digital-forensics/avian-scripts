script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','setup.nuixscript','get_main_directory')

main_directory = get_main_directory(false)

unless main_directory
    puts('Script cancelled because no main directory could be found.')
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

gui_title = 'QC and Culling'

dialog = NXUtils.create_dialog(gui_title)

# Load saved settings.
script_settings = SettingsUtils::load_script_settings(main_directory,'qc_cull')

# Add main tab.
main_tab = dialog.add_tab('main_tab', 'Main')

# Add a text field for the custom metadata name for number of descendants.
main_tab.append_text_field('num_descendants_metadata_key', 'Number of descendants custom metadata name', script_settings[:main][:num_descendants_metadata_key])
main_tab.get_control('num_descendants_metadata_key').set_tool_tip_text('All items will receive a custom metadata field with this key.')

# Add text field for exclude tag prefix.
main_tab.append_text_field('exclude_tag_prefix', 'Exclusion tag prefix', script_settings[:main][:exclude_tag_prefix])
main_tab.get_control('exclude_tag_prefix').set_tool_tip_text('All items with a tag starting with this will be excluded. If left blank, no items will be excluded.')

# Add text field for exclude reason.
main_tab.append_text_field('exclude_reason', 'Exclusion reason', script_settings[:main][:exclude_reason])
main_tab.get_control('exclude_reason').set_tool_tip_text('All exclusions will be given this reason.')


# Add search and tag file tab.
search_and_tag_tab = dialog.add_tab('search_and_tag', 'Search and Tag')
# Add file choosers for search and tag.
search_and_tag_file_num = 0
while script_settings[:search_and_tag].key?("search_and_tag_file_#{search_and_tag_file_num + 1}".to_sym)
    search_and_tag_file_num += 1
    search_and_tag_tab.append_open_file_chooser("search_and_tag_file_#{search_and_tag_file_num}", "Search and Tag File #{search_and_tag_file_num}", 'JSON', 'json')
    search_and_tag_tab.get_control("search_and_tag_file_#{search_and_tag_file_num}").set_tool_tip_text('This file will be loaded into the search and tag.')
    search_and_tag_tab.set_text("search_and_tag_file_#{search_and_tag_file_num}", script_settings[:search_and_tag]["search_and_tag_file_#{search_and_tag_file_num}".to_sym])
end


exclusion_tab = dialog.add_tab('exclusion', 'Culling')
exclusion_prefix_num = 0
while script_settings[:exclusion].key?("exclusion_prefix_#{exclusion_prefix_num + 1}".to_sym)
    exclusion_prefix_num += 1
    exclusion_prefix = script_settings[:exclusion]["exclusion_prefix_#{search_and_tag_file_num}".to_sym]
    exclusion_reason = script_settings[:exclusion]["exclusion_reason_#{search_and_tag_file_num}".to_sym]
    exclusion_tab.append_text_field("exclusion_prefix_#{exclusion_prefix_num}", "Exclusion prefix #{exclusion_prefix_num}", )
    exclusion_tab.append_text_field("exclusion_reason_#{exclusion_prefix_num}", "Exclusion reason #{exclusion_prefix_num}", )
end



# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    
    unless NXUtils.assert_non_empty_field(values, 'num_descendants_metadata_key', 'number of descendants custom metadata name')
        next false
    end

    for k in 0..exclusion_prefix_num
        
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

# If dialog result is false, the user has cancelled.
if dialog.dialog_result
    Utils.print_progress('Running script...')
    
    # values contains the information the user inputted.
    values = dialog.to_map

    # This next part takes the information the user inputted and updates the stored settings so the input will be remembered.

    num_descendants_metadata_key = values['num_descendants_metadata_key']
    script_settings[:main][:num_descendants_metadata_key] = num_descendants_metadata_key

    exclude_tag_prefix = values['exclude_tag_prefix']
    script_settings[:main][:exclude_tag_prefix] = exclude_tag_prefix

    exclude_reason= values['exclude_reason']
    script_settings[:main][:exclude_reason] = exclude_reason

    search_and_tag_files = []
    for k in 1..search_and_tag_file_num
        path = values["search_and_tag_file_#{k}"]
        script_settings[:search_and_tag]["search_and_tag_file_#{k}".to_sym] = path
        unless path.empty?
            search_and_tag_files << path
        end
    end

    SettingsUtils::save_script_settings(main_directory, 'qc_cull', script_settings)

    timer = Timing::Timer.new

    timer.start('total')

    selected_item_tag = 'Avian|SELECTEDITEMS_INTERNAL'
    
    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end

        items = current_selected_items

        # The actual QC process starts here.

        # Number of Descendants.
        NumberOfDescendants::number_of_descendants(current_case, progress_dialog, timer, items, num_descendants_metadata_key)
        
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
        if exclude_tag_prefix.empty?
            progress_dialog.log_message('Skipping exclude because exclude tag prefix is blank.')
        else
            timer.start('exclude_items')

            # Create a list of which tags in the case are exclusion tags.
            # All items with these tags will be excluded.
            progress_dialog.set_main_status_and_log_it('Finding exclusion tags...')
            timer.start('find_exclude_tags')
            exclude_tags = current_case.all_tags.select { |tag| tag.start_with?(exclude_tag_prefix) }
            timer.stop('find_exclude_tags')

            # Finds all selected items with exclusion tags.
            progress_dialog.set_main_status_and_log_it('Finding exclusion items...')
            timer.start('find_exclude_items')
            # Create a search string matching all items with exclusion tags.
            exclude_search = exclude_tags.map { |tag| "tag:\"#{tag}\""}.join(' OR ')
            if exclude_search.empty?
                # If there are no exclusion tags, skip exclusion.
                progress_dialog.log_message('Skipping exclusion since no matching tags were found.')
                timer.stop('find_exclude_items')
            else
                # Add a clause to ensure that only selected items will match the search.
                exclude_search += " AND tag:\"#{selected_item_tag}\""
                # Perform the search.
                exclude_items = current_case.search(exclude_search)
                timer.stop('find_exclude_items')
    
                # Actually exclude the items.
                progress_dialog.set_main_status_and_log_it('Excluding items...')
                Utils::bulk_exclude(utilities, progress_dialog, exclude_items, exclude_reason)
            end

            timer.stop('exclude_items')
        end

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

        timer.stop('total')
        timer.print_timings
    end
    
    CommonDialogs.show_information('Script finished.' , gui_title)
    
    Utils.print_progress('Script finished.')
else
    Utils.print_progress('Script cancelled.')
end
