module NumberOfDescendants
    extend self
    
    def run(nuix_case, utilities, settings_hash, progress_handler)
        main_directory = settings_hash[:main_directory]
        require File.join(main_directory, 'inapp-scripts', 'number-of-descendants', 'number_of_descendants')
        require File.join(main_directory,'utils','timer')

        timer = Timing::Timer.new
        timer.start('total')

        # If a scoping query is given, use that.
        scoping_query = settings_hash.key?(:scoping_query) ? settings_hash[:scoping_query] : ''
        items = nuix_case.search(scoping_query)
        metadata_key = settings_hash[:metadata_key]
        NumberOfDescendants::number_of_descendants(nuix_case, progress_handler, timer, items, metadata_key, utilities.bulk_annotater)

        timer.stop('total')
        timer.print_timings
    end
end