script_directory = File.dirname(__FILE__)
# Finds the path to the Nx.jar in the resources directory.
require File.join(script_directory,"..","resources","Nx.jar")

# Imports a mess of nx graphics modules.
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "com.nuix.nx.dialogs.ProcessingStatusDialog"
java_import "com.nuix.nx.digest.DigestHelper"
java_import "com.nuix.nx.controls.models.Choice"

# Changes to windows look and feel.
LookAndFeelHelper.setWindowsIfMetal

# This is probably necessary.
NuixConnection.setUtilities($utilities)

# This too.
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

module NXUtils
    extend self
    
    # Simply creates a dialog with the given title.
    def create_dialog(title)
        return TabbedCustomDialog.new(title)
    end

    # Returns the selected value out of the given radio_options.
    # Params:
    # +dialog_values+:: The value hash returned by the dialog.
    # +radio_options+:: A list of the possible radio buttons.
    def radio_group_value(dialog_values, radio_options)
        selected_value = radio_options.select{ |key,value| dialog_values[key] }.first
        if selected_value == nil
            return ''
        else
            # First returns a array [key, value]. Since we are interested in the value:
            return selected_value[1]
        end
    end

    # Appends a number of radio buttons in the same group to the specified tab.
    # Params:
    # +tab+:: The tab to append the radio buttons to.
    # +group_label+:: The label for the group shown to the user.
    # +group_label_identifier+:: The identifier for the group label control.
    # +radio_button_group_name+:: The identifier for the radio button group.
    # +radio_button_choices+:: A hash with radio button labels as keys and identifiers as values.
    # +default_choice+:: Any radio button with this identifier will be checked by default. If not given, no radio button will be checked.
    def append_vertical_radio_button_group(tab, group_label, group_label_identifier, radio_button_group_name, radio_button_choices, default_choice='')
        tab.append_label(group_label_identifier, group_label)
        for label,identifier in radio_button_choices
            tab.append_radio_button(identifier, label, radio_button_group_name, identifier==default_choice)
        end
    end
    
    def assert_non_empty_field(values, field_key, field_name)
        if values[field_key].strip.empty?
            CommonDialogs.show_warning("Please provide a non-empty value for '" + field_name + "'.", "Missing " + field_name.titleize)
            return false
        else
            return true
        end
    end
end