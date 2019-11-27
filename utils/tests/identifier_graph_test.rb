require "test/unit"
require_relative '../identifier_graph'
require_relative './dummy_address'

class TestIdentifierGraph < Test::Unit::TestCase
    def test_add_identifier
        graph = IdentifierGraph::IdentifierGraph.new
        assert_raise(graph.add_identifier('test'))
    end

    def test_add_address
        graph = IdentifierGraph::IdentifierGraph.new
        address1 = DummyAddress.new('Alice', 'alice@ex.com')
        address2 = DummyAddress.new('Bob', 'bob@ex.com')
        address3 = DummyAddress.new('Alice', '/fmrio:984')
        graph.add_address(address1)
        graph.add_address(address2)
        graph.add_address(address3)
        # graph.assert() identifiers are connected
end