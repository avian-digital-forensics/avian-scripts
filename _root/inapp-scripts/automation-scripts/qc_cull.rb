require 'json'

module QcCull
  extend self
  
  def run(nuix_case, utilities, settings_hash, progress_handler)
    root_directory = settings_hash[:root_directory]
    require File.join(root_directory, 'inapp-scripts', 'qc-cull', 'main')
    require File.join(root_directory,'utils','timer')

    timer = Timing::Timer.new
    timer.start('total')
    
    # If a scoping query is given, use that.
    scoping_query = settings_hash.key?(:scoping_query) ? settings_hash[:scoping_query] : ''

    qc_settings[:existing_qc_handling] = settings_hash[:existing_qc_handling]
    
    qc_settings = {}
    qc_settings[:num_descendants_metadata_key] = settings_hash[:num_descendants_metadata_key]
    qc_settings[:num_source_files_provided] = settings_hash[:num_source_files_provided]

    qc_settings[:date_format] = settings_hash.key?(:date_format) ? settings_hash[:date_format] : '%d/%m/%Y'

    qc_settings[:run_number_of_descendants] = settings_hash.key?(:run_number_of_descendants) ? settings_hash[:run_number_of_descendants] : true
    qc_settings[:run_search_and_tag] = settings_hash.key?(:run_search_and_tag) ? settings_hash[:run_search_and_tag] : true
    qc_settings[:run_culling] = settings_hash.key?(:run_culling) ? settings_hash[:run_culling] : true
    qc_settings[:run_create_report] = settings_hash.key?(:run_create_report) ? settings_hash[:run_create_report] : true

    # Set up search and tag file paths.
    qc_settings[:search_and_tag_files] = []
    qc_search_and_tag_path = File.join(root_directory, 'data', 'misc', 'qc', 'qc_search_and_tag.json')
    culling_search_and_tag_path = File.join(root_directory, 'data', 'misc', 'qc', 'culling_search_and_tag.json')
    qc_settings[:search_and_tag_files] += [qc_search_and_tag_path, culling_search_and_tag_path]
    # If NSRL is turned on, add the search and tag file.
    if settings_hash.key?(:nsrl) && settings_hash[:nsrl]
      qc_settings[:search_and_tag_files] << File.join(root_directory, 'data', 'misc', 'qc', 'nsrl_search_and_tag.json')
    end

    # Set up exclusion tag prefix hash.
    exclusion_sets_path = File.join(root_directory, 'data', 'misc', 'qc', 'exclusion_sets.json')
    qc_settings[:exclude_tag_prefixes] = JSON.parse(File.read(exclusion_sets_path))

    qc_settings[:report_path] = settings_hash[:report_path]
    qc_settings[:spreadsheet_report_path] = settings_hash[:spreadsheet_report_path]

    # Get QC report information.
    # Create a hash with information for the report.
    qc_report_info = {}
    for key,value in settings_hash
      if key.to_s.start_with?('info_')
        qc_report_info[key[5..-1]] = value
      end
    end

    QCCull::qc_cull(root_directory, nuix_case, utilities, progress_handler, timer, scoping_query, qc_settings, qc_report_info)
    progress_handler.log_message("Script finished.")

    timer.stop('total')
  end
end
