java_import "java.util.regex.Pattern"
# For saving and loading key lists.
require 'csv'

# Holds a collection of EntityKeyLists.
class EntityKeyListManager
    # Initializes an empty EntityKeyListManager.
    def initialize
        @entity_key_lists = {}
    end
    
    # Add an EntityKeyList.
    # The entity_name must be unique.
    def add(entity_key_list)
        raise ArgumentError, 'Already contains entity key list with same name.' unless not @entity_key_lists.key?(entity_key_list.entity_name)
        @entity_key_lists[entity_key_list.entity_name] = entity_key_list
    end
    
    # Add an EntityKeyList.
    # The entity_name must be unique.
    # Alias of add(entity_key_list).
    def add_entity_key_list(entity_key_list)
        add(entity_key_list)
    end
    
    # Finds the entity key list with the given name.
    def [](entity_name)
        return @entity_key_lists[entity_name]
    end
    
    # Returns hash of names to key list patterns that can be given to the worker item's scan_item methods.
    def regex_hash
        return Hash[ @entity_key_lists.values.collect { |key_list| [key_list.entity_name, key_list.pattern] }]
    end
    
    # Returns a list of all entity key lists present in the item text.
    # The key list occurs once in the list for each time it occurs in the item text.
    def entities_in_item_text(worker_item)
        # Uses Nuix's entity scanning to find occurrences of the keys, and uses the result to determine how many of each entity the item has.
        return worker_item.scan_item_text(regex_hash).map{ |entity| @entity_key_lists[entity.type] }
    end 
    
    # Returns a list of all entity key lists present in the item properties.
    # The key list occurs once in the list for each time it occurs in the item properties.
    def entities_in_item_properties(worker_item)
        # Uses Nuix's entity scanning to find occurrences of the keys, and uses the result to determine how many of each entity the item has.
        return worker_item.scan_item_properties(regex_hash).map{ |entity| @entity_key_lists[entity.type] }
    end
    
    # Saves to a csv file.
    def save_to_file(path)
        CSV.open(path, "wb") do |csv|
            for ekl in @entity_key_lists.values
                csv << ekl.to_string_array
            end
        end
    end
    
    # Adds all EntityKeyLists in the file to the EntityKeyListManager.
    def load(path)
        CSV.foreach(path) do |row|
            add_entity_key_list(EntityKeyList.load(row))
        end
    end
end

# Represents an entity with a type and a name/value, and a key list containing the aliases of the entity.
class EntityKeyList
    attr_accessor :entity_type, :entity_name, :key_list, :pattern

    def initialize(entity_type, entity_name, key_list)
        @entity_type = entity_type
        @entity_name = entity_name
        @key_list = key_list
        @pattern = Pattern.compile(key_list.join("|"))
    end
    
    # Creates a string array representing the key list that can be saved to csv.
    def to_string_array
        # Turns the EntityKeyList into an array for more compact storing.
        array = [entity_type, entity_name] + key_list
        return array
    end
    
    # Loads an EntityKeyList from a csv row.
    def self.load(csv_row)
        return EntityKeyList.new(csv_row[0], csv_row[1], csv_row[2..-1])
    end
end
    