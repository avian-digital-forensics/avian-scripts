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
        return radio_options.select{ |key| dialog_values[key] }.first
    end
    
    def assert_non_empty_field(values, field_key, field_name)
        if values[field_key].strip.empty?
            CommonDialogs.showWarning("Please provide a non-empty value for '" + field_name + "'.", "Missing " + field_name.titleize)
            return false
        else
            return true
        end
    end
end