# Standard code for finding main directory.
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled because no main directory could be found.")
    return
end

# For GUI.
require File.join(main_directory,"utils","nx_utils")
# Timings.
require File.join(main_directory,"utils","timer")
# Progress messages.
require File.join(main_directory,"utils","utils")
# Import the superutilities to use the PdfUtility
require File.join(main_directory, "resources", "SuperUtilities.jar")
java_import com.nuix.superutilities.SuperUtilities
$su = SuperUtilities.init($utilities,NUIX_VERSION)
java_import com.nuix.superutilities.misc.PdfUtility
java_import com.nuix.superutilities.export.PdfWorkCache

gui_title = 'Watermark PDFs'

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
main_tab = dialog.add_tab("main_tab", "Main")

default_path = currentCase.location.to_s + "\\tag-metadata-to-pdf"

# Settings for the items that should be watermarked
main_tab.append_check_box("current_selected_items", "Watermark current selected items", true)
main_tab.append_check_box("exported_items", "Watermark exported items", false)
main_tab.append_directory_chooser("exported_path", "Path for the exported items", default_path, java.lang.System.getProperty(default_path))
main_tab.enabled_only_when_checked("exported_path", "exported_items")

# Settings for the watermark
main_tab.append_spinner("opacity", "Opacity", 25, 0, 100)
main_tab.append_spinner("rotation", "Rotation", 45, 0, 360)
main_tab.append_spinner("font_size", "Font size", 48)
main_tab.append_text_field("tag", "Tag", current_case.name)

# Add directory chooser for output path and set default path to the case path
main_tab.append_text_field("prefix", "Prefix for the output files", "")
main_tab.append_directory_chooser("output_path", "Output Path", default_path, java.lang.System.getProperty(default_path))

# Validate the options
dialog.validate_before_closing do |values|
    # Make sure path is not empty.
    if values["output_path"].strip.empty?
        CommonDialogs.show_warning("Please provide a non-empty output path.", "No Output Path")
        next false
    end

    # Checks if the user wants to use already exported items
    if values["exported_items"]
        # Same thing here - check that path is not empty
        if values["exported_path"].strip.empty?
            CommonDialogs.show_warning("Please provide a non-empty path for Exported items or uncheck the box", "No Path")
            next false
        end

        # Make sure the user is using a prefix if the output-path is the same as the exported-path
        if values["exported_path"].to_s == values["output_path"].to_s
            if values["prefix"].strip.empty?
                CommonDialogs.show_warning("Please provide a prefix for the files if the output-path is the same as the export-path", "No Prefix")
                next false
            end
        end

        # Check if the exported-path has a PDFs directory
        $exported_pdf_path = values["exported_path"]
        if $exported_pdf_path.to_s[-4, 4] != "PDFs"
            $exported_pdf_path = File.join($exported_pdf_path, "\\PDFs")
            if !File.directory?($exported_pdf_path)
                CommonDialogs.show_warning("Can't find the PDFs directory #{values["exported_path"]}", "Missing PDFs path")
                next false
            end
            
        end
    end
   
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

