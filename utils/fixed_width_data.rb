require 'java'
require 'csv'

module FixedWidthData
  extend self

  def read_text_lines(text, line_format, &action)
    reader = text.reader
    buffered_reader = Java::Io::BufferedReader.new(reader)
    unpack_string = 'A' + line_format.join('A')
    # Read first line.
    first_line = buffered_reader.read_line
    # Read other lines.
    if first_line
      while line = buffered_reader.read_line
        action.call(line.unpack(unpack_string))
      end
    end
  end

  def fixed_width_to_csv(text, line_format)
    fixed_width_parser = FixedWidthData::LineParser.new(line_format)
    CSV.generate do |csv|
      for line in text.lines
        csv << fixed_width_parser.parse(line)
      end
    end
  end

  def fixed_width_to_csv_file(text, line_format, path)
    fixed_width_parser = FixedWidthData::LineParser.new(line_format)
    CSV.open(path, "wb") do |csv|
      for line in text.lines
        csv << fixed_width_parser.parse(line)
      end
    end
    path
  end

  class LineParser

    def initialize(line_format)
      #cur_pos = 0
      #@line_format = line_format.map do |seg_length|
      #  prev_pos = cur_pos
      #  cur_pos += seg_length
      #  [prev_pos, seg_length]
      #end
      @line_format = line_format
    end

    def parse(line)
      #@line_format.map { |seg_info| line[seg_info[0], seg_info[1]] }
      cur_pos = 0
      @line_format.each_cons(2).map { |seg_start_pos, seg_end_pos| line[seg_start_pos..seg_end_pos - 1].strip }
    end
  end
end