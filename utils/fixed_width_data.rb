require 'java'
require 'csv'

module FixedWidthData
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

  def read_text_lines(text, line_format, &action)
    #reader = text.reader
    #buffered_reader = Java::Io::BufferedReader.new(reader)
    fixed_width_parser = FixedWidthData::LineParser.new(line_format)
    puts('torsk: Reading entire text into string...')
    text_string = text.to_s
    puts('sej: Processing lines...')
    for line in text_string.lines.drop(1)
      if line.start_with?('Summary:')
        break
      end
      action.call(fixed_width_parser.parse(line))
    end
  end

  # Takes a raw yml map of format information and converts it into data more directly usable by the other methods.
  # Format of input:
  #   :column_types: A comma seperated string of column types (date/id/sum).
  #   :column_headers: A comma seperated string of column headers.
  #   :line_format: A comma seperated string of start positions for each column in the fixed width file. Includes the index of the end of the line.
  #   :max_date_diff: The maximum second difference for two entries to be combined into one.
  # Params:
  # +format_info+:: A raw yml map of format information.
  def preprocess_format_info(format_info)
    format = {}
    column_types = format_info[:column_types]
    column_headers = format_info[:column_headers]
    line_format = format_info[:line_format].map { |column_pos| column_pos.to_i }
    max_date_diff_seconds = format_info[:max_date_diff]
    format[:column_headers] = column_headers
    format[:line_format] = line_format
    format[:date_index] = column_types.each_index.select { |index| column_types[index] == :date }.first
    format[:id_indices] = column_types.each_index.select { |index| column_types[index] == :id }
    format[:sum_indices] = column_types.each_index.select { |index| column_types[index] == :sum }
    input_indices = []
    for index in 0..column_types.size-1
      unless column_types[index] == :discard
        input_indices << index
      end
    end
    format[:input_indices] = input_indices
    format[:max_date_diff] = max_date_diff_seconds/(24*60*60)
    return format
  end

  # Takes fixed width data and transforms it into csv which is given to the CSV object.
  # Follows the given format_info (see preprocess_format_info).
  # Params:
  # +text+:: A stringable object holding the fixed width data.
  # +format_info+:: Information about the format of the fixed width data.
  # +csv+:: A ruby CSV object to receive each row array.
  def fixed_width_to_csv(text, format_info, csv)
    format = preprocess_format_info(format_info)
    column_headers = format[:column_headers]
    line_format = format[:line_format]
    date_index = format[:date_index]
    id_indices = format[:id_indices]
    sum_indices = format[:sum_indices]
    input_indices = format[:input_indices]
    max_date_diff = format[:max_date_diff]

    entry_history = []
    entry_history_hash = {}
    # Write column headers.
    csv << column_headers
    # Maps all lines in the file to arrays of values according to the line_format.
    FixedWidthData.read_text_lines(text, line_format) do |line|
      entry = Entry.new(line, date_index, id_indices, sum_indices)
      date = entry.date
      # Writes and removes all entries that are too far back now to be combined with.
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

  class LineParser
    def initialize(line_format)
      @line_format = line_format
    end

    def parse(line)
      cur_pos = 0
      @line_format.each_cons(2).map { |seg_start_pos, seg_end_pos| line[seg_start_pos..seg_end_pos - 1].strip }
    end
  end
end