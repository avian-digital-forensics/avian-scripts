require 'set'
require 'csv'

script_directory = File.expand_path('..', __FILE__)
root_directory = File.expand_path('../../_root', __FILE__)

# For GUI messages.
require File.join(root_directory,'utils','nx_utils')
require File.join(root_directory,'utils','union_find')
# For storing result.
require File.join(root_directory,'utils','settings_utils')
require File.join(root_directory,'utils','identifier_graph')
# Timings.
require File.join(root_directory,'utils','timer')
# Graph correction heuristics.
require File.join(script_directory,'identifier_graph_heuristics')
# Person correction heuristics.
require File.join(script_directory,'person_heuristics')
# Organize identifier in persons.
require File.join(script_directory,'person')
# Progress messages.
require File.join(root_directory,'utils','utils')

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
gui_title = 'Find Correct Addresses'

dialog = NXUtils.create_dialog(gui_title)

# Add main tab.
heuristics_tab = dialog.add_tab('heuristics', 'Heuristics Settings')

heuristics_tab.append_check_box('isolate_highly_connected_vertices', 'Disconnect highly connected identifiers', true)
heuristics_tab.get_control('isolate_highly_connected_vertices').set_tool_tip_text('Whether identifiers with too many connections should be ignored.')
heuristics_tab.append_text_field('num_connections_for_isolation', 'Maximum connections', '5')
heuristics_tab.get_control('num_connections_for_isolation').set_tool_tip_text('The maximum number of connections an identifier may have before it is ignored if the above is enabled.')
heuristics_tab.append_check_box('flag_persons_with_multiple_emails_with_domain', 'Flag persons with multiple emails with same domain', true)
heuristics_tab.get_control('flag_persons_with_multiple_emails_with_domain').set_tool_tip_text('Whether persons with several email addresses with the same domain should be flagged.')

# Checks the input before closing the dialog.
dialog.validate_before_closing do |values|
    
    # Make sure primary address is not empty.
    if values['num_connections_for_isolation'].strip.empty?
        if values['isolate_highly_connected_vertices']
            CommonDialogs.show_warning('Please provide a maximum number of connections.', gui_title)
            next false
        end
    else 
        max_connections_value = Integer(values['num_connections_for_isolation'].strip) rescue false
        if not max_connections_value or max_connections_value < 0
            CommonDialogs.show_warning('Maximum number of connections must be a positive integer.', gui_title)
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
    Utils.print_progress('Running script...')
    
    timer = Timing::Timer.new
    timer.start('total')
    
    # values contains the information the user inputted.
    values = dialog.to_map
    
    heuristics_settings = {}
    heuristics_settings[:isolate_highly_connected_vertices] = values['isolate_highly_connected_vertices']
    heuristics_settings[:num_connections_for_isolation] = Integer(values['num_connections_for_isolation'])
    heuristics_settings[:flag_persons_with_multiple_emails_with_domain] = values['flag_persons_with_multiple_emails_with_domain']

    # The output directory.
    output_dir = SettingsUtils::case_data_dir(root_directory, current_case)

    ProgressDialog.for_block do |progress_dialog|
        # Setup progress dialog.
        progress_dialog.set_title(gui_title)
        progress_dialog.on_message_logged do |message|
            Utils.print_progress(message)
        end
        
        # Find all items with a communication.
        messages = current_case.search('has-communication:1')

        progress_dialog.log_message('Found ' + messages.length.to_s + ' items with communication.')

        identifier_graph = IdentifierGraph::IdentifierGraph.new
        
        progress_dialog.set_main_status_and_log_it('Building graph of identifiers...')
        timer.start('build_graph')
        progress_dialog.set_main_progress(0,messages.size)
        # Add all addresses to the graph.
        messages.each_with_index do |message,message_index|
            for address in all_addresses_in_item(message)
                identifier_graph.add_address(address)
            end
            progress_dialog.increment_main_progress
			progress_dialog.set_sub_status("#{message_index+1}/#{messages.size}")
        end
        timer.stop('build_graph')

        progress_dialog.set_main_status_and_log_it('Running heuristics on graph...')
        timer.start('graph_heuristics')
        # Run graph heuristics.
        run_identifier_graph_heuristics(identifier_graph, heuristics_settings)
        timer.stop('graph_heuristics')
        
        progress_dialog.set_main_status_and_log_it('Saving graph...')
        timer.start('save_graph')
        # Save identifier graph.
        graph_file_path = File.join(output_dir, 'find_correct_addresses_graph.csv')
        CSV.open(graph_file_path, 'wb') do |csv|
            identifier_graph.to_csv(csv)
        end
        timer.stop('save_graph')
        
        progress_dialog.set_main_status_and_log_it('Creating union find from graph...')
        timer.start('graph_to_union_find')
        # Create union find from graph.
        identifiers = identifier_graph.to_union_find
        timer.stop('graph_to_union_find')

        progress_dialog.log_message('Found ' + identifiers.num_components.to_s + ' unique persons.')
        
        progress_dialog.set_main_status_and_log_it('Saving union find...')
        timer.start('write_union_find')
        # Write union find to file.
        output_file_path = File.join(output_dir,'find_correct_addresses_union_find.csv')
        CSV.open(output_file_path, 'wb') do |csv|
            identifiers.to_csv(csv)
        end
        timer.stop('write_union_find')

        progress_dialog.set_main_status_and_log_it('Creating persons from union find...')
        timer.start('union_find_to_persons')
        progress_dialog.set_main_progress(0,identifiers.num_components)
        # Create persons from union find.
        cur_index = 0
        persons = FindCorrectAddresses::PersonManager.from_union_find(identifiers) do
            progress_dialog.increment_main_progress
			progress_dialog.set_sub_status("#{cur_index+=1}/#{identifiers.num_components}")
        end
        timer.stop('union_find_to_persons')

        progress_dialog.set_main_status_and_log_it('Running heuristics on persons...')
        timer.start('person_heuristics')
        # Run person heuristics.
        progress_dialog.set_main_progress(0,persons.num_persons)
        cur_index = 0
        run_person_heuristics(persons, heuristics_settings) do
            progress_dialog.increment_main_progress
            progress_dialog.set_sub_status("#{cur_index+=1}/#{persons.num_persons}")
        end
        timer.stop('person_heuristics')

        progress_dialog.set_main_status_and_log_it('Saving person manager...')
        timer.start('write_person_manager')
        # Write results to file.
        progress_dialog.set_main_progress(0,persons.num_persons)
        cur_index = 0
        output_file_path = File.join(output_dir,'find_correct_addresses_output.csv')
        CSV.open(output_file_path, 'wb') do |csv|
            persons.to_csv(csv) do
                progress_dialog.increment_main_progress
                progress_dialog.set_sub_status("#{cur_index+=1}/#{persons.num_persons}")
            end
        end
        timer.stop('write_person_manager')


        progress_dialog.set_main_status_and_log_it('Script finished.')
    
        timer.stop('total')
        
        timer.print_timings
        
        CommonDialogs.show_information('Script finished. Found ' + 
                identifiers.num_components.to_s + " unique persons." +
                " \nThe result has been stored and is ready for use by other scripts.", 
                gui_title)
        progress_dialog.set_completed
    end
    
    Utils.print_progress('Script finished.')
else
    Utils.print_progress('Script cancelled.')
end
