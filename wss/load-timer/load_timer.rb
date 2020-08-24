module LoadTimer
  extend self
  
  def run_init(wss_global)
    # Will be run once before loading items.
    require File.join(wss_global.root_path, 'utils', 'utils') 
    require File.join(wss_global.root_path, 'utils', 'timer') 
    require 'csv'
    wss_global.vars[:load_timer_start_time] = Utils::nano_now
    wss_global.vars[:load_timer_item_times] = {}
    wss_global.vars[:load_timer_last_item_guid] = nil
    wss_global.vars[:load_timer_last_item_time] = nil

    # Setup the output file.
    id_char_set = Utils::alpha_num_char_set
    id = Utils::random_string(8, id_char_set)
    wss_global.vars[:load_timer_file_path] = File.join(wss_global.case_data_path, 'load_times_' + id + '.csv')
    # Write headers.
    CSV.open(wss_global.vars[:load_timer_file_path], 'a') do |csv|
      csv << ['guid','load_time_since_prev','mime_type','parent_guid','file_size','path','time_stamp']
    end
  end
  
  def run(wss_global, worker_item)
    # Will be run for each item.
    # The output file.

    current_time = Time.now
    current_time_nano = Utils::time_to_nano(current_time)
    
    wss_global.vars[:load_timer_item_times][worker_item.item_guid] = current_time_nano
    worker_item.add_custom_metadata('TimeOfLoad', current_time.to_s, 'text', 'user')
    seconds_since_load_start = (current_time_nano - wss_global.vars[:load_timer_start_time]).to_f/(10**9)
    worker_item.add_custom_metadata('TimeSinceLoadStart', seconds_since_load_start, 'float', 'user')
    seconds_since_prev = nil
    prev_guid = nil
    if wss_global.vars[:load_timer_last_item_guid] # If this is not the first item.
      seconds_since_prev = (current_time_nano-wss_global.vars[:load_timer_last_item_time]).to_f/(10**9)
      prev_guid = wss_global.vars[:load_timer_last_item_guid]
      worker_item.add_custom_metadata('LoadTimeSincePrev', seconds_since_prev, 'float', 'user')
      worker_item.add_custom_metadata('PrevLoadItemGUID', prev_guid, 'text', 'user')
    else # If this is the first item.
      worker_item.add_custom_metadata('LoadTimeSincePrev', 'First item loaded so no time available', 'text', 'user')
      worker_item.add_custom_metadata('PrevLoadItemGUID', 'First item loaded so no previous item is available', 'text', 'user')
    end
    # All items should receive their worker's GUID.
    worker_item.add_custom_metadata('LoadWorkerGUID', worker_item.worker_guid, 'text', 'user')
    # Make ready for next item.
    wss_global.vars[:load_timer_last_item_guid] = worker_item.item_guid
    wss_global.vars[:load_timer_last_item_time] = current_time_nano

    # Write item data to file.
    guid = worker_item.item_guid
    mime_type = worker_item.source_item.type
    parent_guid = worker_item.guid_path[-2]
    file_size = worker_item.source_item.file_size
    path = worker_item.source_item.path
    time_stamp = current_time
    CSV.open(wss_global.vars[:load_timer_file_path], 'a') do |csv|
      csv << [guid, seconds_since_prev || 'NIL', mime_type, parent_guid || 'NIL', file_size || 'NIL', worker_item, path, time_stamp]
    end
  end
  
  def run_close(wss_global)
    CSV.open(wss_global.vars[:load_timer_file_path], 'a') do |csv|
      csv << []
    end
  end
end
