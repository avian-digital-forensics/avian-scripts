module FixUnidentifiedEmails
    # Return a hash of possible fields and there values.
    def find_fields(text, possible_fields, timer)
        lines = text.lines
        
        fields = {}

        for field_key in possible_fields do
            fields[field_key] = lines.select { |line| line.starts_with?(field_key) }.map { |line| line[field_key.size..-1].strip }
        end
        return fields
    end
end