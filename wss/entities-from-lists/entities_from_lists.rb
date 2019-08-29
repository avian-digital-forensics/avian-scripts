module EntitiesFromLists
    extend self
    
    def run_init(wss_global)
        require File.join(wss_global.root_path, 'utils', 'union_find')
        wss_global.vars[:entities_from_lists_key_list] = EntityKeyList("Test", "Jeg", ["Jeg", "jeg", "Mig", "mig", "Vi", "vi"])
    end
    
    def run(wss_global, worker_item)
        entities = worker_item.scan_item_text({"Jeg" => wss_global.vars[:entities_from_lists_key_list].pattern})
        puts(entities)
    end
    
    def run_close(wss_global)
        # Will be run after loading all items.
    end
end