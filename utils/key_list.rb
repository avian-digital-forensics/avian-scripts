java_import "java.util.regex.Pattern"
class EntityKeyList
    attr_accessor :entity_type, :entity_name, :key_list, :pattern

    def initialize(entity_type, entity_name, key_list)
        @entity_type = entity_type
        @entity_name = entity_name
        @key_list = key_list
        @pattern = Pattern.compile(key_list.join("|"))
    end
end
    