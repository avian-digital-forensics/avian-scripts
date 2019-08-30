# Standard code for finding main directory.
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

if not main_directory
    puts("Script cancelled.")
    return
end

# For GUI.
require File.join(main_directory,"utils","nx_utils")


dialog = NXUtils.create_dialog("Connected Addresses")

# Add main tab.
main_tab = dialog.addTab("main_tab", "Main")

# Add text field for primary address.
main_tab.appendTextField("primary_address", "Primary Address", "")
main_tab.getControl("primary_address").setToolTipText("The address to examine")

# Add file chooser for output path.
main_tab.appendOpenFileChooser("output_path", "Output Path", "Comma Seperated Values", "csv")

# The options for the delimiters.
delimiter_options = { 'Comma (,)' => ',', 'Semicolon (;)' => ';', 'Space ( )' => ' ' , 'Custom' => 'custom' }

# Add radio buttons for delimiter choice.
main_tab.appendRadioButtonGroup("Delimiter", "delimiter", delimiter_options)

# Add custom delimiter text field.
main_tab.appendTextField("custom_delimiter", "Custom Delimiter", "")
main_tab.getControl("custom_delimiter").setToolTipText("Used to seperate values in the resulting csv if the above is set to 'Custom'")

# Add information about the script.
main_tab.appendInformation("script_description", "", "Searches through all messages sent by the primary address and counts how often each address appears as to, cc or bcc.")

# Checks the input before closing the dialog.
dialog.validateBeforeClosing do |values|
    # Make sure primary address is not empty.
    if values["primary_address"].strip.empty?
        CommonDialogs.showWarning("Please provide a non-empty primary address.", "No Primary Address")
        next false
    end
    # Make sure path is not empty.
    if values["output_path"].strip.empty?
        CommonDialogs.showWarning("Please provide a non-empty output path.", "No Output Path")
        next false
    end
    # Make sure custom delimiter is not empty if that option is chosen.
    delimiter = NXUtils.radio_group_value(values, delimiter_options)
    if delimiter == 'custom' and values["custom_delimiter"].strip.empty?
        CommonDialogs.showWarning("If you choose to provide your own delimiter, please do so.", "No custom delimiter")
        next false
    end
    # Everything is fine; close the dialog.
    next true
end

dialog.display

if dialog.getDialogResult == true
    puts("Running script...")
    values = dialog.toMap
    
    # The address whose recipients are wanted.
    address = values["primary_address"]

    # The output path.
    file_path = values["output_path"]
    if !file_path.end_with?(".csv")
        file_path += ".csv"
    end

    # What delimiter is used between values on the same line.
    delimiter = NXUtils.radio_group_value(values, delimiter_options)
    if delimiter == "custom"
        delimiter = values["custom_delimiter"]
    end
    
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
                if !@recipients.key?(address)
                    @recipients[address] = Recipient.new(address)
                end
            end
    end
    
    connections = Connections.new

    # All communication items with a from matching the given identifier.
    emails_from = currentCase.search("from:\"" + address + "\" has-communication:1")
    # Handle all communication items from.
    for item in emails_from
        connections.add_communication_item_from(item)
    end

    # All communication items with a to matching the given identifier.
    emails_to = currentCase.search("to:\"" + address + "\" has-communication:1")
    # Handle all communication items to.
    for item in emails_to
        connections.add_communication_item_to(item)
    end

    # All communication items with a cc matching the given identifier.
    emails_cc = currentCase.search("cc:\"" + address + "\" has-communication:1")
    # Handle all communication items cc.
    for item in emails_cc
        connections.add_communication_item_cc(item)
    end

    # All communication items with a bcc matching the given identifier.
    emails_bcc = currentCase.search("bcc:\"" + address + "\" has-communication:1")
    # Handle all communication items bcc.
    for item in emails_bcc
        connections.add_communication_item_bcc(item)
    end

    file = File.open(file_path, 'w')
    # Add header.
    file.puts('address' + delimiter + 'receive_to' + delimiter + 'receive_cc' + delimiter + 'receive_bcc' + delimiter + 'receive_total' + delimiter + 'send_to' + delimiter + 'send_cc' + delimiter + 'send_bcc' + delimiter + 'send_total' + delimiter + 'total')
    # Add data.
    file.puts(connections.to_s(delimiter))
    # Close file.
    file.close
    
    puts("Found " + connections.num_recipients.to_s + " connected addresses")
    puts("Results written to: " + file_path)
    
    CommonDialogs.show_information("Script finished. Found " + connections.num_recipients.to_s + " connected addresses. Results written to " + file_path, "Connected Addresses")
    
    puts("Scipt finished.")
else
    puts("Script cancelled.")
end
