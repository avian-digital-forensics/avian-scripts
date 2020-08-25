module AddChildren
  extend self
  
  def run_init(wss_global)
    # Will be run once before loading items.
    # Setup script here.
    data_path = File.join(wss_global.case_data_path, 'add_children.yml')
    if File.file?(data_path)
      # Load data from file and save to wss_global.
      data = YAML.load_file(data_path)
      wss_global.vars[:add_children] = data
      wss_global.vars[:add_children_has_data] = true
    else
      wss_global.vars[:add_children_has_data] = false
      STDERR.puts("AddChildren: Could not find data file.")
    end

    require File.join(wss_global.root_path, 'utils', 'utils')
  end
  
  def run(wss_global, worker_item)
    # Will be run for each item.
    # This is the main body of the script.
    if wss_global.vars[:add_children_has_data]
      data = wss_global.vars[:add_children]
      child_binary_dir = File.join(wss_global.case_data_path, 'add_children_binaries')
      Utils::execute_add_children(child_binary_dir, data, worker_item)
    else
      STDERR.puts("AddChildren: No data file. Skipping.")
    end
  end
  
  def run_close(wss_global)
    # Will be run after loading all items.
  end
end
