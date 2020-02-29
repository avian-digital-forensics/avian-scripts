require 'set'

module Utils
    def self.alpha_num_char_set 
        [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
    end
    
    # Returns a string time stamp with the current time.
    def self.time_stamp()
        return Time.now.getutc.to_s[0...-4]
    end
    
    # Print to the log a message with a timestamp.
    def self.print_progress(message)
        puts(time_stamp + "  " + message)
    end
    
    # Creates a sample of size num_elements, from array.
    def self.sample(array, num_elements, with_replacement=false)
        if with_replacement
            return Array.new(num_elements) { rand(0..array.length-1) }.map { |index| array[index] }
        else
            return array.sample(num_elements)
        end
    end
    
    # Returns the number of nano seconds since epoch in the time as a single big integer.
    def self.time_to_nano(time)
        return time.tv_sec*(10**9)+time.tv_nsec
    end
    
    # Returns the current number of nano seconds since epoch as a single big integer.
    def self.nano_now
        return time_to_nano(Time.now)
    end
    
    # Returns a random string of length num_chars from the given char_set.
    def self.random_string(num_chars, char_set)
        return sample(char_set, num_chars, true).join
    end

    # Returns true if all the given sets are disjoint.
    def self.sets_disjoint?(*sets)
        total = Set[]
        for set in sets.map(&:to_set)
            unless set.disjoint?(total)
                return false
            end
            total = total | set
        end
    end
end