require 'csv'

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
# Storing entity information.
require File.join(main_directory,'utils','custom_entity')
# Saving data.
require File.join(main_directory,'utils','settings_utils')
# Entities manager.
require File.join(main_directory,'utils','custom_entity_manager')

gui_title = 'Store Custom Entities'

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab('main_tab', 'Main')

# TODO: ADD GUI HERE


# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    
    # TODO: ADD CHECKS HERE
    
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

    timer = Timing::Timer.new

    timer.start('total')

    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
        progress_dialog.set_sub_progress_visible(false)

        items = current_selected_items
        
        entities = CustomEntityManager::CustomEntityManager.new

        # Search custom metadata for custom tags.
        progress_dialog.set_main_status_and_log_it('Searching metadata...')
        timer.start('search_metadata')
        progress_dialog.set_main_progress(0,items.size)
        items.each_with_index do |item, item_index|
            item.custom_metadata.for_each do |key, value|
                if key.start_with?('AvianEntity|') # For every key that starts with 'AvianEntity|'
                    entity = key.split('|')
                    unless entity.size == 3 # Custom metadata for custom entities must have a specific form.
                        progress_dialog.log_message("Invalid custom metadata '#{key}' in item '#{item.guid}'. Custom entity metadata must be of the form AvianEntity|<EntityType>|<EntityName>.")
                        next
                    end
                    begin
                        entity_amount = value.to_i
                        unless entity_amount >= 0 # Entitiy amounts cannot be negative.
                            progress_dialog.log_message("Invalid custom metadata value '#{value.to_s}' for metadata '#{key}' in item '#{item.guid}'. Amount must be non-negative.")
                        end
                        unless entity_amount == 0 # If the entity amount is 0, there is no reason to save it.
                            entities.add_entity(item.guid, CustomEntity::CustomEntity.new(entity[1],entity[2],entity_amount))
                        end
                    rescue ArgumentError # If the custom metadata value isn't an integer.
                        progress_dialog.log_message("Invalid custom metadata value '#{value.to_s}' for metadata '#{key}' in item '#{item.guid}'. Value must be a non-negative integer.")
                    end
                end
            end
            progress_dialog.increment_main_progress
            progress_dialog.set_sub_status("#{item_index+1}/#{items.size}")
        end
        timer.stop('search_metadata')

        
        # Search tags for custom entities.
        progress_dialog.set_main_status_and_log_it('Searching tags...')
        timer.start('search_tags')

        entity_tags = current_case.all_tags.select{ |tag| tag.start_with?('Avian|Entity|') }

        progress_dialog.set_main_progress(0,entity_tags.size)
        progress_dialog.set_sub_progress_visible(true)
        entity_tags.each_with_index do |tag, tag_index| # For all tags starting with 'Avian|Entity|'
            tag_parts = tag.split('|')
            progress_dialog.set_sub_status("#{tag_index}/#{entity_tags.size}: Tag \"#{tag}\"")
            items_with_tag = current_case.search("tag:\"#{tag}\"")
            progress_dialog.set_sub_progress(0,items_with_tag.size)
            items_with_tag.each_with_index do |item, item_index|
                entities.add_entity(item.guid, CustomEntity::CustomEntity.new(tag_parts[2],tag_parts[3],1))
                progress_dialog.incrememnt_sub_progress
            end
            
            progress_dialog.increment_main_progress
        end
        progress_dialog.set_sub_progress_visible(false)
        timer.stop('search_tags')

        progress_dialog.set_main_status_and_log_it('Saving entities...')
        timer.start('save_entities')
        output_dir = SettingsUtils::case_data_dir(main_directory, current_case)
        
        output_file_path = File.join(output_dir,'store_custom_entities_store.csv')
        CSV.open(output_file_path, 'wb') do |csv|
            entities.to_csv(csv)
        end
        timer.stop('save_entities')


        timer.stop('total')
        
        timer.print_timings
        
        progress_dialog.set_completed
        finish_message = 'Script finished. Stored entities for ' + entities.num_items.to_s + " items. \nThe result has been stored and is ready for use by other scripts."
        CommonDialogs.show_information(finish_message, gui_title)
        Utils.print_progress(finish_message)
    end
else
    Utils.print_progress('Script cancelled.')
end
