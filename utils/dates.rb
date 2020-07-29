require 'date'
JodaTime = org.joda.time

module Dates
    extend self

    # Takes a date string that may be either Danish or English and translates it to English if it is Danish.
    def danish_date_string_to_english(date_string)
        if date_string[0,4].count('.') == 1 && date_string.count('.') == 1 # If there are more than this, the date probably uses . as a seperator.
            date_string.delete!('.') # For danish dates using the format 4. november.
        end
        # Most of these are unnecessary since ruby's Date class can figure it out by itself. However, oktober doesn't work so that must be done explicitly.
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
            date_string.gsub!(key, value)
        end
        return date_string
    end

    # Converts an offset in days to a Joda DateTimeZone.
    def offset_to_date_time_zone(offset)
        offset_hours = (offset*24).floor
        offset_minutes = (offset*24 - offset_hours)*60
        JodaTime::DateTimeZone.for_offset_hours_minutes(offset_hours, offset_minutes)
    end

    # Converts a Ruby DateTime to a JodaTime DateTime.
    def date_time_to_joda_time(date_time)
        date = date_time.to_date
        time_zone = offset_to_date_time_zone(date_time.offset)
		
        return JodaTime::DateTime.new(date.year, date.month, date.day, date_time.hour, date_time.minute, date_time.second, time_zone)
    end
end