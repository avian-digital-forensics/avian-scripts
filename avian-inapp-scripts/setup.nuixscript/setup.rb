require 'yaml'
require 'fileutils'
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
  puts("Script cancelled.")
  return
end

require File.join(main_directory, 'utils', 'settings_utils')
require File.join(main_directory, 'utils', 'wss_setup')
require File.join(main_directory, 'utils', 'nx_utils')

settings_file = File.join(main_directory, 'data', 'wss_settings.yml')

# If the settings file does not exist, create it from defaults.
unless File.file?(settings_file)
  FileUtils.cp(File.join(main_directory, 'data', 'default_wss_settings.yml'), settings_file)
end

# Load current settings.
wss_setup = WSSSetup.load(main_directory, current_case.name, current_case.guid)

## Create GUI.
dialog = TabbedCustomDialog.new("Avian Scripts Setup")

# Add WSS tab.
wss_tab = dialog.add_tab("wss_tab", "WSS Setup")

for script in wss_setup.available_scripts
    .map { |script_identifier| wss_setup.script_information(script_identifier) }
  wss_tab.append_check_box(script[:identifier], script[:label], script[:active])
end

dialog.validate_before_closing do |values|
  
  # Everything is fine; close the dialog.
  next true
end

## Display GUI.
dialog.display

## Handle GUI input.
if dialog.get_dialog_result == true
  puts("Applying settings...")
  values = dialog.to_map
  
  # Set the new activation values for wss's.
  for script_identifier in wss_setup.available_scripts
    wss_setup.set_enabled(script_identifier, values[script_identifier])
  end
  
  # Let wss_setup finalize.
  wss_setup.setup
  
  # Inform user of finished script.
  CommonDialogs.show_information("Settings succesfully saved.", "WSS Setup")
  
  puts("Scripts finished.")
end
