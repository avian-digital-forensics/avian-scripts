module ImportPrintedImages
  extend self

  # Imports a printed image for all items with an image in the source directory.
  # Params:
  # +items+:: The items to look for printed images for.
  # +source_path+:: The directory in which to look for printed images.
  # +progress_handler+:: Something that can handle progress like a progress dialog.
  # +timer+:: The timer to record internal timings in.
  # +utilities+:: A reference to the Nuix utilities object.
  def import_printed_images(items, source_path, progress_handler, timer, utilities)
    total_images = 0

    # Find the names of alle pdf's in the source directory
    progress_handler.set_main_status_and_log_it('Finding files to import from...')
    files = Dir.entries(source_path).select { |file| file.end_with?('.pdf') }.to_set
    importer = utilities.pdf_print_importer

    timer.start('import_printed_images')
    progress_handler.set_main_status_and_log_it('Importing printed images...')
    num_items = items.size
    main_progress = 0
    progress_handler.set_main_progress(main_progress, num_items)
    progress_handler.set_sub_status("#{main_progress.to_s}/#{num_items.to_s}")
    for item in items
      guid = item.guid
      file_name = "#{guid}.pdf"
      # Is there a printed image for this file.
      if files.include?(file_name)
        # Import the printed image.
        importer.import_item(item, File.join(source_path, file_name))
        total_images += 1
      end
      progress_handler.set_main_progress(main_progress += 1)
      progress_handler.set_sub_status("#{main_progress.to_s}/#{num_items.to_s}")
    end
    timer.stop('import_printed_images')
    # Return the number of printed images imported.
    return total_images
  end
end