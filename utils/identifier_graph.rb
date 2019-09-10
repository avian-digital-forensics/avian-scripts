require 'set'
require 'csv'

module IdentifierGraph
    # Represents a set of identifiers and infromation about which share and address.
    class IdentifierGraph
        include Enumerable
    
        # Initializes an empty graph.
        def initialize
            @graph = {}
        end
        
        # Returns all identifiers directly connected to the index.
        def [](identifier)
            return @graph[identifier]
        end
        
        # If given one argument, will add the given identifier with an empty set of connected identifiers.
        # If given two arguments, will add the given identifier with the given list of connected identifiers.
        def add_identifier(*args)
            if @graph.key?(args[0])
                raise "Identifier already in graph"
            end
            case args.size
                when 1
                    @graph[args[0]] = Set[]
                when 2
                    @graph[args[0]] = args[1].to_set
            end
        end
        
        def ensure_identifier(identifier)
            unless @graph.key?(identifier)
                add_identifier(identifier)
            end
        end
        
        # Connects the two specified identifiers.
        def connect_identifiers(identifier1, identifier2)
            unless @graph.key?(identifier1)
                add_identifier(identifier1)
            end
            unless @graph.key?(identifier2)
                add_identifier(identifier2)
            end
            @graph[identifier1] << identifier2
            @graph[identifier2] << identifier1
        end
        
        # Adds the specified communication address and connects the personal and address parts.
        def add_address(address)
            if address.personal
                ensure_identifier(address.personal)
            end
            if address.address
                ensure_identifier(address.address)
            end
            if address.personal and address.address # Only union the two identifiers if they both exist.
                connect_identifiers(address.personal, address.address)
            end
        end
        
        # Writes the graph to the specified csv object to be loaded at a later point.
        # Meant to be used in conjunction with CSV methods like CSV.open("path/to/file.csv", "wb") do |csv|
        def to_csv(csv)
            for identifier,values in @graph
                csv << [identifier] + values.to_a
            end
        end
        
        # Loads a single CSV row into the graph.
        # Meant to be used in conjunction with CSV methods like CSV.foreach("path/to/file.csv", **options) do |row|
        def load_csv_row(csv_row)
            add_identifier(csv_row[0], csv_row[1..-1])
        end
        
        def to_union_find
            union_find = UnionFind::UnionFind.new(@graph.keys)
            for identifier,values in @graph
                for connection in values
                    union_find.union(identifier, connection)
                end
            end
            return union_find
        end
        
        def each &block
            @graph.each{ |key, value| block.call(key, value) }
        end
    end
end