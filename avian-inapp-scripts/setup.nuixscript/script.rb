require 'yaml'
module Script

    def create_inapp_script(setup_directory, gui_title, script_name)
        require File.join(setup_directory,'get_main_directory')
        
        main_directory = get_main_directory(false)
        
        unless main_directory
            puts('Script cancelled because no main directory could be found.')
            return nil
        end
        
        return InAppScript.new(main_directory, gui_title, script_name)
    end

    class Settings
        def initialize(main_directory, script_name)
            # Settings files.
            require File.join(main_directory,'utils','settings_utils')
            @main_directory = main_directory
            @script_name = script_name
            @settings = SettingsUtils::load_script_settings(main_directory, script_name)
        end

        def [](key)
            @settings.key?(key) ? @settings[key] : ''
        end

        def []=(key, value)
            @settings[key] = value
        end

        def save
            SettingsUtils::save_script_settings(@main_directory, @script_name, @settings)
        end
    end

    class InAppScript
        attr_reader: settings, timer

        def initialize(main_directory, gui_title, script_name)
        
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
            @timer = Timer::Timer.new

            @settings_dialog = NXUtils.create_dialog(gui_title)
            @input_validater = Proc.new{ |values| next true }

            @settings_inputs = {}
            @radio_button_groups = {}
        end

        def dialog_validate_before_closing(&validate)
            @input_validater = validate
        end

        def run(&run)
            @settings_dialog.validate_before_closing(@input_validater)
            @settings_dialog.display

            if @settings_dialog.dialog_result
                values = @settings_dialog.to_map
                for key,type in @settings_inputs
                    if type == 'value'
                        @settings[key] = values[key]
                    elsif type == 'radio_button'
                        options_hash = @radio_button_groups[key]
                        @settings[key] = NXUtils::radio_group_value(values, options_hash)
                    end
                end
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

                    @timer.stop('total')
        
                    timer.print_timings

                    progress_dialog.set_main_status_and_log_it('Script finished. ' + script_finished_message)
                    CommonDialogs.show_information('Script finished.' + script_finished_message, gui_title)
                    progress_dialog.set_completed
                end
            else
                Utils.print_progress('Script cancelled.')
            end

        def dialog_add_tab(identifier, label)
            @settings_dialog.add_tab(identifier, label)
        end

        def dialog_append_check_box(tab_identifier, identifier, label, tooltip)
            value = @settings[identifier]

            tab = @settings_dialog.tab(tab_identifier)
            tab.append_check_box(identifier, label, value)
            tab.get_control(identifier).set_tool_tip_text(tooltip)

            @settings_inputs[identifier] = 'value'
        end

        def dialog_append_text_field(tab_identifier, identifier, label, tooltip)
            value = @settings[identifier]

            tab = @settings_dialog.tab(tab_identifier)
            tab.append_text_field(identifier, label, value)
            tab.get_control(identifier).set_tool_tip_text(tooltip)

            @settings_inputs[identifier] = 'value'
        end

        def dialog_append_horizontal_radio_button_group(tab_identifier, identifier, label, options_hash)
            value = @settings[identifier]

            tab = @settings_dialog.tab(tab_identifier)
            tab.append_radio_button_group(label, identifier, options_hash)
            if options_hash.has_value?(value)
                tab.set_checked(value, true) 
            end

            @settings_inputs[identifier] = 'radio_button'
            @radio_button_groups[identifier] = options_hash
        end

        def dialog_append_vertical_radio_button_group(tab_identifier, identifier, label, options_hash)
            value = @settings[identifier]

            tab = @settings_dialog.tab(tab_identifier)
            NXUtils::append_vertical_radio_button_group(tab, label, identifier + '_label', identifier, options_hash, value)

            @settings_inputs[identifier] = 'radio_button'
            @radio_button_groups[identifier] = options_hash
        end
    end
end
