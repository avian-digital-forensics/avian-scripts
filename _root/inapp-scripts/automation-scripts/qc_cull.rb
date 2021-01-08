require 'json'

module QCCull
  extend self
  
  def run(nuix_case, utilities, settings_hash, progress_handler)
    root_directory = settings_hash[:root_directory]
    require File.join(root_directory, 'inapp-scripts', 'qc-cull', 'main')
    require File.join(root_directory,'utils','timer')

    timer = Timing::Timer.new
    timer.start('total')
    
    # If a scoping query is given, use that.
    scoping_query = settings_hash.key?(:scoping_query) ? settings_hash[:scoping_query] : ''
    
    qc_settings = {}
    qc_settings[:num_descendants_metadata_key] = settings_hash[:num_descendants_metadata_key]

    # Set up search and tag file paths.
    qc_search_and_tag_path = File.join(root_directory, 'misc', 'qc', 'qc_search_and_tag.json')
    culling_search_and_tag_path = File.join(root_directory, 'misc', 'qc', 'culling_search_and_tag.json')
    qc_settings[:search_and_tag_files] = [qc_search_and_tag_path, culling_search_and_tag_path]

    # Set up exclusion tag prefix hash.
    exclusion_sets_path = File.join(root_directory, 'misc', 'qc', 'exclusion_sets.json')
    qc_settings[:exclude_tag_prefixes] = JSON.parse(File.read(exclusion_sets_path))

    qc_settings[:report_path] = settings_hash[:report_path]

    QCCull::qc_cull(root_directory, nuix_case, utilities, progress_handler, timer, scoping_query, settings_hash, qc_settings)
    progress_handler.log_message("Script finished.")

    timer.stop('total')
  end
end
