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

    def self.date_time_to_joda_time(date_time)
        date = date_time.to_date
        offset_hours = (date_time.offset*24).floor
        puts('torsk: ' + offset_hours.to_s)
        offset_minutes = (date_time.offset.to_f*24 - offset_hours)*60
        puts('sej: ' + offset_minutes.to_s)
        offset = DateTimeZone.for_offset_hours_minutes(offset_hours, offset_minutes)

        DateTime.new(date.year, date.month, date.day, date_time.hour, date_time.minute, date_time.second, offset)
    end
end