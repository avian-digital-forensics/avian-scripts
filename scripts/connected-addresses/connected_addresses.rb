# Menu Title: Connected Addresses
# Needs Case: true
require 'set'


address = "Stabs Chef"

output_destination_path = 'C:\Users\Albert\Documents'
output_filename = 'test'
output_file_extension = '.csv'

delimiter = ','

class Recipient
    
    def initialize(address)
        @address = address
        @tos = 0
        @ccs = 0
        @bccs = 0
    end
    
    def add_to
        @tos += 1
    end
    
    def add_cc
        @ccs += 1
    end
    
    def add_bcc
        @bccs += 1
    end
    
    def tos
        @tos
    end
    
    def ccs
        @ccs
    end
    
    def bccs
        @bccs
    end
    
    def total
        return @tos + @ccs + @bccs
    end
    
    def to_s(delimiter)
        return @address + delimiter + @tos.to_s + delimiter + @ccs.to_s + delimiter + @bccs.to_s + delimiter + total.to_s
    end
end

class ToConnections
    
    def initialize()
        @recipients = {}
    end
    
    def add_to(address)
        add_if_missing(address)
        @recipients[address].add_to
    end
    
    def add_cc(address)
        add_if_missing(address)
        @recipients[address].add_cc
    end
    
    def add_bcc(address)
        add_if_missing(address)
        @recipients[address].add_bcc
    end
    
    def add_communication_item(item)
        communication = item.getCommunication()
        tos = communication.getTo().map{ |to| to.getAddress() }
        ccs = communication.getCc().map{ |cc| cc.getAddress() }
        bccs = communication.getBcc().map{ |bcc| bcc.getAddress() }
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
    
    def to_s(delimiter)
        @recipients.values.reduce(""){ |total, recipient| total + recipient.to_s(delimiter) + "\n" }
    end
    
    private
        def add_if_missing(address)
            if !@recipients.key?(address)
                @recipients[address] = Recipient.new(address)
            end
        end
end
         
        

def recipient_addresses(email)
    communication = email.getCommunication()
    tos = communication.getTo().map{ |to| to.getAddress() }
    ccs = communication.getCc().map{ |cc| cc.getAddress() }
    bccs = communication.getBcc().map{ |bcc| bcc.getAddress() }
    return tos + ccs + bccs
end

def all_recipient_addresses(emails)
    return emails.reduce(Set[]){ |total, email| total.merge(recipient_addresses(email))}
end

def all_from_addresses(email)
    communication = email.getCommunication()
    return communication.getFrom().map{ |from| from.getAddress() }
end

emails_from = currentCase.search("from:\"" + address + "\" has-communication:1")
to_connections = ToConnections.new
for item in emails_from
    to_connections.add_communication_item(item)
end

file_path = File.join(output_destination_path, output_filename + output_file_extension)
file = File.open(file_path, 'w')
file.puts('address' + delimiter + 'to' + delimiter + 'cc' + delimiter + 'bcc' + delimiter + 'total')
file.puts(to_connections.to_s(delimiter))
file.close
puts(to_connections.to_s(delimiter))