module LoadTimer
    extend self
    
    def run_init(wss_global)
        # Will be run once before loading items.
        require File.join(wss_global.root_path, 'utils', 'utils') 
        wss_global.vars[:load_timer_start_time] = Utils::nano_now
        wss_global.vars[:load_timer_item_times] = {}
    end
    
    def run(wss_global, worker_item)
        # Will be run for each item.
        wss_global.vars[:load_timer_item_times][worker_item.item_guid] = Utils::nano_now
    end
    
    def run_close(wss_global)
        # Will be run after loading all items.
        id_char_set = Utils::alpha_num_char_set
        id = Utils::random_string(8, id_char_set)
        data_path = File.join(wss_global.case_data_path, 'load_times' + id + '.txt')
        NOT DONE!!!
    end
end