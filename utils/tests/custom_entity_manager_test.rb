require "test/unit"
require_relative '../custom_entity'
require_relative '../custom_entity_manager'

class TestCustomEntityManager < Test::Unit::TestCase
    def test_entities_for_item
        entities = CustomEntityManager::CustomEntityManager.new
        guid1 = 'asdf'
        entity1 = CustomEntity::CustomEntity.new('CustomTest', 'Test1', 3)
        entities.add_entity(guid1, entity1)
        assert_equal(1,entities.entities_for_item(guid1))
        assert_equal(0,entities.entities_for_item('asdf5'))
    end

    def test_add_entity
        entities = CustomEntityManager::CustomEntityManager.new
        guid1 = 'asdf1'
        guid2 = 'asdf2'
        entity1 = CustomEntity::CustomEntity.new('CustomTest', 'Test1', 3)
        entity2 = CustomEntity::CustomEntity.new('CustomTest', 'Test2', 3)
        entities.add_entity(guid1, entity1)
        entities.add_entity(guid1, entity2)
        entities.add_entity(guid2, entity2)
        assert_equal(2,entities.num_items)
        assert(entities.entities_for_item(guid1).include?(entity1))
        assert(entities.entities_for_item(guid1).include?(entity2))
        assert(entities.entities_for_item(guid2).include?(entity2))
        assert(!entities.entities_for_item(guid2).include?(entity1))
    end
end
