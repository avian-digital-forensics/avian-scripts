module EntitiesFromLists
    extend self
    
    def run_init(wss_global)
        # For EntityKeyLists
        require File.join(wss_global.root_path, 'utils', 'key_list') 
        manager = EntityKeyListManager.new()
        manager.load(wss_global.root_path, 'data', 'entity_key_lists.csv')
        wss_global.vars[:entities_from_lists_key_list_manager] = manager
    end
    
    def run(wss_global, worker_item)
        # Reads the relevant settings.
        settings = wss_global.wss_settings[:entities_from_lists]
        extract_from_text = settings[:extract_from_text]
        extract_from_properties = settings[:extract_from_properties]
        
        # Constructs the list of entity key lists that appear in the item.
        entity_key_lists = []
        if extract_from_text
            entities_from_lists += wss_global.vars[:entities_from_lists_key_list_manager].entities_in_item_text(worker_item)
        end
        if extract_from_properties
            entities_from_lists += wss_global.vars[:entities_from_lists_key_list_manager].entities_in_item_properties(worker_item)
        end
        
        # Add the found entities to the item.
        worker_item.add_named_entities(entity_key_lists.map{ |key_list| worker_item.create_entity(key_list.entity_type, key_list.entity_name)})
    end
    
    def run_close(wss_global)
        # Will be run after loading all items.
    end
end
