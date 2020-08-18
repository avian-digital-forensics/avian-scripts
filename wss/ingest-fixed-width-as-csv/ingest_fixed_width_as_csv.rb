require 'csv'
require 'date'
require 'fileutils'
module IngestFixedWidthAsCsv
  extend self

  class Entry
    attr_accessor :date, :id

    def initialize(elements, date_index, id_indices, sum_indices)
      @date = DateTime.parse(elements[date_index])
      @id = []
      for index in id_indices
        @id << elements[index]
      end
      @data = elements
      for index in sum_indices
        @data[index] = number_string_to_int(@data[index])
      end
    end

    def add(elements, sum_indices)
      for index in sum_indices
        @data[index] += elements[index]
      end
    end

    def to_csv(csv, input_indices)
      output_data = []
      for index in input_indices
        output_data << @data[index]
      end
      puts('klumpfisk: ' + output_data.to_s)
      csv << output_data
    end

    def number_string_to_int(number_string)
      if number_string[-1] == 'M'
        (number_string[0..-3].to_f*1000000).to_i
      elsif number_string[-1] == 'K'
        (number_string[0..-3].to_f*1000).to_i
      elsif number_string[-1] == 'G'
        (number_string[0..-3].to_f*1000000000).to_i
      else
        number_string.to_i
      end
    end
  end

  def run_init(wss_global)
    # Will be run once before loading items.
    # Setup script here.
    require File.join(wss_global.root_path, 'utils', 'fixed_width_data')
    require File.join(wss_global.root_path, 'utils', 'timer')

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
    if wss_global.vars[:ingest_fixed_width_as_csv_has_data] && wss_global.vars[:ingest_fixed_width_as_csv].key?(worker_item.item_guid)
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
    
  end

  def run_close(wss_global)
    # Will be run after loading all items.
  end
end
