require 'set'

script_directory = File.dirname(__FILE__)
require File.join(script_directory,"..","setup.nuixscript","get_main_directory")
main_directory = get_main_directory(false)

require File.join(main_directory,"utils","union_find")

# Returns a list of all the addresses in the communication of the item if such exists.
def all_addresses_in_item(item)
    communication = item.communication
    result = Set[]
    if communication
        if communication.from
            result.merge(communication.from)
        end
        if communication.to
            result.merge(communication.to)
        end
        if communication.cc
            result.merge(communication.cc)
        end
        if communication.bcc
            result.merge(communication.bcc)
        end
    end
    return result
end

puts("Running script...")

# The output directory.
output_dir = File.join(main_directory, "data")

# Find all items with a communication.
messages = currentCase.search("has-communication:1")

puts("Found: " + messages.length.to_s + " items with communication.")

# Initialize the union find.
identifiers = UnionFind.new([])

# Add all addresses to the union find.
for message in messages
    for address in all_addresses_in_item(message)
        if address.personal
            identifiers.add_element(address.personal)
        end
        if address.address
            identifiers.add_element(address.address)
        end
        if address.personal and address.address # Only union the two identifiers if they both exist.
            identifiers.union(address.personal, address.address)
        end
    end
end

puts("Found " + identifiers.num_components.to_s + " unique persons.")

puts("Writing output to file...")
output_file_path = File.join(output_dir,"find_correct_addresses_output.txt")
file = File.open(output_file_path, 'w')
file.puts(identifiers.to_s)
file.close

puts("Script finished.")
