require 'test/unit'
require_relative 'test_utils'
require_relative '../union_find'

class TestUnionFind < Test::Unit::TestCase
    def setup_union_find(num_elements)
        union_find = UnionFind::UnionFind.new((1..num_elements).to_a)
        return union_find
    end

    def test_num_elements
        for i in 1..10
            num = rand(1..100)
            union_find = setup_union_find(num)
            assert_equal(num, union_find.num_elements)
        end
    end

    def test_representative
        union_find = setup_union_find(9)
        assert_nothing_raised {assert_equal(5, union_find.representative(5))}
        assert_raise {union_find.representative('joy')}
    end

    def test_add_element
        union_find = setup_union_find(9)
        assert_raise {union_find.add_element(nil)}
        union_find.add_element('cake')
        assert_nothing_raised {assert_equal('cake', union_find.representative('cake'))}
    end

    def test_union
        union_find = setup_union_find(9)
        union_find.union(1,2)
        union_find.union(3,4)
        union_find.union(4,1)
        assert_equal_many((1..4).to_a.map { |i| union_find.representative(i) })
        assert_not_equal(union_find.representative(1), union_find.representative(5))
        assert_raise {union_find.union(5, 'happiness')}
    end

    def test_num_components
        union_find = setup_union_find(9)
        union_find.union(1,2)
        union_find.union(3,4)
        union_find.union(4,6)
        assert_equal(6, union_find.num_components)
    end

    def test_connected?
        union_find = setup_union_find(9)
        assert(!union_find.connected?(1,5))
        union_find.union(1,2)
        union_find.union(2,3)
        union_find.union(5,6)
        union_find.union(7,8)
        union_find.union(8,5)
        assert(union_find.connected?(1,2))
        assert(union_find.connected?(1,3))
        assert(union_find.connected?(5,7))
        assert(union_find.connected?(6,7))
    end

    def test_to_component_hash
        union_find = setup_union_find(9)
        union_find.union(1,2)
        union_find.union(2,3)
        union_find.union(5,6)
        union_find.union(7,8)
        union_find.union(8,5)
        hash = union_find.to_component_hash
        assert(hash[union_find.representative(1)].include?(2) || union_find.representative(1) == 2)
        assert(hash[union_find.representative(3)].include?(3) || union_find.representative(3) == 3)
        assert(hash[union_find.representative(3)].include?(1) || union_find.representative(3) == 1)
        assert(hash[union_find.representative(5)].include?(7) || union_find.representative(5) == 7)
        assert(hash[union_find.representative(6)].include?(7) || union_find.representative(6) == 7)
        assert(!hash[union_find.representative(6)].include?(4))
    end

    def test_csv
        union_find = setup_union_find(9)
        union_find.union(1,2)
        union_find.union(2,3)
        union_find.union(5,6)
        union_find.union(7,8)
        union_find.union(8,5)
        CSV.open('test_data/union_find_output.csv', 'wb') do |csv|
            union_find.to_csv(csv)
        end

        loaded_union_find = UnionFind::UnionFind.new([])
        CSV.foreach('test_data/union_find_output.csv') do |row|
            loaded_union_find.load_csv_row(row)
        end
        File.delete('test_data/union_find_output.csv') if File.exists?('test_data/union_find_output.csv')
        hash = union_find.to_component_hash
        assert(hash[union_find.representative(1)].include?(2) || union_find.representative(1) == 2)
        assert(hash[union_find.representative(3)].include?(3) || union_find.representative(3) == 3)
        assert(hash[union_find.representative(3)].include?(1) || union_find.representative(3) == 1)
        assert(hash[union_find.representative(5)].include?(7) || union_find.representative(5) == 7)
        assert(hash[union_find.representative(6)].include?(7) || union_find.representative(6) == 7)
        assert(!hash[union_find.representative(6)].include?(4))
    end
end
