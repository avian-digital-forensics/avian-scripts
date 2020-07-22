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
  end
  
  def run(wss_global, worker_item)
    # Will be run for each item.
    # This is the main body of the script.
    if wss_global.vars[:add_children_has_data]
      data = wss_global.vars[:add_children]
      if data.key?(worker_item.item_guid)
        child_guids = data[worker_item.item_guid]

        child_binary_dir = File.join(wss_global.case_data_path, 'add_children_binaries')
        binaries = []
        for child_guid in child_guids
          binary_path = File.join(child_binary_dir, child_guid)
          if File.exist?(binary_path)
            binaries << binary_path
          else
            STDERR.puts("AddChildren: Missing binary for child: #{child_guid}.")
          end
        end
        worker_item.set_children(binaries)
      end
    else
      STDERR.puts("AddChildren: No data file. Skipping.")
    end
  end
  
  def run_close(wss_global)
    # Will be run after loading all items.
  end
end