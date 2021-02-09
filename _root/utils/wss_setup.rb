require 'yaml'

module WSSSetup
  # Create a WSSSetup.
  # All scripts will be disabled to start.
  # Params:
  # +root_directory+:: The main script directory where settings and WSSs are stored.
  # +case_name+:: The name of the case.
  # +case_guid+:: The GUID of the case
  def self.load(root_directory, case_name, case_guid)
    WSSSetup.new(root_directory, case_name, case_guid)
  end

  class WSSSetup
    # Create a WSSSetup.
    # All scripts will be disabled to start.
    # Params:
    # +root_directory+:: The main script directory where settings and WSSs are stored.
    # +case_name+:: The name of the case.
    # +case_guid+:: The GUID of the case
    def initialize(root_directory, case_name, case_guid)
      require File.join(root_directory, 'utils', 'settings_utils')
      
      @root_directory = root_directory

      @wss_settings_path = File.join(root_directory,'data','wss_settings.yml')
      # If the settings file does not exist, create it from defaults.
      unless File.file?(@wss_settings_path)
        FileUtils.cp(File.join(root_directory, 'data', 'default_wss_settings.yml'), @wss_settings_path)
      end
      @wss_settings = YAML.load(File.read(@wss_settings_path))

      # Set all WSSs to inactive
      for script in @wss_settings[:scripts]
        script[:active] = false
      end
      
      @wss_settings[:case] = SettingsUtils::CaseInformation.store_case_information(case_name, case_guid, root_directory).to_yaml_hash
    end

    # Enables the specified script, so that it is run during loading.
    # Params:
    # +script_identifier+:: The identifier of the script to enable.
    def enable_script(script_identifier)
      for script in @wss_settings[:scripts]
          .select { |script| script[:identifier] == script_identifier }
        script[:active] = false
      end
    end

    # Sets whether the specified script is enabled.
    # Params:
    # +script_identifier+:: The identifier of the script to enable/disable.
    # +enabled+:: Whether the script should be enabled.
    def set_enabled(script_identifier, enabled)
      for script in @wss_settings[:scripts]
          .select { |script| script[:identifier] == script_identifier }
        script[:active] = enabled
      end
    end

    # Returns whether the specified script is enabled.
    # Params:
    # +script_identifier+:: The script to check if is enabled.
    def scipt_enabled?(script_identifier)
      @wss_settings[:scripts].any? { |script| script[:identifier] == script_identifier && scipt[:active] }
    end

    # Returns a hash with information about the script.
    # Keys to the hash are: :identifier, :label:, :active.
    # Params:
    # +script_identifier+:: The script to get information about.
    def script_information(script_identifier)
      @wss_settings[:scripts].find { |script| script[:identifier] == script_identifier }
    end

    # Returns a list of the identifiers for all available scripts.
    def available_scripts
      @wss_settings[:scripts].map { |script| script[:identifier] }
    end

    # Writes the settings to file, generates a wss_caller and returns the wss_caller code.
    def setup
      # Write the new settings.
      File.open(@wss_settings_path, "w") { |file| file.write(@wss_settings.to_yaml) }

      generate_wss_caller
    end

    # Generates a wss_caller.
    def generate_wss_caller
      # Update wss_caller.rb with the new path.
      default_wss_caller_path = File.join(@root_directory, 'data', 'templates', 'wss_caller_template.rb')
      wss_caller_path = File.join(@root_directory, 'wss_caller.rb')
      default_wss_caller = File.read(default_wss_caller_path)
      root_directory_string = @root_directory.gsub(/\\/,'\\\\\\\\\\\\\\\\') # These are all necessary to make up for escaping.
      wss_caller = default_wss_caller.gsub(/PATH = '.*'/, "PATH = '" + root_directory_string + "'")
      File.open(wss_caller_path, "w") { |file| file.write(wss_caller) }
      wss_caller
    end
  end
end