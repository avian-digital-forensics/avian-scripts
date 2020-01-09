require "test/unit"
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

    def test_add_element
        union_find = setup_union_find(9)
        assert_raise {union_find.add_element(nil)}
        union_find.add_element('cake')
        assert_nothing_raised {assert_equal('cake', union_find.representative('cake'))}
    end
end
