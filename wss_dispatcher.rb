require 'yaml'

SCRIPT_PATHS = [ # The available scripts. Add new scripts here.
        "WSS/fix-from-addresses/fix_from_addresses.rb",
        "WSS/entities-from-lists/entities_from_lists.rb"
].freeze

# Represents a worker side script.
# Contains information about the file path and aliases.
class WSS
    def initialize(root_path, file_path, aliases = [])
        @file_path = file_path
        @aliases = aliases
        @script_name = @file_path[(@file_path.rindex('/') + 1)..-1]
        @aliases << @script_name
        @aliases = @aliases.map{ |string| transform_string(string) }
        @aliases.uniq!
        
        @module_name = find_module_name(@script_name)
        require (root_path + "/" + @file_path.chomp(".rb"))
        @module = Object.const_get(@module_name)
    end
    
    def file_path
        @file_path
    end
    
    def aliases
        @aliases
    end
    
    def script_name
        @script_name
    end
    
    def module_name
        @module_name
    end
    
    def match?(string)
        return @aliases.include?(transform_string(string))
    end
    
    def run_init(wss_global)
        if @module.method_defined? :run_init
            @module.run_init(wss_global)
        end
        return
    end
    
    def run(wss_global, worker_item)
        if @module.method_defined? :run
            @module.run(wss_global, worker_item)
        end
        return
    end
    
    def run_close(wss_global)
        if @module.method_defined? :run_close
            @module.run_close(wss_global)
        end
        return
    end
    
    private
        # Transform a wss name into alias form: no spaces or underscores, all lowercase.
        def transform_string(string)
            return string.gsub(" ", "").gsub("_", "").chomp(".rb").downcase
        end
        
        # Converts a script name to a module name.
        def find_module_name(script_name)
            module_name = ""
            capitalize = true
            for i in 0..script_name.length-1
                if script_name[i] == '_'
                    capitalize = true
                elsif capitalize
                    capitalize = false
                    module_name += script_name[i].capitalize
                else
                    module_name += script_name[i]
                end
            end
            return module_name.chomp(".rb")
        end
end

# Holds data across scripts and items.
class WSSGlobal
    # The avian scripts root directory.
    attr_reader :root_path
    # The directory for current-case-specific data.
    attr_reader :case_data_path
    # The objects representing all available scripts.
    attr_reader :available_scripts
    # The scripts that will be run.
    attr_reader :run_scripts
    # A hash any script can use to store data.
    attr_reader :vars
    # The wss settings object loaded from data/wss_settings.yml.
    attr_reader :wss_settings
    
    def initialize(root_path)
        @root_path = root_path
        
        # Create WSSs from all script paths.
        @available_scripts = SCRIPT_PATHS.map{ |script_path| WSS.new(root_path, script_path) }
        
        wss_settings_path = File.join(root_path, "data", "wss_settings.yml")
        if not File.file?(wss_settings_path)
            STDERR.puts("Could not find Avian scripts WSS settings file. Have you remembered to run 'Setup WSS's?")
        end
        @wss_settings = YAML.load(File.read(wss_settings_path))
        
        @case_data_path = @wss_settings[:case][:data_path]
        
        run_script_names = @wss_settings[:scripts].select{ |script| script[:active] }.map{ |script| script[:identifier] }
        
        # Finds the scripts matching the script names.
        @run_scripts = []
        for script_name in run_script_names
            script = find_script(script_name)
            if script.nil?
                STDERR.puts("Could not find script matching name '" + script_name + "'.")
            else
                @run_scripts << script
            end
        end
        
        @vars = {}
    end
    
    # Find a script that matches the given name.
    def find_script(script_name)
        return @available_scripts.find{ |script| script.match?(script_name) }
    end
end

def run_init(root_path)
    puts('Starting WSS setup...')
    @wss_global = WSSGlobal.new(root_path).freeze
    for script in @wss_global.run_scripts
        puts('Setting up WSS "' + script.script_name.chomp(".rb") + "'.")
        script.run_init(@wss_global)
    end
    puts('WSS setup finished. Case name is "' + @wss_global.wss_settings[:case][:name] + '".')
end

def run(worker_item)
    for script in @wss_global.run_scripts
        script.run(@wss_global, worker_item)
    end
end

def run_close
    for script in @wss_global.run_scripts
        script.run_close(@wss_global)
    end
end