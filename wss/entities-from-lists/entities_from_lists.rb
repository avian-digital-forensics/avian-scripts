module EntitiesFromLists
    extend self
    
    def run_init(wss_global)
        # For EntityKeyLists
        require File.join(wss_global.root_path, 'utils', 'key_list') 
        manager = EntityKeyListManager.new()
        key_lists_path = File.join(wss_global.root_path, 'data', 'entity_key_lists.csv')
        unless File.exist?(key_lists_path)
            raise "No key list file. Cannot run script"
        end
        manager.load(key_lists_path)
        wss_global.vars[:entities_from_lists_key_list_manager] = manager
    end
    
    def run(wss_global, worker_item)
        # Reads the relevant settings.
        settings = wss_global.wss_settings[:entities_from_lists]
        extract_from_text = settings[:extract_from_text]
        extract_from_properties = settings[:extract_from_properties]
        
        manager = wss_global.vars[:entities_from_lists_key_list_manager]
        
        text = worker_item.source_item.text.to_s
        
        # Constructs the list of entity key lists that appear in the item.
        entities = manager.entities_in_text(text)
        
        for ekl,occurences in entities
            for i in 1..occurences
                worker_item.add_named_entity(worker_item.create_entity(ekl.entity_type, ekl.entity_name))
            end
        end
    end
    
    def run_close(wss_global)
        # Will be run after loading all items.
    end
end
