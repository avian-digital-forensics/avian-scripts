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
# Culling.
require File.join(main_directory,'avian-inapp-scripts','qc-cull.nuixscript','culling')

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
script.dialog_append_text_field('information', 'requested_by', 'Ingestion requested by',
    'Who requested the ingestion. Used when generating the report.')
script.dialog_append_text_field('information', 'ingestion_performed_by', 'Ingestion performed by',
    'Who performed the ingestion. Used when generating the report.')

script.dialog_append_text_field('information', 'qc_performed_by', 'QC performed by',
    'Who performed the qc. Used when generating the report.')

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

  run_only_on_selected_items = script.settings['run_only_on_selected_items']
  scoping_query = script.settings['scoping_query']

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
  
  
  if run_only_on_selected_items
    selected_item_tag = script.create_temporary_tag('SELECTEDITEMS', current_selected_items, 'selected items', progress_dialog)
    scoping_query = Utils::join_queries(scoping_query, "tag:\"#{selected_item_tag}\"")
  end
  items = current_case.search(scoping_query)

  # The actual QC process starts here.

  # Number of Descendants.
  NumberOfDescendants::number_of_descendants(current_case, progress_dialog, timer, items, num_descendants_metadata_key, bulk_annotater)

  # Search and Tag. Both QC and culling.
  # Skipped if no .json file is specified.
  if search_and_tag_files.any?
    QCCull::search_and_tag(current_case,progress_dialog,timer,search_and_tag_files, scoping_query)
  else
    progress_dialog.log_message('Skipping search and tag since no files were selected.')
  end

  # Culling.
  if exclude_tag_prefixes.empty?
    progress_dialog.log_message('Skipping exclude because no exclude tag prefixes were specified.')
  else
    QCCull::exclude_items(current_case, scoping_query, exclude_tag_prefixes, progress_dialog, timer, utilities)
  end

  # Report.
  progress_dialog.set_main_status_and_log_it('Generating report...')
  # Find report template.
  report_template_path = File.join(main_directory,'data','templates','qc_report_template.rtf')
  # Generate report.
  QCCull::generate_report(current_case, report_template_path, report_path, script.settings, utilities)

  # No script finished message.
  ''
end
