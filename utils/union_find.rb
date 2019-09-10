require 'set'
require 'csv'

module UnionFind
    # Implements the union find data structure.
    class UnionFind
        include Enumerable
        
        def initialize(elements)
            @elements = Set[]
            @parent = {}
            @tree_size = {}
            @num_components = 0
            for element in elements
                add_element(element)
            end
        end
        
        # Adds the specified element to the union find.
        def add_element(element)
            raise ArgumentError, 'Element may not be nil.' if element.nil?
            if @elements.add?(element)
                @parent[element] = element
                @tree_size[element] = 1
                @num_components += 1
            end
            return element
        end
        
        # Adds all the specified elements to the union find.
        # Equivalent to calling add_element for every element.
        def add_elements(elements)
            for element in elements
                add_element(element)
            end
        end
        
        # The current number of elements in the union find.
        def num_elements
            @elements.length
        end
        
        # The current number of unconnected components in the union find.
        def num_components
            @num_components
        end
        
        # Returns the representative of the specified element.
        # Fails if the element is not in the union find.
        def representative(element)
            raise IndexError, 'Element does not exist.' unless @elements.include?(element)
            if @parent[element] == element
                return element
            end
            @parent[element] = representative(@parent[element])
            return @parent[element]
        end
        
        # Whether the two elements are connected.
        def connected?(element1, element2)
            raise IndexError, 'Element1 does not exist.' unless @elements.include?(element1)
            raise IndexError, 'Element2 does not exist.' unless @elements.include?(element2)
            representative(element1) == representative(element2)
        end
        
        # Connects the two elements.
        # If the elements have equal size trees, connect element 2 to element 1.
        def union(element1, element2)
            raise IndexError, 'Element1 does not exist.' unless @elements.include?(element1)
            raise IndexError, 'Element2 does not exist.' unless @elements.include?(element2)
            rep1 = representative(element1)
            rep2 = representative(element2)
            
            if rep1 == rep2
                return nil
            end
            
            @num_components -= 1
            
            if @tree_size[rep1] >= @tree_size[rep2]
                @tree_size[rep1] += @tree_size[rep2]
                @parent[rep2] = rep1
                return rep1
            else
                @tree_size[rep2] += @tree_size[rep1]
                @parent[rep1] = rep2
                return rep2
            end
        end
            
        # Writes the union find to the specified CSV object to be loaded at a later point.
        # Meant to be used in conjunction with CSV methods like CSV.open("path/to/file.csv", "wb") do |csv|
        def to_csv(csv)
            components = to_component_hash
            for representative,elements in components
                csv << [representative] + elements.to_a
            end
        end
        
        # Loads a single row of CSV data into the union find.
        # Meant to be used in conjunction with CSV methods like CSV.foreach("path/to/file.csv", **options) do |row|
        def load_csv_row(csv_row)
            add_elements(csv_row)
            for element in csv_row[1..-1]
                union(csv_row[0],element)
            end
        end
        
        # Returns a hash with representatives as keys and lists of the elements they are representatives for as values.
        def to_component_hash
            components = {}
            for element in @elements
                if components.key?(representative(element))
                    if representative(element) != element
                        components[representative(element)] << element
                    end
                else
                    if representative(element) != element
                        components[representative(element)] = [element]
                    else
                        components[representative(element)] = []
                    end
                end
            end
            return components
        end
        
        # Implements Enumerable.each
        def each(&block)
            @elements.each{ |element| block.call(element) }
        end
    end
end