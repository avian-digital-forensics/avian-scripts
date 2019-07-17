require 'set'

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
    
    def add_element(element)
        if @elements.add?(element)
            @parent[element] = element
            @tree_size[element] = 1
            @num_components += 1
        end
        return element
    end
    
    def num_elements
        @elements.length
    end
    
    def num_components
        @num_components
    end
    
    def representative(element)
        if @parent[element] == element
            return element
        end
        @parent[element] = representative(@parent[element])
        return @parent[element]
    end
    
    def connected?(element1, element2)
        representative(element1) == representative(element2)
    end
    
    def union(element1, element2)
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
end


    

puts("Running script...")

messages = currentCase.search("has-communication:1")

puts("Found: " + messages.length.to_s + " items with communication.")

