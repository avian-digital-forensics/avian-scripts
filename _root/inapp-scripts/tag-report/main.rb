require_relative File.join('..', 'qc-cull', 'search_and_tag')
require_relative File.join('..', 'qc-cull', 'report')
require_relative File.join('..', '..', 'utils', 'utils')
require 'json'

module TagReport
    extend self

    def tag_report(nuix_case, utilities, progress_handler, timer, scoping_query, settings_hash)
        root_directory = settings_hash[:root_directory]
        report_destination = settings_hash[:report_destination]
        search_and_tag_file = settings_hash[:search_and_tag_file_path]
        tag_prefix = settings_hash[:tag_prefix]
        tag_suffix = settings_hash[:tag_suffix]
        tag_prefix_length = tag_prefix.length
        tag_suffix_length = tag_suffix.length
        # Perform search and tag.
        QCCull::search_and_tag(nuix_case, progress_handler, timer, [search_and_tag_file], scoping_query)
        progress_handler.log_message('Counting tags...')
        tags = tags_in_search_and_tag(search_and_tag_file)
        tag_counts = {}
        
        for tag in tags
            tag_string = tag
            if tag_string.start_with?(tag_prefix)
                tag_string = tag_string[tag_prefix_length..-1]
            end
            if tag_string.end_with?(tag_suffix)
                tag_string = tag_string[0..-(tag_suffix_length+1)]
            end
            tag_counts[tag_string] = { :tag_count => nuix_case.count(Utils::join_queries("tag:\"#{tag}\"", scoping_query)) }
        end
        tag_count_string = QCCull::report_two_layer_hash(tag_counts, false)
        result_hash = {}
        result_hash['FIELD_tag_list'] = tag_count_string
        result_hash['FIELD_latest_revision'] = settings_hash[:latest_revision]
        result_hash['FIELD_collection_number'] = settings_hash[:collection_number]
        
        report_template_path = File.join(root_directory,'data','misc','tag_report','tag_report_template.rtf')
        # Copy report template.
        Utils::ensure_path_exists(File.expand_path(File.join(report_destination, '..')))
        FileUtils.cp(report_template_path, report_destination)
        # Update report with results.
        progress_handler.log_message('Creating report...')
        QCCull::update_report(result_hash, report_destination)
    end

    # Returns a list of the tags in the given search and tag file.
    # Params: 
    # +search_and_tag_file+:: The search and tag json file to get the tags in.
    def tags_in_search_and_tag(search_and_tag_file)
        search_and_tag_json = JSON.parse(File.read(search_and_tag_file))
        search_and_tag_json['tagAndQueries'].map { |tag_and_query| tag_and_query['tag'] }
    end
end
