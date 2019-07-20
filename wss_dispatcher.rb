SCRIPT_PATHS = [ # The available scripts. Add new scripts here.
        "WSS/email-address-fixer/email_address_fixer.rb"
].freeze

# Represents a worker side script.
# Contains information about the file path and aliases.
class WSS
    def initialize(file_path, aliases = [])
        @file_path = file_path
        @aliases = aliases
        @script_name = @file_path[(@file_path.rindex('/') + 1)..-1]
        @aliases << @script_name
        @aliases = @aliases.map{ |string| transform_string(string) }
        @aliases.uniq!
        
        @module_name = find_module_name(@script_name)
        
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
    
    def require(root_path)
        require (root_path + "/WSS/" + @file_path.chomp(".rb"))
    end
    
    def run_init(wss_global)
        if @module.method_defined? :run_init
            @module.run_init
        end
        return
    end
    
    def run(wss_global, worker_item)
        if @module.method_defined? :run
            @module.run(worker_item)
        end
        return
    end
    
    def run_close(wss_global)
        if @module.method_defined? :run_close
            @module.run_close
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

class WWSGlobal
    attr_reader :root_path
    attr_reader :script_names
    attr_reader :available_scripts
    attr_reader :run_scripts
    # A hash any script can use to store data.
    attr_reader :vars
    
    def initialize(root_path, script_names)
        @root_path = root_path
        @script_names = script_names
        
        # Create WWSs from all script paths.
        @available_scripts = SCRIPT_PATHS.map{ |path| WWS.new(path) }
    
        # Finds the scripts matching the script names.
        @run_scripts = []
        for script_name in @script_names 
            script = find_script(script_name, @available_scripts)
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
        return @available_scripts.find{ |script| script.match?(string) }
end

def run_init(root_path, script_names)
    @wss_global = WSSGlobal.new(root_path, script_names).freeze
    for script in @wss_global.run_scripts
        script.require(root_path)
        script.run_init(@wss_global)
    end
end

def run(worker_item)
    for script in run_scripts
        script.run(@wss_global)
    end
end

def run_close
    for script in run_scripts
        script.run_close(@wss_global)
    end
end