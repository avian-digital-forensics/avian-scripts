require File.join(File.dirname(__FILE__), 'custom_entity')

module CustomEntityManager
    # Stores information about which items have which Entities.
    class CustomEntityManager
        def initialize()
            @items = {}
        end

        # Adds an entity to the specified item.
        def add_entity(guid, entity)
            if @items.include?(guid)
                @items[guid] << entity
            else
                @items[guid] = [entity]
            end
        end

        # The number of items that have entities.
        def num_items
            @items.size
        end

        # Returns a list of all custom entities in the item with the given guid.
        # Returns an empty list if there is no entry for the guid.
        def entities_for_item(guid)
            if @items.key?(guid)
                @items[guid]
            else
                []
            end
        end
            
        # Writes the custom entity manager to the specified CSV object to be loaded at a later point.
        # Meant to be used in conjunction with CSV methods like CSV.open("path/to/file.csv", "wb") do |csv|
        def to_csv(csv)
            @items.each do |guid, entities|
                for entity in entities
                    csv << [guid, entity.entity_type, entity.entity_name, entity.amount]
                end
            end
        end
        
        # Loads a single row of CSV data into the entity manager.
        # Meant to be used in conjunction with CSV methods like CSV.foreach("path/to/file.csv", "r") do |row|
        def load_csv_row(csv_row)
            begin
                amount = csv_row[3].to_i
                unless amount >= 0
                    STDERR.puts('Amount must be a non-negative integer. Amount: ' + amount)
                    raise StandardError('Amount must be a non-negative integer. Amount: ' + amount)
                end
                add_entity(csv_row[0], CustomEntity::CustomEntity.new(csv_row[1], csv_row[2], amount))
            rescue ArgumentError # If the 'amount' value is not an integer.
                STDERR.puts('The "amount" value must be an integer.')
                raise ArgumentError
            end
        end
    end
end