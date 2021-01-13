script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

# GUI_TITLE is the name given to all GUI elements created by the InAppScript.
# SCRIPT_NAME should be of the form inapp_gui_template2.
unless script = Script::create_inapp_script(setup_directory, 'Connected Addresses', 'connected_addresses', current_case, utilities)
  STDERR.puts('Could not find root directory.')
  return
end

# Root directory path can be found in script.root_directory.
# Add requires here.
require File.join(script.root_directory, 'inapp-scripts', 'connected-addresses', 'connected_addresses')

# Setup GUI here.
# Fields added using InAppScript methods are saved automatically.
# The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
# Remember to create a default settings file.
script.dialog_add_tab('main_tab', 'Main')

script.dialog_append_text_field('main_tab', 'primary_address', 'Primary address',
    'The address to examine.')

# Add a file chooser for the csv destination.
script.dialog_append_save_file_chooser('main_tab', 'output_path', 'Output path', 'Comma Seperated Values', 'csv',
    'The generated csv will be placed here.')

# Add delimiter selector.
delimiter_options = { 'Comma (,)' => ',', 'Semicolon (;)' => ';', 'Space ( )' => ' ' , 'Custom' => 'custom' }
script.dialog_append_horizontal_radio_button_group('main_tab', 'delimiter', 'Delimiter', delimiter_options)

# Add custom delimiter text field.
script.dialog_append_text_field('main_tab', 'custom_delimiter', 'Custom delimiter', 'If the above is set to "Custom", this will be used as delimiter in the csv file.')


# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
    # Make sure primary address is not empty.
    if values['primary_address'].strip.empty?
        CommonDialogs.show_warning('Please provide a non-empty primary address.', 'No Primary Address')
        next false
    end
    # Make sure path is not empty.
    if values['output_path'].strip.empty?
        CommonDialogs.show_warning('Please provide a non-empty output path.', 'No Output Path')
        next false
    end

    # Make sure custom delimiter is not empty if that option is chosen.
    if values['delimiter'] == 'custom' && values['custom_delimiter'].strip.empty?
        CommonDialogs.show_warning('If you choose to provide your own delimiter, please do so.', 'No custom delimiter')
        next false
    end
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

  timer = script.timer
  # The address whose recipients are wanted.
  address = script.settings['primary_address']

  # The output path.
  file_path = script.settings['output_path']

  # What delimiter is used between values on the same line.
  delimiter = script.settings['delimiter']
  if delimiter == 'custom'
      delimiter = script.settings['custom_delimiter']
  end
  
  ConnectedAddresses::connected_addresses(current_case, progress_dialog, timer, address, file_path, delimiter)
end
