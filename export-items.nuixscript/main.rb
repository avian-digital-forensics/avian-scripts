require_relative File.join('..','setup.nuixscript','inapp_script')


unless script = Script::create_inapp_script(setup_directory, 'Export Items', 'export_items', current_case, utilities)
  STDERR.puts('Could not find root directory.')
  return
end

# Requires.
require File.join(script.root_directory, 'inapp-scripts', 'export-items', 'export_items')

# Load saved settings.
script_settings = SettingsUtils::load_script_settings(script.root_directory,'export_items')

# Add main tab.
script.dialog_add_tab('main_tab', 'Main')

script.dialog_append_check_box('main_tab', 'run_only_on_selected_items', 'Run only on selected items',
  'Selected items will only get exported if this is checked.')

script.dialog_append_text_field('main_tab', 'scoping_query', 'Scoping query',
  'Items matching this query will be exported.')

# Add a directory chooser for output of the exported items
# Add a file chooser for the csv destination.
script.dialog_append_directory_chooser('main_tab', 'output_path', 'Output path', 'The exported items will be placed here.')

script.dialog_append_check_box('main_tab', 'export_text', 'Export text', 'Export text.')
script.dialog_append_check_box('main_tab', 'export_pdf', 'Export PDFs', 'Export PDFs.')
script.dialog_append_check_box('main_tab', 'export_tiff', 'Export TIFFs', 'Export TIFFs.')
script.dialog_append_check_box('main_tab', 'export_natives', 'Export Natives', 'Export natives.')

# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values| 
  # Make sure path is not empty.
  if values['output_path'].strip.empty?
    CommonDialogs.show_warning('Please provide a non-empty output path.', 'No Output Path')
    next false
  end

  # Everything is fine; close the dialog.
  next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|
  timer = script.timer

  settings_hash = {}
  settings_hash[:output_path] = script.settings['output_path']
  settings_hash[:export_text] = script.settings['export_text']
  settings_hash[:export_pdf] = script.settings['export_pdf']
  settings_hash[:export_tiff] = script.settings['export_tiff']
 
  scoping_query = script.settings['scoping_query']
  run_only_on_selected_items = script.settings['run_only_on_selected_items']

  # Get the items to export
  # Add a selected items tag to the scoping query if appropriate.
  if run_only_on_selected_items
    selected_item_tag = script.create_temporary_tag('SELECTED_ITEMS', current_selected_items, 'selected items', progress_dialog)
    scoping_query = Utils::join_queries(scoping_query, "tag:\"#{selected_item_tag}\"")
  end
  items = current_case.search(scoping_query)

  ExportItems::export_items(current_case, progress_dialog, timer, utilities, items, settings_hash)
end
