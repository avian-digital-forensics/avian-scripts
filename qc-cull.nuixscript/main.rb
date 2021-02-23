require 'json'

script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

gui_title = 'QC and Culling'

unless script = Script::create_inapp_script(setup_directory, gui_title, 'qc_cull', current_case, utilities)
  STDERR.puts('Could not find main directory.')
  return
end

root_directory = script.root_directory

require 'fileutils'
require 'json'
# For GUI.
require File.join(root_directory,'utils','nx_utils')
# Timings.
require File.join(root_directory,'utils','timer')
# Progress messages.
require File.join(root_directory,'utils','utils')
# Save and load script settings.
require File.join(root_directory,'utils','settings_utils')

require File.join(root_directory,'inapp-scripts','qc-cull','main')

# Load saved settings.
script_settings = SettingsUtils::load_script_settings(root_directory,'qc_cull')

# Add main tab.
script.dialog_add_tab('main_tab', 'Main')

script.dialog_append_check_box('main_tab', 'run_only_on_selected_items', 'Run only on selected items',
    'QC and Culling will be run only on selected items if this is checked.')

script.dialog_append_text_field('main_tab', 'scoping_query', 'Scoping query',
    'QC and Culling will be run only on items matching this query.')

existing_qc_handling_options = {
  'Remove Metadata' => :remove_metadata, 
  'Exclude Items from QC' => :exclude_from_qc, 
  'Tag Items and Cancel QC' => :tag_items_and_cancel_script, 
  'Ignore' => :ignore
}
script.dialog_append_combo_box('main_tab', 'existing_qc_handling', 'Handling of existing QC metadata', existing_qc_handling_options.keys, 
    'Choose how the script will react if it finds items that already have QC and Culling related metadata.')

# Add a file chooser for the report destination.
script.dialog_append_save_file_chooser('main_tab', 'report_destination', 'Report destination', 'Rich Text File (.rtf)', 'rtf',
    'The generated report will be placed here.')

# Add a text field for the custom metadata name for number of descendants.
script.dialog_append_text_field('main_tab', 'num_descendants_metadata_key', 'Number of descendants custom metadata name', 
    'All items will receive a custom metadata field with this key.')

# Add text field for the number of source files provided when loading the case.
script.dialog_append_text_field('main_tab', 'num_source_files_provided', 'Number of source files',
    'The number of original source files provided for ingestion. This is checked against the number of loose files in Nuix.')

# Add text field for the format of dates in the report.
script.dialog_append_text_field('main_tab', 'date_format', 'Date format',
    'The format of dates in the report. For the full syntax, search `ruby strftime` on the web, but in short: %Y is the full year, %m is the month e.g. \'02\', and %d is the day e.g. \'04\' or \'25\'')

# Add check box for running NSRL.
script.dialog_append_check_box('main_tab', 'nsrl', 'Run NSRL',
    'Whether to search for NSRL items. This may take a long time.')

# Add information tab.
script.dialog_add_tab('information', 'Info')
script.dialog_append_text_field('information', 'info_project_name', 'Project name',
    'The name of the project. Used when generating the report.')
script.dialog_append_text_field('information', 'info_collection_number', 'Collection number',
    'The collection number. Used when generating the report.')
script.dialog_append_text_field('information', 'info_requested_by', 'Ingestion requested by',
    'Who requested the ingestion. Used when generating the report.')
script.dialog_append_date_picker('information', 'info_ingestion_start_date', 'Ingestion started',
    'When ingestion started. Used when generating the report.')
script.dialog_append_date_picker('information', 'info_ingestion_end_date', 'Ingestion ended',
    'When ingestion ended. Used when generating the report.')
script.dialog_append_text_field('information', 'info_ingestion_performed_by', 'Ingestion performed by',
    'Who performed the ingestion. Used when generating the report.')
script.dialog_append_text_field('information', 'info_qc_performed_by', 'QC performed by',
    'Who performed the qc. Used when generating the report.')



# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
  if values['num_descendants_metadata_key'].strip.empty?
    CommonDialogs.show_warning('Please provide a metadata key for the number of descendants of each item.', gui_title)
    next false
  end
  
  # Everything is fine; close the dialog.
  next true
end

script.run do |progress_dialog|
  timer = script.timer

  settings_hash = {}
  run_only_on_selected_items = script.settings['run_only_on_selected_items']
  scoping_query = script.settings['scoping_query']

  settings_hash[:existing_qc_handling] = existing_qc_handling_options[script.settings['existing_qc_handling']]

  settings_hash[:report_path] = script.settings['report_destination']

  settings_hash[:num_descendants_metadata_key] = script.settings['num_descendants_metadata_key']
  settings_hash[:num_source_files_provided] = script.settings['num_source_files_provided']

  settings_hash[:date_format] = script.settings['date_format']

  # Add search and tag file paths
  qc_search_and_tag_path = File.join(root_directory, 'data', 'misc', 'qc', 'qc_search_and_tag.json')
  culling_search_and_tag_path = File.join(root_directory, 'data', 'misc', 'qc', 'culling_search_and_tag.json')
  settings_hash[:search_and_tag_files] = [qc_search_and_tag_path, culling_search_and_tag_path]
  # If NSRL is turned on, add the search and tag file.
  if script.settings['nsrl']
    settings_hash[:search_and_tag_files] << File.join(root_directory, 'data', 'misc', 'qc', 'nsrl_search_and_tag.json')
  end

  # Set up exclusion tag prefix hash.
  exclusion_sets_path = File.join(root_directory, 'data', 'misc', 'qc', 'exclusion_sets.json')
  exclusion_sets_file = File.read(exclusion_sets_path)
  settings_hash[:exclude_tag_prefixes] = JSON.parse(exclusion_sets_file)

  
  # Add a selected items tag to the scoping query if appropriate.
  if run_only_on_selected_items
    selected_item_tag = script.create_temporary_tag('SELECTED_ITEMS', current_selected_items, 'selected items', progress_dialog)
    scoping_query = Utils::join_queries(scoping_query, Utils::create_tag_query(selected_item_tag))
  end
  items = current_case.search(scoping_query)

  # Create a hash with information for the report.
  report_info_hash = {}
  for key,value in script.settings
    if key.start_with?('info_')
      report_info_hash[key[5..-1]] = value
    end
  end
  QCCull::qc_cull(root_directory, current_case, utilities, progress_dialog, timer, scoping_query, settings_hash, report_info_hash)
  

  # No script finished message.
  ''
end
