require 'java'
require 'json'
require 'csv'
java_import 'nuix.Address'
java_import 'nuix.Communication'

module ReplaceIdentifiers
    extend self
    
    class SimpleAddress
		include Address
        
        attr_accessor :personal, :address

		def initialize(address)
			@personal = address.personal
			@address = address.address
		end

		def getPersonal
			@personal
		end

		def getAddress
			@address
		end
		
		def setAddress(address)
			@address = address
		end

		def getType
			"internet-mail"
		end

		def toRfc822String
			@address
		end

		def toDisplayString
			@address
		end

		def equals(address)
			address == @address
		end
	end

	class SimpleCommunication
		include Communication
        attr_accessor :date_time, :from_addresses, :to_addresses, :cc_addresses, :bcc_addresses

		def initialize(communication)
			@date_time = communication.date_time
			@from_addresses = if communication.from then communication.from else [] end
			@to_addresses = if communication.to then communication.to else [] end
			@cc_addresses = if communication.cc then communication.cc else [] end
			@bcc_addresses = if communication.bcc then communication.bcc else [] end
		end

		def getDateTime
			@date_time
		end
		def getFrom
			@from_addresses
		end
		def set_from(from_addresses)
			@from_addresses = from_addresses
		end
		def getTo
			@to_addresses
		end
		def getCc
			@cc_addresses
		end
		def getBcc
			@bcc_addresses
		end
	end
    
    # Returns the given address with address and personal part replaced if appropriate.
    def update_address(replace_identifiers_hash, address)
        result = SimpleAddress.new(address)
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
        com = SimpleCommunication.new(communication)
        com.from_addresses = update_address_list(replace_identifiers_hash, com.from_addresses)
        com.to_addresses = update_address_list(replace_identifiers_hash, com.to_addresses)
        com.cc_addresses = update_address_list(replace_identifiers_hash, com.cc_addresses)
        com.bcc_addresses = update_address_list(replace_identifiers_hash, com.bcc_addresses)
    end
    
    def run_init(wss_global)
        # Will be run once before loading items.
        replace_identifiers_hash = {}
        file_path = File.join(wss_global.root_path, "utils", "replace_identifiers.csv")
        CSV.foreach(file_path, "r") do |row|
            for item in row[1..-1]
                replace_identifiers_hash[item] = row[0]
            end
        end
        wss_global.vars[:replace_identifiers_hash]
    end
    
    def run(wss_global, worker_item)
        # Will be run for each item.
        if (communication = worker_item.source_item.communication).nil? or communication.from.nil? or communication.from.length == 0
            return # If the item has no from, it has no from to fix.
        end
        
        replace_identifiers_hash = wss_global.vars[:replace_identifiers_hash]
        
        # Create a communication object.
        com = SimpleCommunication.new(communication)
        # Replace identifiers in communication object.
        com = update_communication(replace_identifiers_hash, com)
        # Set the items communication object.
        worker_item.set_item_communication(com)
    end
    
    def run_close(wss_global)
        # Will be run after loading all items.
    end
end