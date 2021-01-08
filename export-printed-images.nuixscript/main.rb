script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

# GUI_TITLE is the name given to all GUI elements created by the InAppScript.
# SCRIPT_NAME should be of the form inapp_gui_template2.
unless script = Script::create_inapp_script(setup_directory, 'Export Printed Images', 'export_printed_images', current_case, utilities)
  STDERR.puts('Could not find main directory.')
  return
end

# Main directory path can be found in script.main_directory.
# Add requires here.
require File.join(script.main_directory, 'avian-inapp-scripts', 'export-printed-images.nuixscript', 'export_printed_images')

# Setup GUI here.
# Fields added using InAppScript methods are saved automatically.
# The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
# To add default values, create a default settings file.
script.dialog_add_tab('main_tab', 'Main')

script.dialog_append_check_box('main_tab', 'run_only_on_selected_items', 'Run only on selected items', 
    'If this is checked, run the script only on selected items.')

script.dialog_append_text_field('main_tab', 'scoping_query', 'Scoping query',
    'Only export the printed image of items matching this query.')


# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
  
  # TODO: ADD CHECKS HERE
  
  # Everything is fine; close the dialog.
  next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

  run_only_on_selected_items = script.settings['run_only_on_selected_items']
  scoping_query = script.settings['scoping_query']

  timer = script.timer
  
  scoping_query = scoping_query == '' ? 'has-printed-image:1' : "(#{scoping_query}) AND has-printed-image:1"
  if run_only_on_selected_items
    selected_items_tag = script.create_temporary_tag('SELECTED_ITEMS', current_selected_items, 'selected items', progress_dialog)
    scoping_query = Utils::join_queries(scoping_query, "tag:\"#{selected_items_tag}\"")
  end

  images_exported = ExportPrintedImages::export_printed_images(script.main_directory, progress_dialog, timer, utilities, current_case, scoping_query)

  next "Exported a total of #{images_exported.to_s} printed images."
end
