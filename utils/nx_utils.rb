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
    
    # Returns the selected value in the out of the given radio_options.
    def radio_group_value(dialog_values, radio_options)
        radio_keys = radio_options.values # Yes, this does make sense.
        return radio_keys.select{ |key| dialog_values[key] }.first
    end
    
    def assert_non_empty_field(values, field_key, field_name)
        if values[field_key].strip.empty?
            CommonDialogs.showWarning("Please provide a non-empty " + field_name + ".", "Missing " + field_name.titleize)
            return false
        else
            return true
        end
    end
end