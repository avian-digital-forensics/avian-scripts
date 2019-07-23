require 'set'

# Implements the union find data structure.
class UnionFind
    def initialize(elements)
        @elements = Set[]
        @parent = {}
        @tree_size = {}
        @num_components = 0
        for element in elements
            add_element(element)
        end
    end
    
    def elements
        @elements
    end
    
    def add_element(element)
        raise ArgumentError, 'Element may not be nil.' unless not element.nil?
        if @elements.add?(element)
            @parent[element] = element
            @tree_size[element] = 1
            @num_components += 1
        end
        return element
    end
    
    def add_elements(elements)
        for element in elements
            add_element(element)
        end
    end
    
    def num_elements
        @elements.length
    end
    
    def num_components
        @num_components
    end
    
    def representative(element)
        raise IndexError, 'Element does not exist.' unless @elements.include?(element)
        if @parent[element] == element
            return element
        end
        @parent[element] = representative(@parent[element])
        return @parent[element]
    end
    
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
    
    # Creates a string representation of the union find with the representatives in the first column.
    def to_s
        components = {}
        for element in elements.select
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
        result = ""
        for rep in components.keys
            result += components[rep].reduce(prepare_for_save(rep)){ |total, element| total + ',' + prepare_for_save(element) } + ";"
        end
        return result.chomp(";")
    end
    
    # Adds all the information in the string to the union.
    def load(file)
        component_strings = split_to_strings(file, ';')
        
        for component_string in component_strings
            load_component(component_string)
        end
    end
    
    private
        def prepare_for_save(element)
            return '"' + element.gsub('"', '""') + '"'
        end
        
        def load_component(component_string)
            component_array = split_to_strings(component_string, ',').map{ |component| component[1..-2].gsub('""', '"') }
            puts("torsk: " + component_array[0])
            for element in component_array
                add_element(element)
                union(component_array[0], element)
            end
        end
        
        def split_to_strings(string, seperator)
            strings = [] 
            index = 0
            string_start = 0
            while index = string.index('"' + seperator + '"', index + 1)
                if string[index - 1] == '"'
                    next
                else
                    strings << string[string_start..index]
                    string_start = index + 2
                end
            end
            strings << string[string_start..-1]
            return strings
        end
end