require 'yaml'
require 'fileutils'
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"utils","nx_utils")

main_directory = ""
while main_directory == ""
    input = CommonDialogs.get_directory("", "Main Script Directory").path
    if input.empty?
        CommonDialogs.show_warning("You must specify the path to the main script directory.")
        next false
    elsif not File.directory?(input)
        CommonDialogs.show_warning("The specified main script directory path is not a directory.")
        next false
    elsif not File.file?(input + "/wss_dispatcher.rb")
        CommonDialogs.show_warning("Wrong path specified for main script directory. The directory required is the one with the file 'wss_dispatcher.rb'.")
        next false
    else
        main_directory = input
    end
end

settings_file = File.join(main_directory, 'data', 'wss_settings.yml')

# If the settings file does not exist, create it from defaults.
if not File.file?(settings_file)
    FileUtils.cp(File.join(main_directory, 'data', 'default_wss_settings.yml'), settings_file)
end

# Load current settings.
wss_settings = YAML.load(File.read(settings_file))

## Create GUI.
dialog = TabbedCustomDialog.new("Connected Addresses")

# Add main tab.
main_tab = dialog.add_tab("main_tab", "Main")

for script in wss_settings[:scripts]
    main_tab.append_check_box(script[:identifier], script[:label], script[:active])
end

dialog.validate_before_closing do |values|
    
    # Everything is fine; close the dialog.
    next true
end

## Display GUI.
dialog.display

## Handle GUI input.
if dialog.get_dialog_result == true
    puts("Applying settings...")
    values = dialog.to_map
    
    # Set the new activation values for wss's.
    for script in wss_settings[:scripts]
        script[:active] = values[script[:identifier]]
    end
    
    # Update wss_caller.rb with the new path.
    default_wss_caller_path = File.join(main_directory, "data", "default_wss_caller.rb")
    wss_caller_path = File.join(main_directory, "wss_caller.rb")
    wss_caller = File.read(default_wss_caller_path)
    new_wss_caller = wss_caller.gsub(/PATH = '.*'/, "PATH = '" + main_directory + "'")
    File.open(wss_caller_path, "w") { |file| file.write(new_wss_caller) }
    
    # Write the new settings.
    File.open(settings_file, "w") { |file| file.write(wss_settings.to_yaml) }
    puts("Scripts finished.")
end