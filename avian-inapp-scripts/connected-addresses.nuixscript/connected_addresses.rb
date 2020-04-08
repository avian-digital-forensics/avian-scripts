# Standard code for finding main directory.
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled.")
    return
end

require File.join(script_directory,'connections')

# For GUI.
require File.join(main_directory,"utils","nx_utils")
# Timings.
require File.join(main_directory,"utils","timer")
# Progress messages.
require File.join(main_directory,"utils","utils")


dialog = NXUtils.create_dialog("Connected Addresses")

# Add main tab.
main_tab = dialog.add_tab("main_tab", "Main")

# Add text field for primary address.
main_tab.append_text_field("primary_address", "Primary Address", "")
main_tab.get_control("primary_address").set_tool_tip_text("The address to examine")

# Add file chooser for output path.
main_tab.append_open_file_chooser("output_path", "Output Path", "Comma Seperated Values", "csv")

# The options for the delimiters.
delimiter_options = { 'Comma (,)' => ',', 'Semicolon (;)' => ';', 'Space ( )' => ' ' , 'Custom' => 'custom' }

# Add radio buttons for delimiter choice.
main_tab.append_radio_button_group("Delimiter", "delimiter", delimiter_options)

# Add custom delimiter text field.
main_tab.append_text_field("custom_delimiter", "Custom Delimiter", "")
main_tab.get_control("custom_delimiter").set_tool_tip_text("Used to seperate values in the resulting csv if the above is set to 'Custom'")

# Add information about the script.
main_tab.append_information("script_description", "", "Searches through all messages sent by the primary address and counts how often each address appears as to, cc or bcc.")

# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    # Make sure primary address is not empty.
    if values["primary_address"].strip.empty?
        CommonDialogs.show_warning("Please provide a non-empty primary address.", "No Primary Address")
        next false
    end
    # Make sure path is not empty.
    if values["output_path"].strip.empty?
        CommonDialogs.show_warning("Please provide a non-empty output path.", "No Output Path")
        next false
    end
    # Make sure custom delimiter is not empty if that option is chosen.
    delimiter = NXUtils.radio_group_value(values, delimiter_options)
    if delimiter == 'custom' and values["custom_delimiter"].strip.empty?
        CommonDialogs.show_warning("If you choose to provide your own delimiter, please do so.", "No custom delimiter")
        next false
    end
    # Everything is fine; close the dialog.
    next true
end

dialog.display

if dialog.dialog_result
    Utils.print_progress("Running script...")
    values = dialog.to_map

    timer = Timing::Timer.new

    timer.start('total')
    
    # The address whose recipients are wanted.
    address = values["primary_address"]

    # The output path.
    file_path = values["output_path"]
    unless file_path.end_with?(".csv")
        file_path += ".csv"
    end

    # What delimiter is used between values on the same line.
    delimiter = NXUtils.radio_group_value(values, delimiter_options.values)
    if delimiter == "custom"
        delimiter = values["custom_delimiter"]
    end
    
    connections = ConnectedAddresses::Connections.new

    timer.start('find_from')
    Utils.print_progress('Finding messages from the primary address...')
    # All communication items with a from matching the given identifier.
    emails_from = currentCase.search("from:\"" + address + "\" has-communication:1")
    # Handle all communication items from.
    for item in emails_from
        connections.add_communication_item_from(item)
    end
    timer.stop('find_from')

    timer.start('find_to')
    Utils.print_progress('Finding messages to the primary address...')
    # All communication items with a to matching the given identifier.
    emails_to = currentCase.search("to:\"" + address + "\" has-communication:1")
    # Handle all communication items to.
    for item in emails_to
        connections.add_communication_item_to(item)
    end
    timer.stop('find_to')

    timer.start('find_cc')
    Utils.print_progress('Finding messages cc the primary address...')
    # All communication items with a cc matching the given identifier.
    emails_cc = currentCase.search("cc:\"" + address + "\" has-communication:1")
    # Handle all communication items cc.
    for item in emails_cc
        connections.add_communication_item_cc(item)
    end
    timer.stop('find_cc')

    timer.start('find_bcc')
    Utils.print_progress('Finding messages bcc the primary address...')
    # All communication items with a bcc matching the given identifier.
    emails_bcc = currentCase.search("bcc:\"" + address + "\" has-communication:1")
    # Handle all communication items bcc.
    for item in emails_bcc
        connections.add_communication_item_bcc(item)
    end
    timer.stop('find_bcc')

    timer.start('write_results')
    Utils.print_progress('Writing results to file...')
    file = File.open(file_path, 'w')
    # Add header.
    file.puts('address' + delimiter + 'receive_to' + delimiter + 'receive_cc' + delimiter + 'receive_bcc' + delimiter + 'receive_total' + delimiter + 'send_to' + delimiter + 'send_cc' + delimiter + 'send_bcc' + delimiter + 'send_total' + delimiter + 'total')
    # Add data.
    file.puts(connections.to_s(delimiter))
    # Close file.
    file.close
    timer.stop('write_results')
    
    Utils.print_progress("Found " + connections.num_recipients.to_s + " connected addresses")
    Utils.print_progress("Results written to: " + file_path)

    timer.stop('total')

    timer.print_timings()
    
    # Tell the user the script has finished.
    CommonDialogs.show_information("Script finished. Found " + connections.num_recipients.to_s + " connected addresses. Results written to " + file_path, "Connected Addresses")
    
    Utils.print_progress("Script finished.")
else
    Utils.print_progress("Script cancelled.")
end
