require 'set'
require 'fileutils'

module Utils
  extend self

  def alpha_num_char_set 
    [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
  end
  
  # Returns a string time stamp with the current time.
  def time_stamp()
    return Time.now.getutc.to_s[0...-4]
  end
  
  # Print to the log a message with a timestamp.
  def print_progress(message)
    puts(time_stamp + "  " + message)
  end
  
  # Creates a sample of size num_elements, from array.
  def sample(array, num_elements, with_replacement=false)
    if with_replacement
      return Array.new(num_elements) { rand(0..array.length-1) }.map { |index| array[index] }
    else
      return array.sample(num_elements)
    end
  end
  
  # Returns the number of nano seconds since epoch in the time as a single big integer.
  def time_to_nano(time)
    return time.tv_sec*(10**9)+time.tv_nsec
  end
  
  # Returns the current number of nano seconds since epoch as a single big integer.
  def nano_now
    return time_to_nano(Time.now)
  end
  
  # Returns a random string of length num_chars from the given char_set.
  def random_string(num_chars, char_set)
    return sample(char_set, num_chars, true).join
  end

  # Adds the specified tag to all given items.
  # Progress is shown in the main progress bar of the given progress dialog.
  def bulk_add_tag(utilities, progress_dialog, tag, items)
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
  def bulk_remove_tag(utilities, progress_dialog, tag, items)
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
  def bulk_exclude(utilities, progress_dialog, items, exclusion_reason)
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
  def sets_disjoint?(*sets)
    total = Set[]
    for set in sets.map(&:to_set)
      unless set.disjoint?(total)
        return false
      end
      total = total | set
    end
  end

  # Exports the printed images of the given images to the specified directory.
  # Params:
  # +items+:: The items whose printed images to export.
  # +directory+:: The directory to export them to.
  # +utilities+:: A reference to the Nuix Utitilies class.
  # +progress_dialog+:: The progress dialog to show results in. Only used if non-null.
  def export_printed_images(items, directory, utilities, progress_dialog=nil)
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

  # Export binaries and store the hash so that the WSS Add Children can actually add the children.
  # Params:
  # +case_data_dir+:: The path string to the case's data directory. The hash yml and binary directory will be located here.
  # +child_hash+:: A hash of parent->[children] stored as item references.
  # +utilities+:: A reference to the Nuix Utitilies class.
  # +progress_dialog+:: The progress dialog to show results in.
  def prepare_add_children(case_data_dir, child_hash, utilities, progress_dialog)
    binary_dir = File.join(case_data_dir, 'add_children_binaries')
    FileUtils.mkdir_p(binary_dir)
    children = child_hash.values.flatten
    
	  items_processed = 0
    progress_dialog.set_main_status_and_log_it('Exporting child binaries...')
    progress_dialog.set_main_progress(0, children.size)
    progress_dialog.set_sub_status("Child binaries exported: " + items_processed.to_s)
    # Use single export because this seems similar to exporting printed images above.
    exporter = utilities.binary_exporter
    for child in children
      exporter.export_item(child, File.join(binary_dir, child.guid.to_s))
      progress_dialog.increment_main_progress
      progress_dialog.set_sub_status("Child binaries exported: " + (items_processed += 1).to_s)
    end
    
    guid_hash = {}

	  items_processed = 0
    progress_dialog.set_main_status_and_log_it('Creating GUID-hash...')
    progress_dialog.set_main_progress(0, child_hash.size)
    progress_dialog.set_sub_status("Parents added: " + items_processed.to_s)
    for parent,child_list in child_hash
      guid_hash[parent.guid] = child_list.map { |child| child.guid }
      progress_dialog.increment_main_progress
      progress_dialog.set_sub_status("Parents added: " + (items_processed += 1).to_s)
    end
    File.open(File.join(case_data_dir, 'add_children.yml'), 'w') { |file| file.write(guid_hash.to_yaml) }
  end

  # If the worker_item is a parent in the child_hash, it is given its children.
  # Params:
  # +child_binary_dir+:: A directory with binaries of all the children listed in child_hash. The files should have the items GUID as name.
  # +child_hash+:: A hash of parent->[children] stored as GUIDs.
  # +worker_item+:: A Nuix worker item to work on if its GUID is listen in child_hash as a parent.
  def execute_add_children(child_binary_dir, child_hash, worker_item)
    if child_hash.key?(worker_item.item_guid)
      child_guids = child_hash[worker_item.item_guid]

      binaries = []
      for child_guid in child_guids
        binary_path = File.join(child_binary_dir, child_guid)
        if File.exist?(binary_path)
          binaries << binary_path
        else
          STDERR.puts("AddChildren: Missing binary for child: #{child_guid}.")
        end
      end
      worker_item.set_children(binaries)
    end
  end

  # Adds hyphens to a GUID that doesn't have any.
  # Mostly useful when working with GUIDs from WorkerItem.getGuidPath.
  # Params:
  # +guid+:: The GUID to add hyphens to.
  def add_hyphens_to_guid(guid)
    if guid.include?('-')
      guid
    else
      "#{guid[0..7]}-#{guid[8..11]}-#{guid[12..15]}-#{guid[16..19]}-#{guid[20..31]}"
    end
  end
end