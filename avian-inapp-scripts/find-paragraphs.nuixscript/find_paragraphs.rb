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
# Timings.
require File.join(main_directory,"utils","timer")
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

    timer = Timing::Timer.new
    
    timer.start('total')
    ProgressDialog.for_block do |progress_dialog|
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
        progress_dialog.set_sub_progress_visible(false)

        items = current_case.search('')

        # Setup regex scanner.
        regex_scanner = $su.createRegexScanner
        regex_scanner.add_pattern('Paragraph', '(\u00a7[ ]?\d{1,4}\b)')

        regex_scanner.when_progress_updated do |value|
            progress_dialog.set_main_progress(value)
        end

        tags = {}

        # Create scan callback
        scan_callback = Proc.new do |item_match_collection|
            regex_scanner.abort_scan if progress_dialog.abort_was_requested

            item = item_match_collection.item

            item_match_collection.matches.each do |match|
                paragraph = match.value.gsub(/\s/, '')
                
                tags[paragraph] = Set[] unless tags.key?(paragraph)
                tags[paragraph] << item
            end
        end
        # Scan all items.
        timer.start('scan')
        progress_dialog.set_main_progress(0, items.size)
        progress_dialog.set_main_status_and_log_it("Scanning all items...")
        regex_scanner.scan_items(items, scan_callback)
        timer.stop('scan')

        # Add tags.
        timer.start('tags')
        progress_dialog.set_main_progress(0, tags.size)
        progress_dialog.set_main_status_and_log_it("Adding tags...")
        tags_processed = 0
        bulk_annotater = $utilities.bulk_annotater
        tags.each do |paragraph, tag_items|
            bulk_annotater.add_tag('Avian|Paragraphs|' + paragraph, tag_items.to_a)
            progress_dialog.set_main_progress(tags_processed += 1)
        end
        timer.stop('tags')

        timer.stop('total')

        CommonDialogs.show_information('Script finished.', gui_title)
        progress_dialog.log_message('Script finished.')
    
        timer.print_timings()
    end
    
    Utils.print_progress('Script finished.')
else
    Utils.print_progress('Script cancelled.')
end
