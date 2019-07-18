require 'set'

# Implements the union find data structure.
class UnionFind
    def initialize(elements)
        @elements = Set[]
        @parent = {}
        @tree_size = {}
        @num_components = 0
        for element in elements
            add_element(element)
        end
    end
    
    def elements
        @elements
    end
    
    def add_element(element)
        raise ArgumentError, 'Element may not be nil.' unless not element.nil?
        if @elements.add?(element)
            @parent[element] = element
            @tree_size[element] = 1
            @num_components += 1
        end
        return element
    end
    
    def add_elements(elements)
        for element in elements
            add_element(element)
        end
    end
    
    def num_elements
        @elements.length
    end
    
    def num_components
        @num_components
    end
    
    def representative(element)
        raise IndexError, 'Element does not exist.' unless @elements.include?(element)
        if @parent[element] == element
            return element
        end
        @parent[element] = representative(@parent[element])
        return @parent[element]
    end
    
    def connected?(element1, element2)
        raise IndexError, 'Element1 does not exist.' unless @elements.include?(element1)
        raise IndexError, 'Element2 does not exist.' unless @elements.include?(element2)
        representative(element1) == representative(element2)
    end
    
    def union(element1, element2)
        raise IndexError, 'Element1 does not exist.' unless @elements.include?(element1)
        raise IndexError, 'Element2 does not exist.' unless @elements.include?(element2)
        rep1 = representative(element1)
        rep2 = representative(element2)
        
        if rep1 == rep2
            return nil
        end
        
        @num_components -= 1
        
        if @tree_size[rep1] >= @tree_size[rep2]
            @tree_size[rep1] += @tree_size[rep2]
            @parent[rep2] = rep1
            return rep1
        else
            @tree_size[rep2] += @tree_size[rep1]
            @parent[rep1] = rep2
            return rep2
        end
    end
end
        
# Returns a list of all the addresses in the communication of the item if such exists.
def all_addresses_in_item(item)
    communication = item.communication
    result = Set[]
    if communication
        if communication.from
            result.merge(communication.from)
        end
        if communication.to
            result.merge(communication.to)
        end
        if communication.cc
            result.merge(communication.cc)
        end
        if communication.bcc
            result.merge(communication.bcc)
        end
    end
    return result
end

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
end


puts("Running script...")

# Find all items with a communication.
messages = currentCase.search("has-communication:1")

puts("Found: " + messages.length.to_s + " items with communication.")

begin_time = Time.now
# Initialize the union find.
identifiers = UnionFind.new([])
end_time = Time.now

puts("helleflynder1: #{(end_time-begin_time)*1000}")
begin_time = Time.now
# Add all addresses to the union find.
for message in messages
    for address in all_addresses_in_item(message)
        if address.personal
            identifiers.add_element(address.personal)
        end
        if address.address
            identifiers.add_element(address.address)
        end
        if address.personal and address.address # Only union the two identifiers if they both exist.
            identifiers.union(address.personal, address.address)
        end
    end
end
end_time = Time.now
puts("helleflynder2: #{(end_time-begin_time)*1000}")

begin_time = Time.now
# Create persons from the components in the union find.
persons = {}
for identifier in identifiers.elements
    representative = identifiers.representative(identifier)
    if not persons.has_key?(representative)
        persons[representative] = Person.new
    end
    persons[representative].add_identifier(identifier)
end
end_time = Time.now

puts("helleflynder3: #{(end_time-begin_time)*1000}")

begin_time = Time.now
# Use 
for message in messages
    if message.communication.from and !message.communication.from.empty?
        from = message.communication.from[0]
        person = persons[identifiers.representative(from.address)]
        email_address = if person.email_addresses.length > 0 then person.email_addresses.to_a[0] else "" end
        message.custom_metadata["CorrectEmailAddress"] = email_address
    end
end
end_time = Time.now

puts("helleflynder4: #{(end_time-begin_time)*1000}")

puts("Unique identities found: " + persons.length.to_s)
for person in persons.values
    #puts(person.identifiers.to_a.to_s + ": " + person.email_addresses.to_a.to_s)
end

puts("Script finished.")