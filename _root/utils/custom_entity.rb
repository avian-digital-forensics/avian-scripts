module CustomEntity
    class CustomEntity

        attr_accessor :entity_type, :entity_name, :amount

        def initialize(type, name, amount)
            @entity_type = type
            @entity_name = name
            @amount = amount
        end
    end
end
