module ConnectedAddresses
    extend self

    def run(nuix_case, utilities, settings_hash, progress_handler)
        main_directory = settings_hash[:main_directory]
        require File.join(main_directory,'utils','timer')
        require File.join(main_directory,'inapp-scripts', 'connected-addresses', 'connected_addresses')

        timer = Timing::Timer.new
        timer.start('total')

        # The address whose recipients are wanted.
        address = settings_hash[:primary_address]
      
        # The output path.
        file_path = settings_hash[:output_path]
      
        # The delimiter used in the CSV.
        delimiter = settings_hash[:delimiter]
        
        ConnectedAddresses::connected_addresses(nuix_case, progress_handler, timer, file_path, delimiter)

        progress_handler.log_message("Script finished.")
    
        timer.stop('total')
    end
end
