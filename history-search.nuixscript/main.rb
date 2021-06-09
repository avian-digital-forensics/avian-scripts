script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

# GUI_TITLE is the name given to all GUI elements created by the InAppScript.
# SCRIPT_NAME should be of the form inapp_gui_template2.
unless script = Script::create_inapp_script(setup_directory, 'History Search', 'history_search', current_case, utilities)
  STDERR.puts('Could not find main directory.')
  return
end

# Main directory path can be found in script.root_directory.
# Add requires here.
require_relative '../_root/inapp-scripts/history-search/history_search'

# Setup GUI here.
# Fields added using InAppScript methods are saved automatically.
# The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
# To add default values, create a default settings file.
script.dialog_add_tab('main_tab', 'Main')


script.dialog_append_check_box('main_tab', 'run_only_on_selected_items', 'Run only on selected items',
  'QC and Culling will be run only on selected items if this is checked.')
script.dialog_append_text_field('main_tab', 'scoping_query', 'Scoping query',
  'QC and Culling will be run only on items matching this query.')

script.dialog_append_date_picker('main_tab', 'start_date_range_start', 'Event start date range start',
    'Only considers history events with start date after this')
script.dialog_append_date_picker('main_tab', 'start_date_range_end', 'Event start date range end',
    'Only considers history events with start date before this')
script.dialog_append_text_field('main_tab', 'users', 'Users', 
    'A comma seperated list of strings denoting user names. Script only considers history events by one of these users. Use the same names as Nuix shows in history.')
script.dialog_append_text_field('main_tab', 'global_tag', 'Tag', 
    'A tag given to all items with events with in the start date range done by one of the specified users. Leave empty to skip this step.')

script.dialog_add_tab('tag_tab', 'Tags')
script.dialog_append_text_field('tag_tab', 'event_tag', 'Event tag', 
    'The tag to search for events about. Leave empty to find all tag events.')
script.dialog_append_check_box('tag_tab', 'tag_added', 'Tag added', 
    'Whether to act on events where the specified tag was added.')
script.dialog_append_check_box('tag_tab', 'tag_removed', 'Tag removed', 
    'Whether to act on events where the specified tag was removed.')
script.dialog_append_text_field('tag_tab', 'tag_tag', 'Tag', 
    'The tag to give to all items with events where \'Event tag\' was added or removed if those are specified. Leave empty to skip this step.')


# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
  
  # TODO: ADD CHECKS HERE
  
  # Everything is fine; close the dialog.
  next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

  scoping_query = script.settings['scoping_query']
  run_only_on_selected_items = script.settings['run_only_on_selected_items']

  # Add a selected items tag to the scoping query if appropriate.
  if run_only_on_selected_items
    selected_item_tag = script.create_temporary_tag('SELECTED_ITEMS', current_selected_items, 'selected items', progress_dialog)
    scoping_query = Utils::join_queries(scoping_query, Utils::create_tag_query(selected_item_tag))
  end

  settings_hash = {
    :start_date_range_start => script.settings['start_date_range_start'],
    :start_date_range_end => script.settings['start_date_range_end'],
    :users => script.settings['users'],
    :global_tag => script.settings['global_tag'],
    
    :event_tag => script.settings['event_tag'],
    :tag_added => script.settings['tag_added'],
    :tag_removed => script.settings['tag_removed'],
    :tag_tag => script.settings['tag_tag'],
  }

  timer = script.timer
  HistorySearch::history_search(script.root_directory, current_case, utilities, progress_dialog, script, timer, scoping_query, settings_hash)
  
  ''
end
