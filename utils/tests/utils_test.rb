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
