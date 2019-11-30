def run_identifier_graph_heuristics(identifier_graph, heuristics_settings)
    if heuristics_settings[:isolate_highly_connected_vertices]
        for identifier,connections in identifier_graph
            if connections.size > heuristics_settings[:num_connections_for_isolation]
                identifier_graph.isolate_vertex(identifier)
            end
        end
    end
end

def run_person_heuristics(person_manager, heuristics_settings)
    if heuristics_settings[:flag_persons_with_multiple_emails_with_domain]
        for person in person_manager
            domains = Set[]
            for domain in person.email_addresses.map(&:email_address_domain)
                unless domains.add?(domain)
                    person.flag
                end
            end
        end
    end
end           

def email_address_domain(email_address)
    email_address.split('@')[1]
end