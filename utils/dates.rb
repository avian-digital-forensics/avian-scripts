# If this package is used, ruby DateTime will be renamed RubyDateTime to free up the namespace for Joda DateTime.

require 'date'
RubyDateTime = DateTime
DateTime = nil
java_import 'org.joda.time.DateTime'
java_import 'org.joda.time.DateTimeZone'

module Dates
    def danish_date_string_to_english(date_string)
        if date_string.count('.') == 1 # If there are more than this, the date probably uses . as a seperator.
            date_string.delete!('.') # For danish dates using the format 4. november.
        end
        translations = {
            'januar' => 'January',
            'februar' => 'February',
            'marts' => 'March',
            'maj' => 'May',
            'juni' => 'June',
            'juli' => 'July',
            'oktober' => 'October'
        }
        for key,value in translations
            date_string.gsub!('key', 'value')
        end
        return date_string
    end

    # Converts an offset in days to a Joda DateTimeZone.
    def offset_to_date_time_zone(offset)
        offset_hours = (date_time.offset*24).floor
        offset_minutes = (date_time.offset*24 - offset_hours)*60
        DateTimeZone.for_offset_hours_minutes(offset_hours, offset_minutes)
    end

    def date_time_to_joda_time(date_time)
        date = date_time.to_date
        time_zone = offset_to_date_time_zone(date_time.offset)

        DateTime.new(date.year, date.month, date.day, date_time.hour, date_time.minute, date_time.second, time_zone)
    end

    # Converts a Joda DateTime to an array that can be saved in csv.
    def joda_time_to_csv_array(joda_time)
        year = joda_time.year
        month = joda_time.month_of_year
        day = joda_time.day_of_month
        hour = joda_time.hour_of_day
        minute = minute_of_hour
        second = second_of_minute
        millisecond_offset = joda_time.get_standard_offset(0)

        csv_array = [year, month, day, hour, minute, second, millisecond_offset]
        unless csv_array.size == joda_time_csv_array_length raise 'Sum ting wong' end
        return csv_array
    end

    # Creates a Joda DateTime from an array.
    def joda_time_from_csv_array(csv_array)
        unless csv_array.size == joda_time_csv_array_length raise ArgumentError 'The array must have exactly seven elements.' end
        year = csv_array[0].to_i
        month = csv_array[1].to_i
        day = csv_array[2].to_i
        hour = csv_array[3].to_i
        minute = csv_array[4].to_i
        second = csv_array[5].to_i
        offset = csv_array[6].to_i
        time_zone = DateTimeZone.for_offset_millis(offset)

        DateTime.new(year, month, day, hour, minute, second, time_zone)
    end

    def joda_time_csv_array_length
        7
    end
end