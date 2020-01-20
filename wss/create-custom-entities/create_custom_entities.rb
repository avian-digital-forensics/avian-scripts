module CreateCustomEntities
    extend self
    
    def run_init(wss_global)
        # Will be run once before loading items.
        require File.join(wss_global.root_path, 'utils', 'timer') 
        require File.join(wss_global.root_path, 'utils', 'utils') 
        require File.join(wss_global.root_path, 'utils', 'custom_entity_manager') 
        timer = Timing::Timer.new
        timer.start('load_data')
        Utils.print_progress('Loading custom entity data...')
        data_path = File.join(wss_global.case_data_path, 'store_custom_entities_store.csv')
        if File.file?(data_path)
            entities = CustomEntityManager::CustomEntityManager.new
            CSV.foreach(data_path, "r") do |row|
                entities.load_csv_row(row)
            end
            wss_global.vars[:create_custom_entities_entities] = entities
            wss_global.vars[:create_custom_entities_has_data] = true
        else
            wss_global.vars[:create_custom_entities_has_data] = false
            STDERR.puts('Could not find data file. Did you remember to run "Store Custom Entities"?')
        end
        Utils.print_progress('Finished loading custom entity data.')
        timer.stop('load_data')
        wss_global.vars[:create_custom_entities_timer] = timer
    end
    
    def run(wss_global, worker_item)
        # Will be run for each item.
        timer = wss_global.vars[:create_custom_entities_timer]
        timer.start('run_total')
        if wss_global.vars[:create_custom_entities_has_data]
            entity_manager = wss_global.vars[:create_custom_entities_entities]
            item_entities = entity_manager.entities_for_item(worker_item.item_guid)
            timer.start('create_entity_list')
            item_entity_objects = []
            for entity in item_entities
                timer.start('create_entities')
                entity_object = worker_item.create_entity(entity.entity_type, entity.entity_name)
                timer.stop('create_entities')
                for i in 1..entity.amount
                    item_entity_objects << entity_object
                end
            end
            timer.stop('create_entity_list')

            # Add the entities to the item.
            timer.start('add_entities')
            puts('Size of item_entity_objects: ' + item_entity_objects.size.to_s)
            worker_item.add_named_entities(item_entity_objects)
            timer.stop('add_entities')
        else
            STDERR.puts('No data file; cannot add custom entities.')
        end
        timer.stop('run_total')
    end
    
    def run_close(wss_global)
        # Will be run after loading all items.
        puts('create_custom_entities timings:')
        wss_global.vars[:create_custom_entities_timer].print_timings
    end
end