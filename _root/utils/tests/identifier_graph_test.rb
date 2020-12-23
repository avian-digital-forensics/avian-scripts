require "test/unit"
require_relative '../identifier_graph'
require_relative './dummy_address'

class TestIdentifierGraph < Test::Unit::TestCase
    def setup_graph
        graph = IdentifierGraph::IdentifierGraph.new
        address1 = DummyAddress.new('Alice', 'alice@ex.com')
        address2 = DummyAddress.new('Bob', 'bob@ex.com')
        address3 = DummyAddress.new('Alice', '/fmrio:984')
        graph.add_address(address1)
        graph.add_address(address2)
        graph.add_address(address3)
        return graph
    end

    def test_add_address
        graph = setup_graph
        assert_equal(2, graph.num_connected_identifiers('Alice'))
        assert_equal(1, graph.num_connected_identifiers('Bob'))
        assert_raise {graph.num_connected_identifiers('Charlie')}
        # graph.assert() identifiers are connected
    end

    def test_isolate_vertex1
        graph = setup_graph
        graph.isolate_vertex('Alice')
        assert_equal(0, graph.num_connected_identifiers('Alice'))
        assert_equal(0, graph.num_connected_identifiers('alice@ex.com'))
        assert_equal(1, graph.num_connected_identifiers('Bob'))
        assert_raise {graph.isolate_vertex('Charlie')}
        # graph.assert() identifiers are connected
    end

    def test_isolate_vertex2
        graph = setup_graph
        graph.isolate_vertex('alice@ex.com')
        assert_equal(1, graph.num_connected_identifiers('Alice'))
        assert_equal(0, graph.num_connected_identifiers('alice@ex.com'))
        assert_equal(1, graph.num_connected_identifiers('Bob'))
        # graph.assert() identifiers are connected
    end

    def test_connect_identifiers
        graph = setup_graph
        graph.connect_identifiers('alice@ex.com', 'Bob')
        assert_equal(2, graph.num_connected_identifiers('Alice'))
        assert_equal(2, graph.num_connected_identifiers('alice@ex.com'))
        assert_equal(2, graph.num_connected_identifiers('Bob'))
        assert_equal(1, graph.num_connected_identifiers('bob@ex.com'))
        # graph.assert() identifiers are connected
    end

    def test_connect_identifiers_new_identifier
        graph = setup_graph
        graph.connect_identifiers('alice@ex.com', 'Charlie')
        assert_equal(2, graph.num_connected_identifiers('Alice'))
        assert_equal(2, graph.num_connected_identifiers('alice@ex.com'))
        assert_equal(1, graph.num_connected_identifiers('Bob'))
        assert_equal(1, graph.num_connected_identifiers('bob@ex.com'))
        assert_equal(1, graph.num_connected_identifiers('Charlie'))
        # graph.assert() identifiers are connected
    end

    def test_csv
        graph = IdentifierGraph::IdentifierGraph.new
        graph = setup_graph
        CSV.open('test_data/identifier_graph_output.csv', 'wb') do |csv|
            graph.to_csv(csv)
        end

        loaded_graph = IdentifierGraph::IdentifierGraph.new
        CSV.foreach("test_data/identifier_graph_output.csv") do |row|
            loaded_graph.load_csv_row(row)
        end

        graph.each do |key, value|
            assert_equal(graph.num_connected_identifiers(key), loaded_graph.num_connected_identifiers(key))
        end
        File.delete('test_data/identifier_graph_output.csv') if File.exists?('test_data/identifier_graph_output.csv')
    end
end
