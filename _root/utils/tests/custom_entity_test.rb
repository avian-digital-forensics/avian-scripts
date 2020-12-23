require "test/unit"
require_relative '../custom_entity'

class TestCustomEntity < Test::Unit::TestCase
    def test_init
        entity = CustomEntity::CustomEntity.new('CustomTest', 'Test', 5)
        assert_equal(entity.entity_type, 'CustomTest')
        assert_equal(entity.entity_name, 'Test')
        assert_equal(entity.amount, 5)
    end
end
