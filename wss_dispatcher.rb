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
    
    def run(worker_item)
        Object.const_get(@module_name).run(worker_item)
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

# Find a script that matches the given name.
def find_script(string, available_scripts)
    return available_scripts.find{ |script| script.match?(string) }
end

# Runs all scripts specified in script_names on worker_item.
def dispatch_scripts(root_path, script_names, worker_item)
    root_path.gsub!('\\', '/')

    available_scripts = [ # The available scripts. Add new scripts here.
        WSS.new("email-address-fixer/email_address_fixer.rb")
    ]
    
    # Finds the scripts matching the script names.
    run_scripts = []
    for script_name in script_names 
        script = find_script(script_name, available_scripts)
        if script.nil?
            STDERR.puts("Could not find script matching name '" + script_name + "'.")
        else
            run_scripts << script
        end
    end
    
    # Require the scripts to run.
    for script in run_scripts.uniq
        require (root_path + "/WSS/" + script.file_path.chomp(".rb"))
    end
    # Run all the scripts.
    for script in run_scripts
        puts("Running script: " + script.script_name)
        script.run(worker_item)
    end
end
