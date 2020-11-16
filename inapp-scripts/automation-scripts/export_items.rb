module ExportItems
    extend self

    def run(nuix_case, utilities, settings_hash, progress_handler)
        main_directory = settings_hash[:main_directory]
        require File.join(main_directory,'utils','timer')
        require File.join(main_directory,'inapp-scripts', 'export-items', 'export_items')

        timer = Timing::Timer.new
        timer.start('total')
      
        # If a scoping query is given, use that.
        scoping_query = settings_hash.key?(:scoping_query) ? settings_hash[:scoping_query] : ''
        items = nuix_case.search(scoping_query)
        
        script_finished_message = ExportItems::export_items(current_case, progress_dialog, timer, utilities, items, settings_hash)

        progress_handler.log_message("Script finished. #{script_finished_message}")
        timer.stop('total')
    end
end
