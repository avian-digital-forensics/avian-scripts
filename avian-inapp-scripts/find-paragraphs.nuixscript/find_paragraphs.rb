script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','setup.nuixscript','get_main_directory')

main_directory = get_main_directory(false)

unless main_directory
    puts('Script cancelled.')
    return
end

# Regex scanner.
require File.join(main_directory,'resources','SuperUtilities.jar')
java_import 'com.nuix.superutilities.SuperUtilities'
$su = SuperUtilities.init($utilities, NUIX_VERSION)
# GUI.
require File.join(main_directory,'utils','nx_utils')
# Progress messages.
require File.join(main_directory,'utils','utils')
# Tag groups.
require 'set'

gui_title = 'Find Paragraphs'

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab('main_tab', 'Main')

# TODO: ADD GUI HERE


# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    
    # TODO: ADD CHECKS HERE
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

# If dialog result is false, the user has cancelled.
if dialog.dialog_result == true
    puts('Running script...')
    
    # values contains the information the user inputted.
    values = dialog.to_map
    
    ProgressDialog.for_block do |progress_dialog|
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end

        items = current_case.search('')

        progress_dialog.set_main_progress(0, items.size)
        
        regex_scanner = $su.createRegexScanner
        regex_scanner.add_pattern('Paragraph', '(\u00a7[ ]?\d{1,4}\b)')

        regex_scanner.when_progress_updated do |value|
            progress_dialog.set_main_progress(value)
        end

        tags = {}

        scan_callback = Proc.new do |item_match_collection|
            regex_scanner.abort_scan if progress_dialog.abort_was_requested

            item = item_match_collection.item

            item_match_collection.matches.each do |match|
                paragraph = match.value.gsub(/\s/, '')
                
                tags[paragraph] = Set[] unless tags.key?(paragraph)
                tags[paragraph] << item
            end
        end
        regex_scanner.scan_items(items, scan_callback)

        bulk_annotater = $utilities.bulk_annotater
        tags.each do |paragraph, tag_items|
            bulk_annotater.add_tag('Avian|Paragraphs|' + paragraph, tag_items.to_a)
        end
    end
    
    CommonDialogs.show_information('Script finished.', gui_title)
    
    puts('Script finished.')
else
    puts('Script cancelled.')
end
