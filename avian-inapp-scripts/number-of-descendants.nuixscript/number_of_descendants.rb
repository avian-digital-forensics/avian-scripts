module NumberOfDescendants
    extend self
    
    # Returns the number of descendants of the item.
    def num_descendants(item)
        return item.descendants.length
    end

    def number_of_descendants(current_case, progress_dialog, timer, items, metadata_key)

        progress_dialog.set_sub_progress_visible(false)
        
        # Add metadata to items.
        progress_dialog.set_main_status_and_log_it('Finding number of descendants of items...')
        timer.start('find_num_descendants')
        progress_dialog.set_main_progress(0, items.size)
        items.each_with_index do |item, item_index|
            # Add a custom metadata field to each item with the number of descendants.
            item.custom_metadata[metadata_key] = num_descendants(item)

            progress_dialog.increment_main_progress
            progress_dialog.set_sub_status("#{item_index+1}/#{items.size}")
        end
        timer.stop('find_num_descendants')
    end
end