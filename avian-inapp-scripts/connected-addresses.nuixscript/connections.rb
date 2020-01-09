require File.join(File.dirname(__FILE__), 'recipient')

module ConnectedAddresses
    # Represents all addresses that have communicated with the primary address.
    class Connections
        
        # Initializes the Connections as empty.
        def initialize()
            @recipients = {}
        end
        
        # Adds 1 to the specified value of the specified address.
        def increment_value(address, key)
            add_if_missing(address)
            @recipients[address].increment_value(key)
        end
        
        # Handles a communication item sent from the primary address.
        def add_communication_item_from(item)
            communication = item.getCommunication()
            # Find all to, cc and bcc addresses.
            receive_tos = communication.getTo().map{ |to| to.getAddress() }
            receive_ccs = communication.getCc().map{ |cc| cc.getAddress() }
            receive_bccs = communication.getBcc().map{ |bcc| bcc.getAddress() }
            # Update the recipients.
            for address in receive_tos
                increment_value(address, "receive_tos")
            end
            for address in receive_ccs
                increment_value(address, "receive_ccs")
            end
            for address in receive_bccs
                increment_value(address, "receive_bccs")
            end
            return
        end
        
        # Handles a communication item sent to the primary address.
        def add_communication_item_to(item)
            communication = item.getCommunication()
            send_tos = communication.from.map { |from| from.address }
            
            for address in send_tos
                increment_value(address, "send_tos")
            end
        end
        
        # Handles a communication item sent cc the primary address.
        def add_communication_item_cc(item)
            communication = item.getCommunication()
            send_ccs = communication.from.map { |from| from.address }
            
            for address in send_ccs
                increment_value(address, "send_ccs")
            end
        end
        
        # Handles a communication item sent bcc the primary address.
        def add_communication_item_bcc(item)
            communication = item.getCommunication()
            send_bccs = communication.from.map { |from| from.address }
            
            for address in send_bccs
                increment_value(address, "send_bccs")
            end
        end
        
        def num_recipients
            @recipients.length
        end
        
        # Prints all contained recipients with newlines between them.
        def to_s(delimiter)
            @recipients.values.reduce(""){ |total, recipient| total + recipient.to_s(delimiter) + "\n" }
        end
        
        private
            # Adds a new recipient with the address if none exists.
            def add_if_missing(address)
                unless @recipients.key?(address)
                    @recipients[address] = Recipient.new(address)
                end
            end
    end
end