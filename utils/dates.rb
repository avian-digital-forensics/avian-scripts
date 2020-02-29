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
end