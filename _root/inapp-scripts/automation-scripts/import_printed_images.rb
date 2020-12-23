module ImportPrintedImages
    extend self
    
    def run(nuix_case, utilities, settings_hash, progress_handler)
        root_directory = settings_hash[:root_directory]
        require File.join(root_directory, 'inapp-scripts', 'import-printed-images', 'import_printed_images')
        require File.join(root_directory,'utils','timer')

        timer = Timing::Timer.new
        timer.start('total')
        
        # If a scoping query is given, use that.
        scoping_query = settings_hash.key?(:scoping_query) ? settings_hash[:scoping_query] : ''
        items = nuix_case.search(scoping_query)
        source_path = settings_hash[:source_path]
        images_imported = ImportPrintedImages::import_printed_images(items, source_path, progress_handler, timer, utilities)
        progress_handler.log_message("Script finished. Imported a total of #{images_imported} printed images.")

        timer.stop('total')
    end
end