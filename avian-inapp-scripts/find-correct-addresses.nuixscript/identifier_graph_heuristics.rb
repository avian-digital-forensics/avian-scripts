def run_identifier_graph_heuristics(identifier_graph, heuristics_settings)
    if heuristics_settings[:isolate_highly_connected_vertices]
        for identifier,connections in identifier_graph
            if connections.size > heuristics_settings[:num_connections_for_isolation]
                identifier_graph.isolate_vertex(identifier)
            end
        end
    end
end