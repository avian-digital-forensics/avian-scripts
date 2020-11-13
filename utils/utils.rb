require 'set'
require 'fileutils'

module Utils
    def self.alpha_num_char_set 
        [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
    end
    
    # Returns a string time stamp with the current time.
    def self.time_stamp()
        return Time.now.getutc.to_s[0...-4]
    end
    
    # Print to the log a message with a timestamp.
    def self.print_progress(message)
        puts(time_stamp + "  " + message)
    end
    
    # Creates a sample of size num_elements, from array.
    def self.sample(array, num_elements, with_replacement=false)
        if with_replacement
            return Array.new(num_elements) { rand(0..array.length-1) }.map { |index| array[index] }
        else
            return array.sample(num_elements)
        end
    end
    
    # Returns the number of nano seconds since epoch in the time as a single big integer.
    def self.time_to_nano(time)
        return time.tv_sec*(10**9)+time.tv_nsec
    end
    
    # Returns the current number of nano seconds since epoch as a single big integer.
    def self.nano_now
        return time_to_nano(Time.now)
    end
    
    # Returns a random string of length num_chars from the given char_set.
    def self.random_string(num_chars, char_set)
        return sample(char_set, num_chars, true).join
    end

    # Adds the specified tag to all given items.
    # Progress is shown in the main progress bar of the given progress dialog.
    def self.bulk_add_tag(utilities, progress_dialog, tag, items)
        progress_dialog.set_sub_progress_visible(false)
        progress_dialog.set_main_progress(0, items.size)
        bulk_annotater = utilities.get_bulk_annotater
        num_items = items.size
        item_num = 0
        bulk_annotater.add_tag(tag, items) do |event_info|
            progress_dialog.increment_main_progress
            progress_dialog.set_sub_status("#{item_num += 1}/#{num_items}")
        end
    end

    # Removes the specified tag from all given items.
    # Progress is shown in the main progress bar of the given progress dialog.
    def self.bulk_remove_tag(utilities, progress_dialog, tag, items)
        progress_dialog.set_sub_progress_visible(false)
        progress_dialog.set_main_progress(0, items.size)
        bulk_annotater = utilities.get_bulk_annotater
        num_items = items.size
        item_num = 0
        bulk_annotater.remove_tag(tag, items) do |event_info|
            progress_dialog.increment_main_progress
            progress_dialog.set_sub_status("#{item_num += 1}/#{num_items}")
        end
    end

    # Excludes the specified items with the specified reason.
    # Progress is shown in the main progress bar of the given progress dialog.
    def self.bulk_exclude(utilities, progress_dialog, items, exclusion_reason)
        progress_dialog.set_sub_progress_visible(false)
        progress_dialog.set_main_progress(0, items.size)
        bulk_annotater = utilities.get_bulk_annotater
        num_items = items.size
        item_num = 0
        bulk_annotater.exclude(exclusion_reason, items) do |event_info|
            progress_dialog.increment_main_progress
            progress_dialog.set_sub_status("#{item_num += 1}/#{num_items}")
        end
    end
    
    # Returns true if all the given sets are disjoint.
    def self.sets_disjoint?(*sets)
        total = Set[]
        for set in sets.map(&:to_set)
            unless set.disjoint?(total)
                return false
            end
            total = total | set
        end
    end
    
    def self.search_count_deduplicated(nuix_case, search, utilities)
        item_utility = utilities.item_utility
        item_utility.deduplicate(nuix_case.search_unsorted(search)).size.to_s
    end

    # Exports the printed images of the given images to the specified directory.
    # Params:
    # +items+:: The items whose printed images to export.
    # +directory+:: The directory to export them to.
    # +utilities+:: A reference to the Nuix Utitilies class.
    # +progress_dialog+:: The progress dialog to show results in. Only used if non-null.
    def self.export_printed_images(items, directory, utilities, progress_dialog=nil)
        FileUtils.mkdir_p(directory)
		items_processed = 0
        if progress_dialog
            progress_dialog.set_main_status_and_log_it('Exporting printed images...')
            progress_dialog.set_main_progress(0, items.size)
            progress_dialog.set_sub_status("Printed images exported: " + items_processed.to_s)
        end
        
        # Use single export because batch export seems to be only slightly faster, while this is far simpler.
        exporter = utilities.pdf_print_exporter
        for item in items
			if item.is_kind?('no-data')
				progress_dialog.log_message("Unable to export printed image for item '#{item.name}'. Could not find data. GUID:#{item.guid}")
			else
				exporter.export_item(item, "#{directory}/#{item.guid}.pdf")
			end
            if progress_dialog
                progress_dialog.increment_main_progress
                progress_dialog.set_sub_status("Printed images exported: " + (items_processed += 1).to_s)
            end
        end
    end

    # Combines all given search queries with ANDs.
    # Params:
    # +queries+:: Arbitrarily many queries or arrays of queries to be combined.
    def self.join_queries(*queries)
        queries.flatten.map { |query| query == '' ? nil : "(#{query})" }.reject(&:nil?).join(' AND ')
    end

    # Ensures that the given directory exists.
    # Params:
    # +path+:: The path including the directory to ensure.
    def self.ensure_path_exists(path)
        FileUtils.mkpath(path) unless File.exists?(path)
    end
end
