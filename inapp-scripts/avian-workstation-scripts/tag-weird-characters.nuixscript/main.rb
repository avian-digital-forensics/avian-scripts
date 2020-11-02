script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

# GUI_TITLE is the name given to all GUI elements created by the InAppScript.
# SCRIPT_NAME should be of the form inapp_gui_template2.
unless script = Script::create_inapp_script(setup_directory, 'Tag Weird Characters', 'tag_weird_characters', current_case, utilities)
  STDERR.puts('Could not find main directory.')
  return
end

# Main directory path can be found in script.main_directory.
# Add requires here.
require File.join(script.main_directory, 'inapp-scripts', 'tag-weird-characters', 'tag_weird_characters')

# Setup GUI here.
# Fields added using InAppScript methods are saved automatically.
# The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
# To add default values, create a default settings file.
script.dialog_add_tab('main_tab', 'Main')

script.dialog_append_check_box('main_tab', 'run_only_on_selected_items', 'Run only on selected items',
    'QC and Culling will be run only on selected items if this is checked.')

script.dialog_append_text_field('main_tab', 'scoping_query', 'Scoping query',
    'QC and Culling will be run only on items matching this query.')

script.dialog_append_text_field('main_tab', 'non_weird_character_codes', 'Accepted character codes', 
    'A comma seperated list of unicode character codes to ignore.')

script.dialog_append_text_field('main_tab', 'tag_name', 'Tag name', 
    'The name of the tag given. Will be prefixed with "Avian|".')


# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
  
    # Make sure primary address is not empty.
    if values['tag_name'].strip.empty?
      CommonDialogs.show_warning('Please provide a non-empty tag name.', 'No Tag Name')
      next false
  end
  
  # Everything is fine; close the dialog.
  next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

  timer = script.timer

  scoping_query = script.settings['scoping_query']
  
  # Add a selected items tag to the scoping query if appropriate.
  if script.settings['run_only_on_selected_items']
    selected_item_tag = script.create_temporary_tag('SELECTEDITEMS', current_selected_items, 'selected items', progress_dialog)
    scoping_query = Utils::join_queries(scoping_query, "tag:\"#{selected_item_tag}\"")
  end

  # Get an array of the individual accepted characters.
  accepted_char_codes = script.settings['non_weird_character_codes'].split(',').map(&:to_i)
  puts('torsk: ' + accepted_char_codes.to_s)
  # If the tag name doesn't already start with 'Avian|' prepend it.
  tag_name = script.settings['tag_name'].start_with?('Avian|') ? script.settings['tag_name'] : 'Avian|' + script.settings['tag_name']
  
  TagWeirdCharacters::tag_weird_characters(current_case.search(scoping_query), progress_dialog, timer, utilities, accepted_char_codes, tag_name)
end
