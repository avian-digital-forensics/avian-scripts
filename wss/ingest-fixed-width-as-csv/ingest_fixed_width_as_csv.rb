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

    column_types = [:date, :id, :id, :id, :discard, :id, :id, :discard, :id, :sum, :sum]
    column_headers = ['Date first seen', 'Event', 'XEvent Proto', 'Src IP Addr:Port', 'Dst IP Addr:Port', 'X-Src IP Addr:Port', 'X-Dst IP Addr:Port', 'In Byte', 'Out Byte']
    line_format = [0, 24, 33, 45, 69, 71, 95, 118, 120, 143, 152, 161]
    csv_dir = File.join(wss_global.case_data_path, 'ingest_fixed_width_as_csv')
    # Ensure that csv_dir is empty.
    puts('Ensuring that the directory for the csv files is empty.')
    if Dir.exist?(csv_dir)
      FileUtils.rm_rf(csv_dir)
    end
    FileUtils.mkdir_p(csv_dir)

    wss_global.vars[:csv_dir] = csv_dir
    wss_global.vars[:column_headers] = column_headers
    wss_global.vars[:line_format] = line_format
    wss_global.vars[:date_index] = column_types.each_index.select { |index| column_types[index] == :date }.first
    puts("helleflynder Date index: #{wss_global.vars[:date_index]}")
    wss_global.vars[:id_indices] = column_types.each_index.select { |index| column_types[index] == :id }
    puts("helleflynder ID indices: #{wss_global.vars[:id_indices]}")
    wss_global.vars[:sum_indices] = column_types.each_index.select { |index| column_types[index] == :sum }
    puts("helleflynder Sum indices: #{wss_global.vars[:sum_indices]}")
    input_indices = []
    for index in 0..column_types.size-1
      unless column_types[index] == :discard
        input_indices << index
      end
    end
    wss_global.vars[:input_indices] = input_indices
    puts("helleflynder Input indices: #{input_indices}")
    wss_global.vars[:max_date_diff] = 1r/(24*60)
  end

  def run(wss_global, worker_item)
    # Will be run for each item.
    # This is the main body of the script.
    if worker_item.source_item.name.end_with?('.netflow')
      # Get the format information from wss_global.
      csv_dir = wss_global.vars[:csv_dir]
      column_headers = wss_global.vars[:column_headers]
      line_format = wss_global.vars[:line_format]
      date_index = wss_global.vars[:date_index]
      id_indices = wss_global.vars[:id_indices]
      sum_indices = wss_global.vars[:sum_indices]
      input_indices = wss_global.vars[:input_indices]
      max_date_diff = wss_global.vars[:max_date_diff]

      # Find path on which to create the csv file.
      item_name = worker_item.source_item.name
      child_name = "#{item_name.split('.')[0..-2].join('.')}.csv"
      csv_path = File.join(csv_dir, child_name)
      puts('gedde: ' + csv_path)

      entry_history = []
      entry_history_hash = {}

      item_text = worker_item.source_item.text
      # Get ready to write to a CSV file.
      CSV.open(csv_path, "wb") do |csv|
        # Write column headers.
        csv << column_headers
        # Maps all lines in the file to arrays of values according to the line_format.
        FixedWidthData.read_text_lines(item_text, line_format) do |line|
          entry = Entry.new(line, date_index, id_indices, sum_indices)
          date = entry.date
          # Writes and removes all entries that are too far back now to be combined with.
          if entry_history.first
            puts('aborre: ' + (date - entry_history.first.date).to_s)
          end
          while entry_history.first && date - entry_history.first.date > max_date_diff
            first = entry_history.shift
            first.to_csv(csv, input_indices)
            entry_history_hash.delete(first.id)
          end
          # Checks if there is a previous entry the new entry should be combined into.
          combiner = entry_history_hash[entry.id]
          if combiner
            combiner.add(line, sum_indices)
          else
            entry_history << entry
            entry_history_hash[entry.id] = entry
          end
        end
        for entry in entry_history
          entry.to_csv(csv, input_indices)
        end
      end
      # Add a child based on the newly created csv file.
      puts('skrubbe: ')
      worker_item.set_children([csv_path])
    end
    
  end

  def run_close(wss_global)
    # Will be run after loading all items.
  end
end
