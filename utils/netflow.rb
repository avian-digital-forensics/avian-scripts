require 'date'

module Netflow
  extend self

  def generate_ip()
    [*1..4].map { |x| rand(0..999).to_s }.join('.') + ':' + rand(0..65535).to_s
  end

  def generate_poisson(lambda)
    -Math.log(1.0 - Random.rand) / lambda
  end

  def generate_size()
    magnitude = ['', 'K', 'M', 'G'].sample(1)[0]
    "#{rand(0..999).to_f/10} #{magnitude}"
  end

  def generate_netflow(file, num_lines, lambda = 1.0/60)
    current_date_time = DateTime.now
    seconds_in_day = 60*60*24
    headers = ['Date first seen','Event','XEvent Proto','Src IP Addr:Port','','Dst IP Addr:Port','X-Src IP Addr:Port','','X-Dst IP Addr:Port','In Byte','Out Byte']
    line_format = [23, 9, 13, 24, 2, 23, 24, 2, 23, 9, 9]
    File.open(file, 'w') do |file|
      file.puts(headers.zip(line_format).map { |header, column_width| header.ljust(column_width)}.join(''))
      for _ in 1..num_lines do
        current_date_time += generate_poisson(lambda).to_f/seconds_in_day
        fields = [current_date_time.strftime("%Y-%m-%d %H:%M:%S.%L"),
            'INVALID',
            'Ignore TCP',
            generate_ip,
            '->',
            generate_ip,
            generate_ip,
            '->',
            generate_ip,
            generate_size,
            generate_size
        ]
        padded_fields = fields.zip(line_format).map { |field, column_width| field.ljust(column_width)}
        file.puts(padded_fields.join(''))
      end
    end

  end
end