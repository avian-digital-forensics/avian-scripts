require 'java'
require 'json'
java_import 'nuix.Address'
java_import 'nuix.Communication'

module FixFromAddresses
    extend self
    
    class SimpleAddress
		include Address

		def initialize(address)
			@personal = address.getPersonal
			@address = address.getAddress
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

		def initialize(communication)
			@dateTime = communication.getDateTime
			@fromAddresses = communication.getFrom
			@toAddresses = communication.getTo
			@ccAddresses = communication.getCc
			@bccAddresses = communication.getBcc
		end

		def getDateTime
			@dateTime
		end
		def getFrom
			@fromAddresses
		end
		def setFrom(fromAddresses)
			@fromAddresses = fromAddresses
		end
		def getTo
			@toAddresses
		end
		def getCc
			@ccAddresses
		end
		def getBcc
			@bccAddresses
		end
	end
    
    # Represents a set of equivalent identifiers.
    class Person
        def initialize
            @identifiers = Set[]
            @email_addresses = Set[]
        end
        
        def add_identifier(identifier)
            raise ArgumentError, 'Identifier may not be nil.' unless not identifier.nil?
            if @identifiers.add?(identifier) and email_address?(identifier)
                @email_addresses.add(identifier)
            end
        end
        
        def identifiers
            @identifiers
        end
        
        def email_addresses
            @email_addresses
        end
        
        def to_s
            return "{" + @email_addresses.to_a.to_s + ":" + @identifiers.select{ |identifier| not @email_addresses.include?(identifier) }.to_s + "}"
        end
        
        private
            # Returns true if the identifier is an email address.
            # Very fuzzy.
            def email_address?(identifier)
                illegal_chars = ['"','(',')',':',';','<','>','[','\\',']']
                for char in illegal_chars
                    if identifier.include?(char)
                        return false
                    end
                end
                return identifier.count('@') == 1
            end
    end
    
    class PersonManager
        def initialize
            @persons = Set[]
            @identifier_map = {}
        end
        
        def add_person(person)
            @persons.add(person)
            for identifier in person.identifiers
                @identifier_map[identifier] = person
            end
        end
        
        def person(identifier)
            return @identifier_map[identifier]
        end
        
        def to_s
            @identifier_map.reduce(""){ |result,(key,val)| result + key + ": " + val.to_s + "\n" }
        end
    end

    def run_init(wss_global)
        root_path = wss_global.root_path
        require File.join(root_path, 'utils', 'union_find')
        data_path = File.join(root_path, 'data', 'find_correct_addresses_output.txt')
        if not File.file?(data_path)
            STDERR.puts("Could not find data file. Did you remember to run 'Find Correct Addresses'?")
        end
        data = File.read(data_path)
        union = UnionFind.new([])
        union.load(data)
        
        # Create persons from the components in the union find.
        persons = {}
        for identifier in union.elements
            representative = union.representative(identifier)
            if not persons.has_key?(representative)
                persons[representative] = Person.new
            end
            persons[representative].add_identifier(identifier)
        end
        
        person_manager = PersonManager.new
        for person in persons.values
            person_manager.add_person(person)
        end
        
        
        wss_global.vars[:fix_from_addreses_person_manager] = person_manager
    end
    
    def run(wss_global, worker_item)
        person_manager = wss_global.vars[:fix_from_addreses_person_manager]
        
		if (communication = worker_item.source_item.communication).nil? or communication.from.nil? or communication.from.length == 0
			return # If the item has no from, it has no from to fix.
		end
        
        from_address_metadata_name = "CorrectFromAddress" # The name of the custom metadata element used for the corrected from emai address.
		original_from_address_metadata_name = "OriginalFromAddress" # The name of the custom metadata element used for the original exchange server address.
        found_email_address_metadata_name = "FoundEmailAddress" # The name of the custom metadata element saying whether the found address is an email address.
        
        original_from_address = communication.from[0].address
        
        person = person_manager.person(original_from_address)
        
        raise StandardError, 'No person with identifier ' + original_from_address + ' exists. Please try running the in-app script again' unless person
        
        if person.email_addresses.length > 0
            correct_from_address = person.email_addresses.to_a[0]
            found_email_address = true
        else 
            correct_from_address = person.identifiers.to_a[0]
            found_email_address = false
        end
        
        worker_item.add_custom_metadata(from_address_metadata_name, correct_from_address, "text", "user")
        worker_item.add_custom_metadata(original_from_address_metadata_name, original_from_address, "text", "user")
        worker_item.add_custom_metadata(found_email_address_metadata_name, found_email_address.to_s, "text", "user")
        
        com = SimpleCommunication.new(communication)
		from_address = SimpleAddress.new(com.getFrom[0])
		from_address.setAddress(correct_from_address)
		com.setFrom([from_address])
		
		worker_item.set_item_communication(com)
    end
end
