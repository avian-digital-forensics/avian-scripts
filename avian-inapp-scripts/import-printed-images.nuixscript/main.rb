script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

gui_title = 'Import Printed Images'

# gui_title is the name given to all GUI elements created by the InAppScript.
unless script = Script::create_inapp_script(setup_directory, gui_title, 'import_printed_images')
  STDERR.puts('Could not find main directory.')
  return
end

# Main directory path can be found in script.main_directory.
# Add requires here.

# Setup GUI here.
# Fields added using InAppScript methods are saved automatically.
# The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
# To add default values, create a default settings file.
script.dialog_add_tab('main_tab', 'Main')

script.dialog_append_directory_chooser('main_tab', 'printed_image_dir', 'Source Directory', 
    'The directory to search for printed images.')

# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
  if values['printed_image_dir'].strip.empty?
    CommonDialogs.show_warning('Please provide a source for the printed images.', gui_title)
    next false
  end
  
  # Everything is fine; close the dialog.
  next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

  timer = script.timer
  
  items = []
  if current_selected_items.size == 0
    items = current_case.search('')
  else
    items = current_selected_items
  end
  num_imported_images = ImportPrintedImages::import_printed_images(items, script.settings['printed_image_dir'], progress_dialog, timer, utilities)
  
  return "Imported a total of #{num_imported_images} printed images."
end
