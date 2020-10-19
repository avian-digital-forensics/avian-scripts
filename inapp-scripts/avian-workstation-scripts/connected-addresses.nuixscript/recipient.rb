module ConnectedAddresses
    # Represents a recipient address.
    # Contains information about the number of messages sent between the primary address and this address.
    class Recipient
        # Initializes the Recipient with an address and all counters set to 0.
        def initialize(address)
            @address = address
            keys = ["receive_tos", "receive_ccs", "receive_bccs", "send_tos", "send_ccs", "send_bccs"]
            @values = Hash[keys.collect{ |item| [item, 0] }]
        end
        
        # Increments the specified value.
        def increment_value(key)
            @values[key] += 1
        end
        
        # Returns the specified value.
        def get_value(key)
            @values[key]
        end
        
        # The total number of times this recipient has connected with primary.
        def total_with_prefix(prefix)
            keys = @values.keys.select{ |key| key.start_with?(prefix) }
            return keys.reduce(0){ |sum, key| sum + get_value(key) }
        end
        
        # Creates a string in human readable format with all information about this recipient.
        def to_s(delimiter)
            return @address + delimiter + 
                    @values["receive_tos"].to_s + delimiter + @values["receive_ccs"].to_s + delimiter + @values["receive_bccs"].to_s + delimiter + total_with_prefix("receive_").to_s + delimiter +
                    @values["send_tos"].to_s + delimiter + @values["send_ccs"].to_s + delimiter + @values["send_bccs"].to_s + delimiter + total_with_prefix("send_").to_s + delimiter +
                    total_with_prefix("").to_s
        end
    end
end