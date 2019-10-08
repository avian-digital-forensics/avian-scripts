require 'set'
require 'csv'

# Standard code for finding main directory.
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")

main_directory = get_main_directory(false)

unless main_directory
    puts("Script cancelled.")
    return
end

# For GUI messages.
require File.join(main_directory,"utils","nx_utils")
require File.join(main_directory,"utils","union_find")
# For storing result.
require File.join(main_directory,"utils","settings_utils")
require File.join(main_directory,"utils","identifier_graph")
# Timings.
require File.join(main_directory,"utils","timer")
# Graph correction heuristics.
require File.join(script_directory,"identifier_graph_heuristics")
# Progress messages.
require File.join(main_directory,"utils","utils")

# Returns a list of all the addresses in the communication of the item if such exists.
def all_addresses_in_item(item)
    communication = item.communication
    result = Set[]
    if communication
        if communication.from
            result.merge(communication.from)
        end
        if communication.to
            result.merge(communication.to)
        end
        if communication.cc
            result.merge(communication.cc)
        end
        if communication.bcc
            result.merge(communication.bcc)
        end
    end
    return result
end

## Setup GUI.
gui_title = "Find Correct Addresses"

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
heuristics_tab = dialog.add_tab("heuristics", "Heuristics Settings")

heuristics_tab.append_check_box("isolate_highly_connected_vertices", "Disconnect highly connected identifiers", true)
heuristics_tab.get_control("isolate_highly_connected_vertices").set_tool_tip_text("Whether identifiers with too many connections should be ignored.")
heuristics_tab.append_text_field("num_connections_for_isolation", "Maximum connections", "5")
heuristics_tab.get_control("num_connections_for_isolation").set_tool_tip_text("The maximum number of connections an identifier may have before it is ignored if the above is enabled.")


# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    
    # Make sure primary address is not empty.
    if values["num_connections_for_isolation"].strip.empty?
        if values["isolate_highly_connected_vertices"]
            CommonDialogs.show_warning("Please provide a maximum number of connections.", gui_title)
            next false
        end
    else 
        max_connections_value = Integer(values["num_connections_for_isolation"].strip) rescue false
        if not max_connections_value or max_connections_value < 0
            CommonDialogs.show_warning("Maximum number of connections must be a positive integer.", gui_title)
            next false
        end
    end
    
    # Everything is fine; close the dialog.
    next true
end

# Display dialog. Duh.
dialog.display

# If dialog result is false, the user has cancelled.
if dialog.get_dialog_result == true
    Utils.print_progress("Running script...")
    
    timer = Timing::Timer.new
    timer.start("total")
    
    # values contains the information the user inputted.
    values = dialog.to_map
    
    heuristics_settings = {}
    heuristics_settings[:isolate_highly_connected_vertices] = values["isolate_highly_connected_vertices"]
    heuristics_settings[:num_connections_for_isolation] = Integer(values["num_connections_for_isolation"])

    # The output directory.
    output_dir = SettingsUtils::case_data_dir(main_directory, current_case)

    # Find all items with a communication.
    messages = current_case.search("has-communication:1")

    puts("Found " + messages.length.to_s + " items with communication.")

    identifier_graph = IdentifierGraph::IdentifierGraph.new
    
    Utils.print_progress("Building graph of identifiers...")
    timer.start("build_graph")
    # Add all addresses to the graph.
    for message in messages
        for address in all_addresses_in_item(message)
            identifier_graph.add_address(address)
        end
    end
    timer.stop("build_graph")

    Utils.print_progress("Running heuristics on graph...")
    timer.start("heuristics")
    # Run graph heuristics.
    run_identifier_graph_heuristics(identifier_graph, heuristics_settings)
    timer.stop("heuristics")
    
    Utils.print_progress("Saving graph...")
    timer.start("save_graph")
    # Save identifier graph.
    graph_file_path = File.join(output_dir, "find_correct_addresses_graph.csv")
    CSV.open(graph_file_path, "wb") do |csv|
        identifier_graph.to_csv(csv)
    end
    timer.stop("save_graph")
    
    Utils.print_progress("Creating union find from graph...")
    timer.start("graph_to_union_find")
    identifiers = identifier_graph.to_union_find
    timer.stop("graph_to_union_find")

    puts("Found " + identifiers.num_components.to_s + " unique persons.")
    
    Utils.print_progress("Saving union find...")
    timer.start("write_union_find")
    # Write results to file.
    output_file_path = File.join(output_dir,"find_correct_addresses_output.txt")
    CSV.open(output_file_path, 'wb') do |csv|
        identifiers.to_csv(csv)
    end
    timer.stop("write_union_find")
    
    timer.stop("total")
    
    timer.print_timings
    
    CommonDialogs.show_information("Script finished. Found " + identifiers.num_components.to_s + " unique persons. \nThe result has been stored and is ready for use by other scripts.", gui_title)
    
    Utils.print_progress("Script finished.")
else
    Utils.print_progress("Script cancelled.")
end
