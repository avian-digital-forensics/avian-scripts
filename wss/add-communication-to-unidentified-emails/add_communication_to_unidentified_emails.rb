module AddCommunicationToUnidentifiedEmails
    extend self
    
    def run_init(wss_global)
        # Will be run once before loading items.
        # Setup script here.
        require 'yaml'

        root_path = wss_global.root_path

        require File.join(root_path, 'utils', 'custom_communication')

        # Finds the data file path.
        data_path = File.join(wss_global.case_data_path, 'unidentified_emails_data.yml')
        if File.file?(data_path)
            # Load data from file and save to wss_global.
            data = YAML.load_file(data_path)
            wss_global.vars[:add_communication_to_unidentified_emails_data] = data
            wss_global.vars[:add_communication_to_unidentified_emails_has_data] = true
        else
            wss_global.vars[:add_communication_to_unidentified_emails_has_data] = false
            STDERR.puts("Could not find data file. Did you remember to run 'FixUnidentifiedEmails'?")
        end
    end
    
    def run(wss_global, worker_item)
        # Will be run for each item.
        # This is the main body of the script.
        if wss_global.vars[:add_communication_to_unidentified_emails_has_data]
            data = wss_global.vars[:add_communication_to_unidentified_emails_data]
            if data.key?(worker_item.item_guid)
                # Create a CustomCommunication from the guid's data.
                communication = Custom::CustomCommunication::from_yaml_hash(data[worker_item.item_guid][0])
				
				# Set the item's communication to the created CustomCommunication.
                worker_item.set_item_communication(communication)

                # Get the desired MIME-type.
                mime_type = data[worker_item.item_guid][1]

                # Set the item's MIME-type.
                worker_item.set_item_type(mime_type)
            end
        else
            STDERR.puts("AddCommunicationToUnidentifiedEmails: No data file. Skipping.")
        end
    end
end