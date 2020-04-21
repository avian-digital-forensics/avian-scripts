module LoadTimer
    extend self
    
    def run_init(wss_global)
        # Will be run once before loading items.
        require File.join(wss_global.root_path, 'utils', 'utils') 
        require File.join(wss_global.root_path, 'utils', 'timer') 
        wss_global.vars[:load_timer_start_time] = Utils::nano_now
        wss_global.vars[:load_timer_item_times] = {}
        wss_global.vars[:load_timer_last_item_guid] = nil
        wss_global.vars[:load_timer_last_item_time] = nil
    end
    
    def run(wss_global, worker_item)
        # Will be run for each item.
        current_time = Time.now
        current_time_nano = Utils::time_to_nano(current_time)
        wss_global.vars[:load_timer_item_times][worker_item.item_guid] = current_time_nano
        worker_item.add_custom_metadata('TimeOfLoad', current_time.to_s, 'text', 'user')
        seconds_since_load_start = (current_time_nano - wss_global.vars[:load_timer_start_time]).to_f/(10**9)
        worker_item.add_custom_metadata('TimeSinceLoadStart', seconds_since_load_start, 'float', 'user')
        if wss_global.vars[:load_timer_last_item_guid] # If this is not the first item.
            seconds_since_prev = (current_time_nano-wss_global.vars[:load_timer_last_item_time]).to_f/(10**9)
            worker_item.add_custom_metadata('LoadTimeSincePrev', seconds_since_prev, 'float', 'user')
            worker_item.add_custom_metadata('PrevLoadItemGUID', wss_global.vars[:load_timer_last_item_guid], 'text', 'user')
        else # If this is the first item.
            worker_item.add_custom_metadata('LoadTimeSincePrev', 'First item loaded so no time available', 'text', 'user')
            worker_item.add_custom_metadata('PrevLoadItemGUID', 'First item loaded so previous item available', 'text', 'user')
        end
        # All items should receive their worker's GUID.
        worker_item.add_custom_metadata('LoadWorkerGUID', worker_item.worker_guid, 'text', 'user')
        # Make ready for next item.
        wss_global.vars[:load_timer_last_item_guid] = worker_item.item_guid
        wss_global.vars[:load_timer_last_item_time] = current_time_nano
    end
    
    def run_close(wss_global)
        # Will be run after loading all items.
        wss_global.vars[:load_timer_end_time] = Utils::nano_now
        id_char_set = Utils::alpha_num_char_set
        id = Utils::random_string(8, id_char_set)
        data_path = File.join(wss_global.case_data_path, 'load_times_' + id + '.txt')
        File.open(data_path, 'w') { |file| 
            file.puts('start_time:' + wss_global.vars[:load_timer_start_time].to_s)
            file.puts('end_time:' + wss_global.vars[:load_timer_end_time].to_s)
            wss_global.vars[:load_timer_item_times].each do |guid, time|
                file.puts(guid + ':' + time.to_s)
            end
        }
    end
end
