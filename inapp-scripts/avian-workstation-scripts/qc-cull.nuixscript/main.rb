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
require 'json'
# For GUI.
require File.join(main_directory,'utils','nx_utils')
# Timings.
require File.join(main_directory,'utils','timer')
# Progress messages.
require File.join(main_directory,'utils','utils')
# Save and load script settings.
require File.join(main_directory,'utils','settings_utils')

require File.join(main_directory,'inapp-scripts','qc-cull','main')

# Load saved settings.
script_settings = SettingsUtils::load_script_settings(main_directory,'qc_cull')

# Add main tab.
script.dialog_add_tab('main_tab', 'Main')

script.dialog_append_check_box('main_tab', 'run_only_on_selected_items', 'Run only on selected items',
    'QC and Culling will be run only on selected items if this is checked.')

script.dialog_append_text_field('main_tab', 'scoping_query', 'Scoping query',
    'QC and Culling will be run only on items matching this query.')

# Add a file chooser for the report destination.
script.dialog_append_save_file_chooser('main_tab', 'report_destination', 'Report destination', 'Rich Text File (.rtf)', 'rtf',
    'The generated report will be placed here.')

# Add a text field for the custom metadata name for number of descendants.
script.dialog_append_text_field('main_tab', 'num_descendants_metadata_key', 'Number of descendants custom metadata name', 
    'All items will receive a custom metadata field with this key.')

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

  settings_hash[:report_path] = script.settings['report_destination']

  # This next part takes the information the user inputted and updates the stored settings so the input will be remembered.
  settings_hash[:num_descendants_metadata_key] = script.settings['num_descendants_metadata_key']

  # Add search and tag file paths
  qc_search_and_tag_path = File.join(main_directory, 'data', 'misc', 'qc', 'qc_search_and_tag.json')
  culling_search_and_tag_path = File.join(main_directory, 'data', 'misc', 'qc', 'culling_search_and_tag.json')
  settings_hash[:search_and_tag_files] = [qc_search_and_tag_path, culling_search_and_tag_path]
  # If NSRL is turned on, add the search and tag file.
  if script.settings['nsrl']
    settings_hash[:search_and_tag_files] << File.join(main_directory, 'data', 'misc', 'qc', 'nsrl_search_and_tag.json')
  end

  # Set up exclusion tag prefix hash.
  exclusion_sets_path = File.join(main_directory, 'data', 'misc', 'qc', 'exclusion_sets.json')
  exclusion_sets_file = File.read(exclusion_sets_path)
  settings_hash[:exclude_tag_prefixes] = JSON.parse(exclusion_sets_file)

  
  # Add a selected items tag to the scoping query if appropriate.
  if run_only_on_selected_items
    selected_item_tag = script.create_temporary_tag('SELECTED_ITEMS', current_selected_items, 'selected items', progress_dialog)
    scoping_query = Utils::join_queries(scoping_query, "tag:\"#{selected_item_tag}\"")
  end
  items = current_case.search(scoping_query)

  # Create a hash with information for the report.
  report_info_hash = {}
  for key,value in script.settings
    if key.start_with?('info_')
      report_info_hash[key[5..-1]] = value
    end
  end
  QCCull::qc_cull(main_directory, current_case, utilities, progress_dialog, timer, scoping_query, settings_hash, report_info_hash)
  

  # No script finished message.
  ''
end
