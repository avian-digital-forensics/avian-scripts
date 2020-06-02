# This file is placed in the setup.nuixscript directory because it must be in the avian-inapp-scripts yet should show up in the script list.

require 'yaml'
module Script
    extend self

    
    # Creates an instance of the InAppScript class for and finds the main_directory for it.
    # Params:
    # +setup_directory+:: The directory of the setup script. The location where the main_directory utilities are located.
    # +gui_title+:: The title given to all GUI elements.
    # +script_name+:: The internal script identifier. Should be the same as used in the directory name but with _ instead of -.
    # +current_case+:: The case the script is being run on.
    # +utilites+:: The Utilities object provided by Nuix.
    def create_inapp_script(setup_directory, gui_title, script_name, current_case, utilities)
        require File.join(setup_directory,'get_main_directory')
        
        main_directory = get_main_directory(false)
        
        # If the main_directory could not be found, few things will work.
        unless main_directory
            puts('Script cancelled because no main directory could be found.')
            return nil
        end
        
        # Create and return a new InAppScript.
        return InAppScript.new(main_directory, gui_title, script_name, current_case, utilities)
    end

    # Used to store settings of an inapp script.
    class Settings
        # Initializes a new inapp script settings object and loads the script's settings from file.
        # Loads from default file if none other exists.
        # Params:
        # +main_directory+:: The main directory. The one where the data directory is located.
        # +script_name+:: The name of the script. Used to calculate the names of the settings files.
        def initialize(main_directory, script_name)
            # Settings files.
            require File.join(main_directory,'utils','settings_utils')
            @main_directory = main_directory
            @script_name = script_name
            @settings = SettingsUtils::load_script_settings(main_directory, script_name)
        end

        # Returns the setting with the given key or '' if no such setting exists.
        def [](key)
            @settings.key?(key) ? @settings[key] : ''
        end

        # Sets the setting with the given key.
        def []=(key, value)
            @settings[key] = value
        end

        # Saves the settings to the script's settings file, overwriting any settings already stored.
        def save
            SettingsUtils::save_script_settings(@main_directory, @script_name, @settings)
        end
    end

    # A class meant to abstract away as much boiler plate as possible from individual inapp scripts.
    class InAppScript
        # The settings_dialog can be set up manually, but the input to these fields will not be saved automatically.
        attr_reader :settings, :timer, :main_directory, :settings_dialog, :current_case, :utilities

        # Initializes the InAppScript. Inapp scripts should use create_inapp_script instead.
        # Params:
        # +main_directory+:: The main directory. The one where the data directory is located.
        # +gui_title+:: The title given to all GUI elements.
        # +script_name+:: The internal script identifier. Should be the same as used in the directory name but with _ instead of -.
        # +current_case+:: The case the script is being run on.
        # +utilites+:: The Utilities object provided by Nuix.
        def initialize(main_directory, gui_title, script_name, current_case, utilities)
            @main_directory = main_directory
            @utilities = utilities
            @current_case = current_case
            @script_name = script_name

            # For GUI.
            require File.join(main_directory,'utils','nx_utils')
            # Timings.
            require File.join(main_directory,'utils','timer')
            # Settings files.
            require File.join(main_directory,'utils','settings_utils')
            # Progress messages.
            require File.join(main_directory,'utils','utils')

            @gui_title = gui_title
            @settings = Settings.new(main_directory, script_name)
            @timer = Timing::Timer.new

            @settings_dialog = NXUtils.create_dialog(gui_title)
            # Default value for input validater for dialog.
            @input_validater = Proc.new{ |values| next true }

            # Stores all settings in the dialog and which type they are.
            @settings_inputs = {}
            # All options for all radio button groups.
            @radio_button_groups = {}

            # A list of all the temporary tags added by the script.
            @temporary_tags = {}
        end

        # Sets the dialog's input validater.
        def dialog_validate_before_closing(&validate)
            @input_validater = validate
        end

        # Runs the script. Displays the dialog and processes and saves the results. Creates and sets up the progress dialog.
        # After the script has been run, prints timings and prints finishing messages to user.
        def run(&run)
            # Run settings dialog.
            @settings_dialog.validate_before_closing do |values|
                settings = {}
                for key,type in @settings_inputs
                    if type == 'value'
                        # All settings stored as such.
                        settings[key] = values[key]
                    elsif type == 'radio_button'
                        # Radio buttons are returned by the dialog in a weird way, so they require special treatment.
                        options_hash = @radio_button_groups[key]
                        settings[key] = NXUtils::radio_group_value(values, options_hash)
                    end
                end
                result = @input_validater.call(settings)
                next result
            end
            @settings_dialog.display

            if @settings_dialog.dialog_result
                # Get the inputted settings from the dialog.
                values = @settings_dialog.to_map
                # Run through all settings and process the inputs.
                for key,type in @settings_inputs
                    if type == 'value'
                        # All settings stored as such.
                        @settings[key] = values[key]
                    elsif type == 'radio_button'
                        # Radio buttons are returned by the dialog in a weird way, so they require special treatment.
                        options_hash = @radio_button_groups[key]
                        @settings[key] = NXUtils::radio_group_value(values, options_hash)
                    end
                end
                # Save the inputted settings to file.
                @settings.save

                ProgressDialog.for_block do |progress_dialog|
                    @timer.start('total')
                    # Setup progress dialog.
                    progress_dialog.set_title(@gui_title)
                    progress_dialog.on_message_logged do |message|
                        Utils.print_progress(message)
                    end
                    progress_dialog.set_sub_progress_visible(false)

                    # Run actual script.
                    script_finished_message = run.call(progress_dialog)

                    # Remove temporary tags.
                    progress_dialog.set_main_status_and_log_it('Removing temporary tags...')
                    @timer.start('remove_temporary_tags')
                    for tag,group_name in @temporary_tags
                        @timer.start('remove_temp_tag_' + tag)
                        progress_dialog.set_main_status_and_log_it('Removing temporary tag from ' + group_name + '...')
                        items_with_tag = @current_case.search("tag:\"#{tag}\"")
                        Utils.bulk_remove_tag(@utilities, progress_dialog, tag, items_with_tag)
                        @current_case.delete_tag(tag)
                        @timer.stop('remove_temp_tag_' + tag)
                    end

                    @timer.stop('total')
        
                    @timer.print_timings

                    progress_dialog.set_main_status_and_log_it('Script finished. ' + script_finished_message)
                    CommonDialogs.show_information('Script finished.' + script_finished_message, @gui_title)
                    progress_dialog.set_completed
                end
            else
                Utils.print_progress('Script cancelled.')
            end
        end

        # Returns the string placed between Avian| and |<tag_name> in tags from this script.
        def self.find_script_tag_prefix(script_name)
            script_name.split('_').map{|e| e.capitalize}.join
        end

        # Returns the given tag in script tag format, i.e. Avian|<script name>|<tag>.
        # If tag already has some of the prefix, this is not duplicated.
        def to_script_tag(tag)
            script_tag_prefix = InAppScript.find_script_tag_prefix(@script_name)
            if tag.start_with?('Avian|' + script_tag_prefix + '|')
                return tag
            elsif tag.start_with?('Avian|')
                return 'Avian|' + InAppScript.find_script_tag_prefix(@script_name) + '|' + tag[6..-1]
            elsif tag.start_with?(script_tag_prefix + '|')
                return 'Avian|' + tag
            else
                return 'Avian|' + script_tag_prefix + '|' + tag
            end
        end

        # Add tag to the specified items.
        # The tag will be modified to ensure the proper prefix. The modified tag is returned.
        # Tag will be removed from all items in the case when the script is finished.
        # Params:
        # +tag+:: The tag to give to the items. Automatically adds the Avian| prefix if it is missing.
        # +items+:: The items to give the tag to.
        # +item_group_name+:: What to call the items in messages, e.g. item_group_name='RFC mails' -> 'Adding temporary tag to RFC mails for internal use...'
        # +progress_dialog+:: The ProgressDialog used to update the user on progress.
        def create_temporary_tag(tag, items, item_group_name, progress_dialog)
            # Add Avian| prefix to tag if it isn't there already.
            tag = to_script_tag(tag)
            @timer.start('add_temp_tag_' + tag)
            progress_dialog.set_main_status_and_log_it('Adding temporary tag to ' + item_group_name + ' for internal use...')
            Utils.bulk_add_tag(@utilities, progress_dialog, tag, items)
            @temporary_tags[tag] = item_group_name
            @timer.stop('add_temp_tag_' + tag)
            return tag
        end

        # Add tab to the script's settings dialog.
        # Params:
        # +identifier+:: The internal identifier for the tab.
        # +label+:: The label for the tab the user sees.
        def dialog_add_tab(identifier, label)
            @settings_dialog.add_tab(identifier, label)
        end

        # Appends a checkbox to the specified tab.
        # Params:
        # +tab_identifier+:: The identifier for the tab in which to add the check box.
        # +identifier+:: The internal identifier for the checkbox. This is the key to the setting.
        # +label+:: The text the user sees.
        # +tooltip+:: The tooltip that appears when the user hovers over the box with their mouse.
        def dialog_append_check_box(tab_identifier, identifier, label, tooltip)
            value = @settings[identifier]

            tab = @settings_dialog.get_tab(tab_identifier)
            unless tab
                raise 'No such tab "' + tab_identifier + '"'
            end
            # Value must be compared to true to get a boolean value understood by JRuby.
            tab.append_check_box(identifier, label, value == true)
            tab.get_control(identifier).set_tool_tip_text(tooltip)

            @settings_inputs[identifier] = 'value'
        end

        # Appends a text field to the specified tab.
        # Params:
        # +tab_identifier+:: The identifier for the tab in which to add the text field.
        # +identifier+:: The internal identifier for the text field. This is the key to the setting.
        # +label+:: The text the user sees.
        # +tooltip+:: The tooltip that appears when the user hovers over the field with their mouse.
        def dialog_append_text_field(tab_identifier, identifier, label, tooltip)
            value = @settings[identifier]

            tab = @settings_dialog.get_tab(tab_identifier)
            unless tab
                raise 'No such tab "' + tab_identifier + '"'
            end
            tab.append_text_field(identifier, label, value)
            tab.get_control(identifier).set_tool_tip_text(tooltip)

            @settings_inputs[identifier] = 'value'
        end

        # Appends a open file chooser to the specified tab.
        # Params:
        # +tab_identifier+:: The identifier for the tab in which to add the open file chooser.
        # +identifier+:: The internal identifier for the open file chooser. This is the key to the setting.
        # +label+:: The text the user sees.
        # +file_type_name+:: The name of the file type.
        # +file_type_extension+:: the extension of the file type. E.g. .rtf, .csv.
        # +tooltip+:: The tooltip that appears when the user hovers over the field with their mouse.
        # +file_chosen_callback+:: Run whenever a new path is chosen.
        def dialog_append_open_file_chooser(tab_identifier, identifier, label, file_type_name, file_type_extension, tooltip, file_chosen_callback = nil)
            value = @settings[identifier]

            tab = @settings_dialog.get_tab(tab_identifier)
            if file_chosen_callback
                tab.append_open_file_chooser(identifier, label, file_type_name, file_type_extension, file_chosen_callback)
            else
                tab.append_open_file_chooser(identifier, label, file_type_name, file_type_extension)
            end

            tab.get_control(identifier).set_tool_tip_text(tooltip)
            tab.set_text(identifier, value)

            @settings_inputs[identifier] = 'value'
        end

        # Appends a horizontal group of radio buttons to the specified tab.
        # Params:
        # +tab_identifier+:: The identifier for the tab in which to add the radio buttons.
        # +identifier+:: The internal identifier for the radio buttons. This is the key to the setting.
        # +label+:: The text the user sees.
        # +options_hash+:: A hash of options where keys are the text the user sees and values are the setting values they represent.
        def dialog_append_horizontal_radio_button_group(tab_identifier, identifier, label, options_hash)
            value = @settings[identifier]

            tab = @settings_dialog.get_tab(tab_identifier)
            unless tab
                raise 'No such tab "' + tab_identifier + '"'
            end
            tab.append_radio_button_group(label, identifier, options_hash)
            if options_hash.has_value?(value)
                tab.set_checked(value, true) 
            end

            @settings_inputs[identifier] = 'radio_button'
            @radio_button_groups[identifier] = options_hash
        end

        # Appends a vertical group of radio buttons to the specified tab.
        # Params:
        # +tab_identifier+:: The identifier for the tab in which to add the radio buttons.
        # +identifier+:: The internal identifier for the radio buttons. This is the key to the setting.
        # +label+:: The text the user sees.
        # +options_hash+:: A hash of options where keys are the text the user sees and values are the setting values they represent.
        def dialog_append_vertical_radio_button_group(tab_identifier, identifier, label, options_hash)
            value = @settings[identifier]

            tab = @settings_dialog.get_tab(tab_identifier)
            unless tab
                raise 'No such tab "' + tab_identifier + '"'
            end
            NXUtils::append_vertical_radio_button_group(tab, label, identifier + '_label', identifier, options_hash, value)

            @settings_inputs[identifier] = 'radio_button'
            @radio_button_groups[identifier] = options_hash
        end
    end
end
