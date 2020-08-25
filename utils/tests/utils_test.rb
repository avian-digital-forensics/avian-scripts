require 'test/unit'
require 'set'
require_relative '../utils'

class TestUtils < Test::Unit::TestCase
    def test_sets_disjoint_true
        set1 = Set[1,2,3,4]
        set2 = Set[5,6,7,8]
        set3 = Set[9,10,11,12]
        assert(Utils::sets_disjoint?(set1, set2, set3))
    end

    def test_sets_disjoint_false
        set1 = Set[1,2,3,4]
        set2 = Set[5,6,7,8]
        set3 = Set[9,10,2,12]
        assert(!Utils::sets_disjoint?(set1, set2, set3))
    end

    def test_sets_disjoint_arrays
        array1 = [1,2,3,4]
        array2 = [5,6,7,8]
        assert(Utils::sets_disjoint?(array1, array2))
    end

    def test_hyphenate_guid_do_nothing
        pre_guid = '023423b7-1568-4b1f-bbcb-aa809850c3f1'
        post_guid = Utils::add_hyphens_to_guid(pre_guid)
        assert(pre_guid == post_guid)
    end

    def test_hyphenate_guid_add_hyphens
        pre_guid = '023423b715684b1fbbcbaa809850c3f1'
        post_guid = Utils::add_hyphens_to_guid(pre_guid)
        assert(post_guid == '023423b7-1568-4b1f-bbcb-aa809850c3f1')
    end
end
