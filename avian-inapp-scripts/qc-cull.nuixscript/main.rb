script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

gui_title = 'QC and Culling'

unless script = Script::create_inapp_script(setup_directory, gui_title, 'qc_cull', current_case, utilities)
  STDERR.puts('Could not find main directory.')
  return
end

main_directory = script.main_directory

require 'fileutils'
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

# Load saved settings.
script_settings = SettingsUtils::load_script_settings(main_directory,'qc_cull')

# Add main tab.
script.dialog_add_tab('main_tab', 'Main')

# Add a file chooser for the report destination.
script.dialog_append_save_file_chooser('main_tab', 'report_destination', 'Report destination', 'Rich Text File (.rtf)', 'rtf',
    'The generated report will be placed here.')

# Add a text field for the custom metadata name for number of descendants.
script.dialog_append_text_field('main_tab', 'num_descendants_metadata_key', 'Number of descendants custom metadata name', 
    'All items will receive a custom metadata field with this key.')

# Add file chooser for the QC search and tag.
script.dialog_append_open_file_chooser('main_tab', 'qc_search_and_tag_file', 'QC Search and Tag file', 'JSON', 'json', 
    'This file will be loaded into the search and tag.')

# Add file chooser for the Culling search and tag.
script.dialog_append_open_file_chooser('main_tab', 'culling_search_and_tag_file', 'Culling Search and Tag file', 'JSON', 'json', 
    'This file will be loaded into the search and tag.')

# Add information tab.
script.dialog_add_tab('information', 'Info')
script.dialog_append_text_field('information', 'project_name', 'Project name',
    'The name of the project. Used when generating the report.')
script.dialog_append_text_field('information', 'collection_number', 'Collection number',
    'The collection number. Used when generating the report.')

# Add exclusion tab.
script.dialog_add_tab('exclusion', 'Culling')
# Add text fields for exclusion prefixes.
# Any items with tags with a prefix, will be excluded with the specified reason.
exclusion_prefix_num = 0
while script_settings.key?("exclusion_prefix_#{exclusion_prefix_num + 1}")
  exclusion_prefix_num += 1
  script.dialog_append_text_field('exclusion', "exclusion_prefix_#{exclusion_prefix_num}", "Exclusion prefix #{exclusion_prefix_num}",
      'Any items with a tag with this prefix will be excluded with the associated reason.')
  script.dialog_append_text_field('exclusion', "exclusion_reason_#{exclusion_prefix_num}", "Exclusion reason #{exclusion_prefix_num}",
      'Any items with a tag with the associated prefix will be excluded with this reason.')
end



# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
  if values['report_destination'].strip.empty?
    CommonDialogs.show_warning('Please provide a destination for the generated report.', gui_title)
    next false
  end

  if values['num_descendants_metadata_key'].strip.empty?
    CommonDialogs.show_warning('Please provide a metadata key for the number of descendants of each item.', gui_title)
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
  timer = script.timer

  report_path = script.settings['report_destination']

  # This next part takes the information the user inputted and updates the stored settings so the input will be remembered.
  num_descendants_metadata_key = script.settings['num_descendants_metadata_key']

  exclude_tag_prefixes = {}
  for k in 1..exclusion_prefix_num
    prefix = script.settings["exclusion_prefix_#{k}"]
    reason = script.settings["exclusion_reason_#{k}"]
    unless prefix.empty?
      if reason.empty?
        STDERR.puts('Sum ting wong! sdfgonvr')
      end
      exclude_tag_prefixes[prefix] = reason
    end
  end

  search_and_tag_files = []
  if script.settings['qc_search_and_tag_file'] != ''
    search_and_tag_files << script.settings['qc_search_and_tag_file']
  end
  if script.settings['culling_search_and_tag_file'] != ''
    search_and_tag_files << script.settings['culling_search_and_tag_file']
  end

  bulk_annotater = utilities.get_bulk_annotater
  
  
  items = current_selected_items

  # The actual QC process starts here.

  # Number of Descendants.
  NumberOfDescendants::number_of_descendants(current_case, progress_dialog, timer, items, num_descendants_metadata_key, bulk_annotater)
  
  selected_item_tag = script.create_temporary_tag('SELECTEDITEMS', items, 'selected items', progress_dialog)

  # Search and Tag. Both QC and culling.
  # Skipped if no .json file is specified.
  if search_and_tag_files.any?
    QCCull::search_and_tag(current_case,progress_dialog,timer,search_and_tag_files,'tag:"' + selected_item_tag + '"')
  else
    progress_dialog.log_message('Skipping search and tag since no files were selected.')
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
  end

  # Report.
  result_hash = {}
  # Add ingestion information to report.
  result_hash['FIELD_project_name'] = script.settings['project_name']
  result_hash['FIELD_collection_number'] = script.settings['collection_number']
  current_time = Time.now.strftime("%d/%m/%Y")
  result_hash['FIELD_qc_start_date'] = current_time

  # Find report template.
  report_template_path = File.join(main_directory,'data','qc_report_template.rtf')
  FileUtils.cp(report_template_path, report_path)
  # Update report with results.
  QCCull::update_report(result_hash, report_path)

  # No script finished message.
  ''
end
