module CustomEntityManager
    class CustomEntityManager
        def initialize()
            @items = {}
        end

        def add_entity(item, entity)
            if @items.include?(item.guid)
                @items[item.guid] += entity
            else
                @items[item.guid] = [entity]
            end
        end

        def num_items
            @items.size
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
    end
end