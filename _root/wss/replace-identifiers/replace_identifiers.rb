require 'java'
require 'json'
require 'csv'

module ReplaceIdentifiers
    extend self
    
    # Returns the given address with address and personal part replaced if appropriate.
    def update_address(replace_identifiers_hash, address)
        result = Custom::CustomAddress.from_address(address)
        if result.address and replace_identifiers_hash.key?(result.address)
            result.address = replace_identifiers_hash[result.address]
        end
        if result.personal and replace_identifiers_hash.key?(result.personal)
            result.personal = replace_identifiers_hash[result.personal]
        end
        return result
    end
    
    # Returns a new list of addresses, all updated acording to the hash.
    def update_address_list(replace_identifiers_hash, address_list)
        return address_list.map{ |address| update_address(replace_identifiers_hash, address) }
    end
   
    # Returns a communcation with all identifiers updated.
    def update_communication(replace_identifiers_hash, communication)
        com = Custom::CustomCommunication.from_communication(communication)
        com.from_addresses = update_address_list(replace_identifiers_hash, com.from_addresses)
        com.to_addresses = update_address_list(replace_identifiers_hash, com.to_addresses)
        com.cc_addresses = update_address_list(replace_identifiers_hash, com.cc_addresses)
        com.bcc_addresses = update_address_list(replace_identifiers_hash, com.bcc_addresses)
        return com
    end
    
    def run_init(wss_global)
        # Will be run once before loading items.
        replace_identifiers_hash = {}
        file_path = File.join(wss_global.root_path, "data", "replace_identifiers.csv")
        if File.file?(file_path)
            CSV.foreach(file_path, "r") do |row|
                for item in row[1..-1]
                    replace_identifiers_hash[item] = row[0]
                end
            end
        end
        wss_global.vars[:replace_identifiers_hash] = replace_identifiers_hash
    end
    
    def run(wss_global, worker_item)
        root_path = wss_global.root_path
        require File.join(root_path, 'utils', 'custom_communication')
    
        # Will be run for each item.
        if (communication = worker_item.source_item.communication).nil?
            return # If the item has no communication, it has no communication to fix.
        end
        
        replace_identifiers_hash = wss_global.vars[:replace_identifiers_hash]
        
        # Replace identifiers in communication object.
        com = update_communication(replace_identifiers_hash, communication)
        # Set the items communication object.
        worker_item.set_item_communication(com)
    end
    
    def run_close(wss_global)
        # Will be run after loading all items.
    end
end