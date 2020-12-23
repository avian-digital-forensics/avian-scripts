# Replace module name with appropriate name.
module AutomationTemplate
    extend self

    def run(nuix_case, utilities, settings_hash, progress_handler)
        root_directory = settings_hash[:root_directory]
        require File.join(root_directory,'utils','timer')
        # Require stuff here.

        timer = Timing::Timer.new
        timer.start('total')

        # Write code here.

        progress_handler.log_message("Script finished.")
    
        timer.stop('total')
    end
end
