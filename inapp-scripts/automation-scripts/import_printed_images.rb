module ImportPrintedImages
    extend self
    
    def run(nuix_case, utilities, settings_hash, progress_handler)
        main_directory = settings_hash[:main_directory]
        require File.join(main_directory, 'inapp-scripts', 'import-printed-images.nuixscript', 'import_printed_images')
        require File.join(main_directory,'utils','timer')

        timer = Timing::Timer.new
        timer.start('total')

        items = nuix_case.search(settings_hash[:scoping_query])
        source_path = settings_hash[:source_path]
        ImportPrintedImages::import_printed_images(items, source_path, progress_handler, timer, utilities)

        timer.stop('total')
        timer.print_timings
    end
end