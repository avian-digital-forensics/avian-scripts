script_directory = File.dirname(__FILE__)
setup_directory = File.join(script_directory,'..','setup.nuixscript')
require File.join(setup_directory,'inapp_script')

unless script = Script::create_inapp_script(setup_directory, "Ingest Fixed Width as CSV", "setup_ingest_fixed_width_as_csv", current_case, utilities)
  STDERR.puts('Could not find main directory.')
  return
end

# Main directory path can be found in script.main_directory.
# Add requires here.
require 'yaml'

require File.join(script.main_directory, 'utils', 'settings_utils')

# Setup GUI here.
# Fields added using InAppScript methods are saved automatically.
# The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
# To add default values, create a default settings file.
script.dialog_add_tab('main_tab', 'Main')


# Checks the input before closing the dialog.
script.dialog_validate_before_closing do |values|
  
  # TODO: ADD CHECKS HERE
  
  # Everything is fine; close the dialog.
  next true
end

# Display dialog. Receive input from user. Run script.
script.run do |progress_dialog|

  timer = script.timer
  
  data = {}

  #   :column_types: A comma seperated string of column types (date/id/sum).
  #   :column_headers: A comma seperated string of column headers.
  #   :line_format: A comma seperated string of start positions for each column in the fixed width file. Includes the index of the end of the line.
  #   :max_date_diff: The maximum second difference for two entries to be combined into one.

  for item in current_selected_items
    column_format_hash = {}

    custom_metadata = item.custom_metadata

    error = false
    # Column types.
    unless custom_metadata.key?('ColumnTypes')
      script.show_error("Item #{item.guid} does not have custom metadata field ColumnTypes.")
      error = true
      break
    end
    column_types = custom_metadata['ColumnTypes'].split(',')
    possible_column_types = ['date', 'id', 'sum', 'ignore']
    if invalid_column_type = column_types.find { |column_type| !possible_column_types.include?(column_type) }
      script.show_error("Invalid ColumnType '#{invalid_column_type}' for item #{item.guid}")
      error = true
      break
    else
      column_format_hash[:column_types] = column_types
    end

    # Column headers.
    unless custom_metadata.key?('ColumnHeaders')
      script.show_error("Item #{item.guid} does not have custom metadata field ColumnHeaders.")
      error = true
      break
    end
    column_headers = custom_metadata['ColumnHeaders'].split(',')
    unless column_headers.size == column_types.count { |column_type| column_type != 'ignore' }
      script.show_error("Invalid column headers for item #{item.guid}. There must be as many column headers as there are non-'ignore' column types.")
      error = true
      break
    end
    column_format_hash[:column_headers] = column_headers

    # Line format.
    unless custom_metadata.key?('LineFormat')
      script.show_error("Item #{item.guid} does not have custom metadata field LineFormat.")
      error = true
      break
    end
    line_format = custom_metadata['LineFormat'].split(',').map { |column_index| column_index.to_i }
    unless line_format.size == column_types.size + 1
      script.show_error("Invalid line format for item #{item.guid}. There must be a column position for every column type, plus one for the end of the line.")
      error = true
      break
    end
    if line_format.each_cons(2).any? { |seg_start_pos, seg_end_pos| seg_end_pos <= seg_start_pos }
      script.show_error("Invalid line format for item #{item.guid}. Column positions must be an array of increasing non-negative integers.", script.gui_title)
      error = true
      break
    end
    column_format_hash[:line_format] = line_format

    # Max date diff.
    unless custom_metadata.key?('MaxDateDiff')
      script.show_error("Item #{item.guid} does not have custom metadata field MaxDateDiff.", script.gui_title)
      error = true
      break
    end
    max_date_diff = custom_metadata['MaxDateDiff'].to_f
    column_format_hash[:max_date_diff] = max_date_diff

    data[item.guid] = column_format_hash
  end
  
  if error
    'An error occured'
  else
    data_path = File.join(script.case_data_dir, 'ingest_fixed_width_as_csv_metadata.yml')
    File.open(data_path, 'w') { |file| file.write(data.to_yaml) }
    'Line format information succesfully written to file. Ingest Fixed Width as CSV is now ready to be run.'
  end
end
