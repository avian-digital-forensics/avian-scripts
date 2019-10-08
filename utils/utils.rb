module Utils
    def self.time_stamp()
        return Time.now.getutc.to_s[0...-4]
    end
    
    def self.print_progress(message)
        puts(time_stamp + "  " + message)
    end
end