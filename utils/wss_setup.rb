require 'yaml'

module WSSSetup
  class WSSSetup
    def initialize(main_directory, case_name, case_guid)
      require File.join(main_directory, 'utils', 'settings_utils')
      
      @main_directory = main_directory

      @wss_settings_path = File.join(main_directory,'data','wss_settings.yml')
      # If the settings file does not exist, create it from defaults.
      unless File.file?(@wss_settings_path)
        FileUtils.cp(File.join(main_directory, 'data', 'default_wss_settings.yml'), @wss_settings_path)
      end
      @wss_settings = YAML.load(File.read(@wss_settings_path))

      # Set all WSSs to inactive
      for script in @wss_settings[:scripts]
        script[:active] = false
      end
      
      @wss_settings[:case] = SettingsUtils::CaseInformation.store_case_information(case_name, case_guid, main_directory).to_yaml_hash
    end

    def enable_script(script_identifier)
      for script in @wss_settings[:scripts]
          .select { |script| script[:identifier] == script_identifier }
        script[:active] = false
      end
    end

    def available_scripts
      @wss_settings[:scripts].map { |script| script[:identifier] }
    end

    def setup
      # Write the new settings.
      File.open(@wss_settings_path, "w") { |file| file.write(@wss_settings.to_yaml) }

      generate_wss_caller
    end

    def generate_wss_caller

      # Update wss_caller.rb with the new path.
      default_wss_caller_path = File.join(main_directory, "data", "default_wss_caller.rb")
      wss_caller_path = File.join(main_directory, "wss_caller.rb")
      default_wss_caller = File.read(default_wss_caller_path)
      main_directory_string = main_directory.gsub(/\\/,'\\\\\\\\\\\\\\\\') # These are all necessary to make up for escaping.
      wss_caller = default_wss_caller.gsub(/PATH = '.*'/, "PATH = '" + main_directory_string + "'")
      File.open(wss_caller_path, "w") { |file| file.write(wss_caller) }
      wss_caller
    end
  end
end