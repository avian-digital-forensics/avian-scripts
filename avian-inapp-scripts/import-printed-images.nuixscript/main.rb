script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

gui_title = 'Import Printed Images'

# gui_title is the name given to all GUI elements created by the InAppScript.
unless script = Script::create_inapp_script(setup_directory, gui_title, 'import_printed_images', current_case, utilities)
  STDERR.puts('Could not find main directory.')
  return
end

# Main directory path can be found in script.main_directory.
# Add requires here.
# Main logic.
require File.join(script.main_directory,'avian-inapp-scripts','import-printed-images.nuixscript','import_printed_images')
# Find case data.
require File.join(script.main_directory,'utils','settings_utils')

# Setup GUI here.
# Fields added using InAppScript methods are saved automatically.
# The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
# To add default values, create a default settings file.
script.dialog_add_tab('main_tab', 'Main')

# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
  
  # Everything is fine; close the dialog.
  next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

  timer = script.timer
  
  data_dir = SettingsUtils.case_data_dir(script.main_directory, current_case.name, current_case.guid)
  printed_image_dir = File.join(data_dir, 'unidentified_emails_printed_images')

  items = []
  if current_selected_items.size == 0
    items = current_case.search('')
  else
    items = current_selected_items
  end
  num_imported_images = ImportPrintedImages::import_printed_images(items, printed_image_dir, progress_dialog, timer, utilities)
  
  "Imported a total of #{num_imported_images.to_s} printed images."
end
