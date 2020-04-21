script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

# SCRIPT_NAME should be of the form inapp_gui_template2.
unless script = Script::create_inapp_script(setup_directory, GUI_TITLE, SCRIPT_NAME)
    return
end

# Main directory path can be found in script.main_directory.

script.dialog_add_tab('main_tab', 'Main')

script.dialog_append_check_box('main_tab', 'example_checkbox', 'Example Checkbox', 
        'Description of checkbox.')

script.dialog_append_text_field('main_tab', 'example_text_field', 'Example text field',
        'Description of text field.')

options = { 'Button 1' => 'button_1', 'Button 2' => 'button_2' }
script.dialog_append_horizontal_radio_button_group('main_tab', 'example_horizontal_radio_button', 'Example horizontal radio button', options)

script.dialog_append_vertical_radio_button_group('main_tab', 'example_vertical_radio_button', 'Example vertical radio button', options)


# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
    
    # TODO: ADD CHECKS HERE
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

    timer = script.timer
    
    # TODO: ADD SCRIPT HERE.
    
    return 'RESULT_MESSAGE'
end
