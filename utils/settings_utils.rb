require 'fileutils'

# Gets the data directory for the specified case.
def case_data_dir(main_directory, current_case)
    case_guid = current_case.guid
    case_name = current_case.name
    
    dir_name = File.join(main_directory, "data", "cases", case_name)
    
    # If the directory already exists, check if it is the same case.
    if File.directory?(dir_name)
        dir_guid = File.read(File.join(dir_name, "guid.txt"))
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