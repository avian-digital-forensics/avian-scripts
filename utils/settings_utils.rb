require 'yaml'
require 'fileutils'

module SettingsUtils
    extend self
    
    # Holds information about a nuix case that can be saved to settings.
    class CaseInformation
        attr_accessor :guid, :name, :data_path
        
        class << self
            private :new
        end
        
        # Creates a new CaseInformation about the given case.
        def self.store_case_information(nuix_case, main_directory)
            case_information = new
            case_information.guid = nuix_case.guid
            case_information.name = nuix_case.name
            case_information.data_path = SettingsUtils::case_data_dir(main_directory, nuix_case)
            return case_information
        end
        
        # Creates a hash meant to be stored in yaml, that contains all the necessary information to recreate the case.
        def to_yaml_hash
            return {:guid => @guid, :name => @name, :data_path =>  @data_path}
        end
        
        # Loads case information from a hash.
        def self.from_yaml_hash(yaml_hash)
            case_information = new
            case_information.guid = yaml_hash[:guid]
            case_information.name = yaml_hash[:name]
            case_information.data_path = yaml_hash[:data_path]
            return case_information
        end
    end

    # Gets the data directory for the specified case.
    def case_data_dir(main_directory, current_case)
        case_guid = current_case.guid
        case_name = current_case.name
        
        dir_name = File.join(main_directory, "data", "cases", case_name)
        
        # If the directory already exists, check if it is the same case.
        if File.directory?(dir_name)
            dir_guid = File.read(File.join(dir_name, "guid.txt")).strip
            # If not, use a different directory.
            if dir_guid != case_guid
                dir_name = File.join(main_directory, "data", "cases", case_guid)
            end
        end
        # If the directory does not exist, create it and place the guid information inside.
        unless File.directory?(dir_name)
            FileUtils.mkdir_p(dir_name)
            file = File.open(File.join(dir_name, "guid.txt"), 'w')
            file.puts(case_guid)
            file.close
        end
        return dir_name
    end

    def inapp_script_settings_path(main_directory, script_name)
        default_settings_file = File.join(main_directory,'data','inapp-script-settings',"default_#{script_name}_settings.yml")
        settings_file = File.join(main_directory,'data','inapp-script-settings',"#{script_name}_settings.yml")

        # If the settings file does not exist, create it from defaults.
        unless File.file?(settings_file)
            FileUtils.cp(default_settings_file, settings_file)
        end
        return settings_file
    end

    def load_script_settings(main_directory, script_name)
        settings_file = inapp_script_settings_path(main_directory, script_name)

        settings = YAML.load(File.read(settings_file))
    end

    def save_script_settings(main_directory, script_name, yaml_hash)
        settings_file = inapp_script_settings_path(main_directory, script_name)

        # Write the settings.
        File.open(settings_file, "w") { |file| file.write(yaml_hash.to_yaml) }
    end

end