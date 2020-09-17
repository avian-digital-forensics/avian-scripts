require 'csv'
require 'date'
require 'fileutils'
module IngestFixedWidthAsCsv
  extend self

  def run_init(wss_global)
    # Will be run once before loading items.
    # Setup script here.
    require File.join(wss_global.root_path, 'utils', 'fixed_width_data')
    require File.join(wss_global.root_path, 'utils', 'timer')
    require File.join(wss_global.root_path, 'utils', 'custom_communication')
    require File.join(wss_global.root_path, 'utils', 'dates')
    require File.join(wss_global.root_path, 'utils', 'utils')

    # Has the format { guid: format_info }.
    data_path = File.join(wss_global.case_data_path, 'ingest_fixed_width_as_csv_metadata.yml')
    
    if File.file?(data_path)
      # Load data from file and save to wss_global.
      data = YAML.load_file(data_path)
      wss_global.vars[:ingest_fixed_width_as_csv] = data
      wss_global.vars[:ingest_fixed_width_as_csv_has_data] = true
    else
      wss_global.vars[:ingest_fixed_width_as_csv_has_data] = false
      STDERR.puts("IngestFixedWidthAsCsv: Could not find data file. Skipping script")
    end

    if wss_global.vars[:ingest_fixed_width_as_csv_has_data]
      # The directory to write the resulting csv's from.
      csv_dir = File.join(wss_global.case_data_path, 'ingest_fixed_width_as_csv')
      # Ensure that csv_dir is empty.
      puts('Ensuring that the directory for the csv files is empty...')
      if Dir.exist?(csv_dir)
        FileUtils.rm_rf(csv_dir)
      end
      FileUtils.mkdir_p(csv_dir)

      wss_global.vars[:ingest_fixed_width_as_csv_csv_dir] = csv_dir
    end
  end

  def run(wss_global, worker_item)
    # Will be run for each item.
    # This is the main body of the script.
    if wss_global.vars[:ingest_fixed_width_as_csv_has_data]
      if wss_global.vars[:ingest_fixed_width_as_csv].key?(worker_item.item_guid)
        process_netflow(wss_global, worker_item)
      elsif worker_item.source_item.type.to_s == 'text/csv' && 
          wss_global.vars[:ingest_fixed_width_as_csv].key?(Utils::add_hyphens_to_guid(worker_item.guid_path[-2]))
        process_csv(wss_global, worker_item)
      elsif worker_item.source_item.type.to_s == 'application/x-database-table-row' && 
          wss_global.vars[:ingest_fixed_width_as_csv].key?(Utils::add_hyphens_to_guid(worker_item.guid_path[-3]))
        process_row(wss_global, worker_item)
      end        
    end
  end

  def run_close(wss_global)
    # Will be run after loading all items.
  end


  # The part of this WSS that handles the original netflow items.
  def process_netflow(wss_global, worker_item)
    # Get the format information from wss_global.
    data = wss_global.vars[:ingest_fixed_width_as_csv]
    csv_dir = wss_global.vars[:ingest_fixed_width_as_csv_csv_dir]
    format_info = data[worker_item.item_guid]

    # Find path on which to create the csv file.
    item_name = worker_item.source_item.name
    child_name = "#{item_name.split('.')[0..-2].join('.')}.csv"
    csv_path = File.join(csv_dir, child_name)

    # Get ready to write to a CSV file.
    CSV.open(csv_path, "wb") do |csv|
      FixedWidthData.fixed_width_to_csv(worker_item.source_item.text.to_s, format_info, csv)
    end
    # Add a child based on the newly created csv file.
    worker_item.set_children([csv_path])
  end

  # The part of this WSS that handles the CSV children given to the original netflow items.
  def process_csv(wss_global, worker_item)
    # Get the format information from wss_global.
    data = wss_global.vars[:ingest_fixed_width_as_csv]

    netflow_item_guid = Utils::add_hyphens_to_guid(worker_item.guid_path[-2])
    # The added csv file represents a conversation and the type should reflect this.
    worker_item.set_item_type('application/x-chat-conversation')
  end

  # The part of this WSS that handles the database row items of the created CSV items.
  def process_row(wss_global, worker_item)
    # Get the format information from wss_global.
    data = wss_global.vars[:ingest_fixed_width_as_csv]

    netflow_item_guid = Utils::add_hyphens_to_guid(worker_item.guid_path[-3])
    format_info = data[netflow_item_guid] 
    # Find communication information
    date_header = format_info[:date_header]
    date = worker_item.source_item.properties[date_header]
    joda_time = Dates::date_time_to_joda_time(DateTime.parse(date))
    from_header = format_info[:from_header]
    from = worker_item.source_item.properties[from_header]
    from_address = Custom::CustomAddress.new('', from)
    to_header = format_info[:to_header]
    to = worker_item.source_item.properties[to_header]
    to_address = Custom::CustomAddress.new('', to)

    # Create communication
    communication = Custom::CustomCommunication.new(joda_time, from + to, [from_address], [to_address], [], [])

    # Set communication
    worker_item.set_item_communication(communication)

    # Set type
    worker_item.set_item_type('application/x-chat-message')

    # Set date
    properties = worker_item.source_item.properties
    properties['Date'] = joda_time
    worker_item.set_item_properties(properties)

    # Set name
    worker_item.set_item_name(from + to)
  end
end
