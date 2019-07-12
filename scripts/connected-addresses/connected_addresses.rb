# Menu Title: Connected Addresses
# Needs Case: true

# The address whose recipients are wanted.
address = "Stabs Chef"

# The path to the directory in which to place the output.
output_destination_path = 'C:\Users\Albert\Documents'
# The name of the output file.
output_filename = 'test'
# The file extension of the output file.
output_file_extension = '.csv'

# What delimiter is used between values on the same line.
delimiter = ','

# Represents a recipient address.
# Contains information about the number of items sent from the main address 
# to this address as either to, cc or bcc
class Recipient
    # Initializes the Recipient with an address and all counters set to 0.
    def initialize(address)
        @address = address
        @tos = 0
        @ccs = 0
        @bccs = 0
    end
    
    # Adds 1 to the counter for the number of times this recipient has been a to.
    def add_to
        @tos += 1
    end
    
    # Adds 1 to the counter for the number of times this recipient has been a cc.
    def add_cc
        @ccs += 1
    end
    
    # Adds 1 to the counter for the number of times this recipient has been a bcc.
    def add_bcc
        @bccs += 1
    end
    
    # The number of times this recipient has been a to.
    def tos
        @tos
    end
    
    # The number of times this recipient has been a cc.
    def ccs
        @ccs
    end
    
    # The number of times this recipient has been the bcc.
    def bccs
        @bccs
    end
    
    # The total number of times this recipient has received items from the from.
    def total
        return @tos + @ccs + @bccs
    end
    
    # Creates a string in human readable format with all information about this recipient.
    def to_s(delimiter)
        return @address + delimiter + @tos.to_s + delimiter + @ccs.to_s + delimiter + @bccs.to_s + delimiter + total.to_s
    end
end

# Represents all addresses that have received items from the from.
class ToConnections
    
    # Initializes the ToConnections as empty.
    def initialize()
        @recipients = {}
    end
    
    # Adds 1 to the addresses to counter.
    def add_to(address)
        add_if_missing(address)
        @recipients[address].add_to
    end
    
    # Adds 1 to the addresses cc counter.
    def add_cc(address)
        add_if_missing(address)
        @recipients[address].add_cc
    end
    
    # Adds 1 to the addresses bcc counter.
    def add_bcc(address)
        add_if_missing(address)
        @recipients[address].add_bcc
    end
    
    # Handles a communication item by updating the correct recipients.
    def add_communication_item(item)
        communication = item.getCommunication()
        # Find all to, cc and bcc addresses.
        tos = communication.getTo().map{ |to| to.getAddress() }
        ccs = communication.getCc().map{ |cc| cc.getAddress() }
        bccs = communication.getBcc().map{ |bcc| bcc.getAddress() }
        # Update the recipients.
        for address in tos
            add_to(address)
        end
        for address in ccs
            add_cc(address)
        end
        for address in bccs
            add_bcc(address)
        end
        return
    end
    
    # Prints all contained recipients with newlines between them.
    def to_s(delimiter)
        @recipients.values.reduce(""){ |total, recipient| total + recipient.to_s(delimiter) + "\n" }
    end
    
    private
        # Adds a new recipient with the address if none exists.
        def add_if_missing(address)
            if !@recipients.key?(address)
                @recipients[address] = Recipient.new(address)
            end
        end
end

# All communication items with a from matching the given identifier.
emails_from = currentCase.search("from:\"" + address + "\" has-communication:1")

to_connections = ToConnections.new
# Handle all communication items.
for item in emails_from
    to_connections.add_communication_item(item)
end

# Find the whole file path.
file_path = File.join(output_destination_path, output_filename + output_file_extension)
file = File.open(file_path, 'w')
# Add header.
file.puts('address' + delimiter + 'to' + delimiter + 'cc' + delimiter + 'bcc' + delimiter + 'total')
# Add data.
file.puts(to_connections.to_s(delimiter))
# Close file.
file.close