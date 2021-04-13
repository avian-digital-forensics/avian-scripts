script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

# GUI_TITLE is the name given to all GUI elements created by the InAppScript.
# SCRIPT_NAME should be of the form inapp_gui_template2.
unless script = Script::create_inapp_script(setup_directory, 'Tag Report', 'tag_report', current_case, utilities)
  STDERR.puts('Could not find main directory.')
  return
end

# Main directory path can be found in script.root_directory.
# Add requires here.

require File.join(script.root_directory,'inapp-scripts','tag-report','main')

# Setup GUI here.
# Fields added using InAppScript methods are saved automatically.
# The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
# To add default values, create a default settings file.
script.dialog_add_tab('main_tab', 'Main')

# Add check box that if ticked ensures that the script is only run on selected items.
script.dialog_append_check_box('main_tab', 'run_only_on_selected_items', 'Run only on selected items',
    'QC and Culling will be run only on selected items if this is checked.')

# Add text field for the scoping query.
script.dialog_append_text_field('main_tab', 'scoping_query', 'Scoping query',
    'QC and Culling will be run only on items matching this query.')

# Add text field for the collection number.
script.dialog_append_text_field('main_tab', 'collection_number', 'Collection number',
    'The collection number. Used when generating the report.')

# Add date field for the latest revision date.
script.dialog_append_date_picker('main_tab', 'latest_revision', 'Latest revision date',
    'When the last revision took place. Used when generating the report.')

# Add file chooser for search and tag file.
script.dialog_append_open_file_chooser('main_tab', 'search_and_tag_file_path', 'Search and Tag File', 'JavaScript Object Notation (.json)', 'json',
    'The search and tag file to run before generating the report.')

# Add text field for the tag prefix.
script.dialog_append_text_field('main_tab', 'tag_prefix', 'Tag prefix',
  'When generating the report, any tag with this prefix will have it removed. Automatically adds \'|\' to the end if this is missing.')

# Add text field for the tag suffix.
script.dialog_append_text_field('main_tab', 'tag_suffix', 'Tag suffix',
    'When generating the report, any tag with this suffix will have it removed. Automatically adds \'|\' to the beginning if this is missing.')

# Add a file chooser for the report destination.
script.dialog_append_save_file_chooser('main_tab', 'report_destination', 'Report destination', 'Extensible Markup Language (.xml)', 'xml',
    'The generated report will be placed here.')

# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
  
  if values['search_and_tag_file'] != nil && values['search_and_tag_file'] != '' && !File.file?(values['search_and_tag_file'])
    CommonDialogs.show_warning('Please provide an existing search and tag file or leave the field blank to skip that step.')
    next false
  end

  if !values['search_and_tag_file'].end_with?('.json')
    CommonDialogs.show_warning('Search and tag file must have .json extension.')
    next false
  end

  if values['latest_revision'] == '' || values['latest_revision'].nil?
    CommonDialogs.show_warning('Please enter a latest revision date.')
    next false
  end
  
  # Everything is fine; close the dialog.
  next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

  timer = script.timer

  scoping_query = script.settings['scoping_query']

  settings_hash = {
    :root_directory => script.root_directory,
    :collection_number => script.settings['collection_number'],
    :latest_revision => script.settings['latest_revision'],
    :search_and_tag_file_path => script.settings['search_and_tag_file_path'],
    :tag_prefix => script.settings['tag_prefix'].end_with?('|') ? script.settings['tag_prefix'] : script.settings['tag_prefix'] + '|',
    :tag_suffix => script.settings['tag_suffix'].start_with?('|') ? script.settings['tag_suffix'] : '|' + script.settings['tag_suffix'],
    :report_destination => script.settings['report_destination']
  }

  # Add a selected items tag to the scoping query if appropriate.
  if script.settings['run_only_on_selected_items']
    selected_item_tag = script.create_temporary_tag('SELECTED_ITEMS', current_selected_items, 'selected items', progress_dialog)
    scoping_query = Utils::join_queries(scoping_query, Utils::create_tag_query(selected_item_tag))
  end
  
  TagReport::tag_report(current_case, utilities, progress_dialog, timer, scoping_query, settings_hash)
  
  # No script finished message.
  ''
end
