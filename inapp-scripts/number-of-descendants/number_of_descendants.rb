require 'set'

module NumberOfDescendants
  extend self
  
  class NumDescendantsHash
    def initialize()
      @hash = {}
    end

    def add_item(item, num_descendants)
      unless @hash.key?(num_descendants)
        @hash[num_descendants] = Set[]
      end
      @hash[num_descendants].add(item)
    end

    # Adds the number of descendants of each item as custom metadata.
    def annotate(bulk_annotater, metadata_key, timer, progress_dialog)
      timer.start('num_descendants_add_metadata')

      num_items = @hash.values.map(&:size).reduce(0, :+)
      
      # Setup progress dialog
      progress_dialog.set_main_status_and_log_it('Adding number of descendants custom metadata...')
      main_progress = 0
      progress_dialog.set_main_progress(main_progress, num_items)
      progress_dialog.set_sub_status("#{main_progress.to_s}/#{num_items.to_s}")
      for num_descendants,item_set in @hash
        if item_set.size < 5
          # If the item set is too small, add metadata individually. This should maybe be removed.
          for item in item_set
            item.custom_metadata.put_integer(metadata_key, num_descendants.to_s)
            # Update progress dialog.
            progress_dialog.set_main_progress(main_progress += 1)
            progress_dialog.set_sub_status("#{main_progress.to_s}/#{num_items.to_s}")
          end
        else
          # Bulk annotate.
          bulk_annotater.put_custom_metadata(metadata_key, num_descendants, item_set) do |item_event_info| 
            # Update progress dialog.
            progress_dialog.set_main_progress(main_progress += 1)
            progress_dialog.set_sub_status("#{main_progress.to_s}/#{num_items.to_s}")
          end
        end
      end

      timer.stop('num_descendants_add_metadata')
    end
  end

  # Returns the number of descendants of the item.
  # +item+:: The item to find the number of descendants of.
  def num_descendants(item)
    return item.descendants.length
  end

  def number_of_descendants(current_case, progress_dialog, timer, items, metadata_key, bulk_annotater)

    progress_dialog.set_sub_progress_visible(false)
    
    # Add metadata to items.
    progress_dialog.set_main_status_and_log_it('Finding number of descendants of items...')
    timer.start('num_descendants_find_num_descendants')
    progress_dialog.set_main_progress(0, items.size)
    num_descendants_hash = NumDescendantsHash.new
    items.each_with_index do |item, item_index|
      # Find the number of descendants for item and add to hash.
      num_descendants_hash.add_item(item, num_descendants(item))

      # Update progress dialog.
      progress_dialog.increment_main_progress
      progress_dialog.set_sub_status("#{(item_index+1).to_s}/#{items.size.to_s}")
    end
    timer.stop('num_descendants_find_num_descendants')

    num_descendants_hash.annotate(bulk_annotater, metadata_key, timer, progress_dialog)
  end
end