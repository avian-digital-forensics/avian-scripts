module ConnectedAddresses
    extend self

    def run(nuix_case, utilities, settings_hash, progress_handler)
        root_directory = settings_hash[:root_directory]
        require File.join(root_directory,'utils','timer')
        require File.join(root_directory,'inapp-scripts', 'connected-addresses', 'connected_addresses')

        timer = Timing::Timer.new
        timer.start('total')

        # The address whose recipients are wanted.
        address = settings_hash[:primary_address]
      
        # The output path.
        file_path = settings_hash[:output_path]
      
        # The delimiter used in the CSV.
        # Default to ','.
        delimiter = settings_hash.key?(:delimiter) ? settings_hash[:delimiter] : ','
        
        script_finished_message = ConnectedAddresses::connected_addresses(nuix_case, progress_handler, timer, file_path, delimiter)

        progress_handler.log_message("Script finished. #{script_finished_message}")
    
        timer.stop('total')
    end
end
