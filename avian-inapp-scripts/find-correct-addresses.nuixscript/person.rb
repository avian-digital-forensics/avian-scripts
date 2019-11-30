module FindCorrectAddresses
    # Represents a set of equivalent identifiers.
    class Person
        attr_reader :flagged

        def initialize
            @identifiers = Set[]
            @email_addresses = Set[]
			@flagged = false
        end
        
        def add_identifier(identifier)
            raise ArgumentError, 'Identifier may not be nil.' if identifier.nil?
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

        def flag
            @flagged = true
        end

        def unflag
            @flagged = false
        end
        
        def to_s
            return "{" + @email_addresses.to_a.to_s + ":" + @identifiers.select{ |identifier| not @email_addresses.include?(identifier) }.to_s + "}"
        end

        def to_csv_array
            return @email_addresses.to_a + @identifiers.select{ |identifier| not @email_addresses.include?(identifier) } + (@flagged ? ['flagged'] : [])
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
        include Enumerable
        def initialize
            @persons = Set[]
            @identifier_map = {}
        end

        def self.from_union_find(union_find)
            person_manager = PersonManager.new
            union_find.to_component_hash.each do |representative, identifiers|
                person = Person.new
                person.add_identifier(representative)
                for identifier in identifiers
                    person.add_identifier(identifier)
                end
                person_manager.add_person(person)
                yield
            end
            return person_manager
        end

        def num_persons
            @persons.size
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

        def to_csv(csv)
            for person in @persons
                csv << person.to_csv_array
                yield
            end
        end

        def each &block
            @persons.each{ |person| block.call(person) }
        end
    end
end