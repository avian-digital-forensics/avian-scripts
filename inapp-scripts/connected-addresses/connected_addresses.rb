require_relative 'connections'

module ConnectedAddresses
    def connected_addresses(nuix_case, progress_handler, timer, primary_address, file_path, delimiter)
        # The output path.
        unless file_path.end_with?('.csv')
            file_path += '.csv'
        end

        connections = ConnectedAddresses::Connections.new
      
        timer.start('find_from')
        progress_handler.set_main_status_and_log_it('Finding messages from the primary address...')
        # All communication items with a from matching the given identifier.
        emails_from = nuix_case.search("from:\"#{primary_address}\" has-communication:1")
        # Handle all communication items from.
        for item in emails_from
            connections.add_communication_item_from(item)
        end
        timer.stop('find_from')
      
        timer.start('find_to')
        progress_handler.set_main_status_and_log_it('Finding messages to the primary address...')
        # All communication items with a to matching the given identifier.
        emails_to = nuix_case.search("to:\"#{primary_address}\" has-communication:1")
        # Handle all communication items to.
        for item in emails_to
            connections.add_communication_item_to(item)
        end
        timer.stop('find_to')
      
        timer.start('find_cc')
        progress_handler.set_main_status_and_log_it('Finding messages cc the primary address...')
        # All communication items with a cc matching the given identifier.
        emails_cc = nuix_case.search("cc:\"#{primary_address}\" has-communication:1")
        # Handle all communication items cc.
        for item in emails_cc
            connections.add_communication_item_cc(item)
        end
        timer.stop('find_cc')
      
        timer.start('find_bcc')
        progress_handler.set_main_status_and_log_it('Finding messages bcc the primary address...')
        # All communication items with a bcc matching the given identifier.
        emails_bcc = nuix_case.search("bcc:\"#{primary_address}\" has-communication:1")
        # Handle all communication items bcc.
        for item in emails_bcc
            connections.add_communication_item_bcc(item)
        end
        timer.stop('find_bcc')
      
        timer.start('write_results')
        progress_handler.set_main_status_and_log_it('Writing results to file...')
        File.open(file_path, 'w') do |file
          # Add header.
          headers = ['address', 'receive_to', 'receive_cc', 'receive_bcc', 'receive_total', 'send_to', 'send_cc', 'send_bcc', 'send_total', 'total']
          file.puts(headers.join(delimiter))
          # Add data.
          file.puts(connections.to_s(delimiter))
        end
        timer.stop('write_results')
        
        "Found #{connections.num_recipients.to_s} connected addresses.\nResults written to: #{file_path}"
    end
end