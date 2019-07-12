script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","resources","Nx.jar")

java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "com.nuix.nx.dialogs.ProcessingStatusDialog"
java_import "com.nuix.nx.digest.DigestHelper"
java_import "com.nuix.nx.controls.models.Choice"

LookAndFeelHelper.setWindowsIfMetal

NuixConnection.setUtilities($utilities)

NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

module NXUtils
    extend self
    
    def create_dialog(title)
        return TabbedCustomDialog.new(title)
    end
end