# If dialog result is false, the user has cancelled.
if dialog.dialog_result
    Utils.print_progress('Running script...')
    
    # values contains the information the user inputted.
    values = dialog.to_map

    timer = Timing::Timer.new

    timer.start('total')

    # Set the path for export and make sure it exists
    path = values["output_path"]
    java.io.File.new(path).mkdirs

    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end

        # Create variables if the settings needs extra formatting
        tag = values["tag"]
        font_size = values["font_size"]
        opacity = values["opacity"].to_f / 100
        rotation = values["rotation"]

        progress_dialog.log_message("Watermarking PDFs with tag: #{tag}, font-size: #{font_size}, opacity: #{opacity}, rotation: #{rotation}")

        item_count = 0
        if values["current_selected_items"]
            progress_dialog.log_message("Looking for current selected items within Nuix")
            item_count += current_selected_items.length
            progress_dialog.log_message("Found #{item_count.to_s} selected items")
        end
        if values["exported_items"]
            progress_dialog.log_message("Looking for items in exported path: #{$exported_pdf_path}")
            exported_count = Dir.glob(File.join($exported_pdf_path, '**', '*')).select { |file| File.file?(file) }.count
            progress_dialog.log_message("Found #{exported_count.to_s} items in the exported PDF directory")
            item_count += exported_count
        end

        progress_dialog.set_sub_progress_visible(false)
        progress_dialog.log_message("Found a total of #{item_count.to_s} items to process.")
        timer.start('process_items')
        progress_dialog.set_main_status_and_log_it('Processing items...')
        progress_dialog.set_main_progress(0, item_count)

        counter = 0 # counter to set progress-bar

        # Check if the user wants to watermark current selected items within Nuix
        if values["current_selected_items"]
            timer.start("selected_items")

            # create a tmp-path and initialize the pdf work cache
            tmp_path = path + "\\tmp"
            java.io.File.new(tmp_path).mkdirs
            pdf_cache = PdfWorkCache.new(java.io.File.new(tmp_path))

            # Loop through the selected items
            for item, item_index in current_selected_items.each_with_index
                counter += 1
                # Get the file-name
                file_name = item.path_names[-1]

                # If current item is not a PDF - convert it
                if item.type.to_s != 'application/pdf'
                    progress_dialog.log_message("Item #{file_name} type: #{item.type.to_s} - skipping item")
                    next
                    # FIX ME : Need to convert this file to a PDF
                end

                # Check if we need to add a prefix to the file
                if !values["prefix"].strip.empty?
                    file_name = values["prefix"] + "-" + file_name
                end

                # Set the file-path to where the watermarked file should be exported
                tagged_path = File.join(path, file_name)

                # Get file-path for the tmp PDF
                tmp_item = pdf_cache.get_pdf_path(item)

                progress_dialog.log_message("Creating watermarked PDF to: #{path} with filename: #{file_name}")
                PdfUtility.create_water_marked_pdf(tmp_item.to_s, tagged_path, values["tag"], font_size, opacity, rotation)

                progress_dialog.increment_main_progress
                progress_dialog.set_sub_status("#{counter}/#{item_count} - #{item}")
            end
            pdf_cache.cleanup_temporary_pdfs() # This will cleanup directly after this for-loop instead of when Nuix closes
            timer.stop("selected_items")
        end

        # Check if the user chose to watermark items that has already been exported
        if values["exported_items"]
            timer.start("exported_items")
             # Loop through the exported items
             for file_name, file_index in Dir.entries($exported_pdf_path)
                input = File.join($exported_pdf_path, file_name)
                # Check if the file-extension is PDF
                if file_name.to_s[-4, 4] != ".pdf"
                    progress_dialog.log_message("Item #{file_name} seems to not be a PDF - skipping item")
                    next
                end
                
                counter += 1

                # Check if we need to add a prefix to the file
                if !values["prefix"].strip.empty?
                    file_name = values["prefix"] + "-" + file_name
                end

                output = File.join(path, file_name)
                progress_dialog.log_message("Creating watermarked PDF to: #{path} with filename: #{file_name}")
                PdfUtility.create_water_marked_pdf(input, output, values["tag"], font_size, opacity, rotation)
                progress_dialog.increment_main_progress
                progress_dialog.set_sub_status("#{counter}/#{item_count} - #{item}")
             end
             timer.stop("exported_items")
        end

        timer.stop('process_items')

        timer.stop('total')
        timer.print_timings()
        script_finished_message = "Script finished."
        # Write result to GUI.
        progress_dialog.log_message(script_finished_message)
        CommonDialogs.show_information(script_finished_message, 'Tag Metadata to PDF')
    end
else
    Utils.print_progress('Script cancelled.')
end

