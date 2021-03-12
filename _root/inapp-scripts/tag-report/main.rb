require_relative '../qc-cull/search_and_tag'

module TagReport
    extend self

    def tag_report(nuix_case, utilities, progress_handler, timer, scoping_query, settings_hash)
        search_and_tag_file = settings_hash[:search_and_tag_file_path]
        # Perform search and tag.
        QCCull::search_and_tag(nuix_case, progress_handler, timer, [search_and_tag_file], scoping_query)
    end
end
