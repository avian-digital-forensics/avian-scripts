module IngestFixedWidthAsCsv
  module_function

  def run_init(wss_global)
    # Will be run once before loading items.
    # Setup script here.
    require File.join(wss_global.root_path, 'utils', 'fixed_width_data')
  end

  def run(wss_global, worker_item)
    # Will be run for each item.
    # This is the main body of the script.

    line_format = [0, 24, 33, 45, 69, 71, 95, 118, 120, 143, 152, 161]
    csv_path = File.join('C:\Users\aga\Documents', worker_item.source_item.name.split('.')[0..-2].flatten + '.csv')
    if worker_item.source_item.name.end_with?('.netflow')
      item_text = worker_item.source_item.text.to_s
      FixedWidthData::fixed_width_to_csv_file(item_text, line_format, csv_path)
      worker_item.set_children([csv_path])
    end
    
  end

  def run_close(wss_global)
    # Will be run after loading all items.
  end
end
