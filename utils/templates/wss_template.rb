module WSSTemplate
  extend self
  
  def run_init(wss_global)
    # Will be run once before loading items.
    # Setup script here.
  end
  
  def run(wss_global, worker_item)
    # Will be run for each item.
    # This is the main body of the script.
  end
  
  def run_close(wss_global)
    # Will be run after loading all items.
  end
end