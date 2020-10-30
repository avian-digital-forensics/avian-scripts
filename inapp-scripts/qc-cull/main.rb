require_relative 'culling'
require_relative 'report'
require_relative 'search_and_tag'
require_relative '../number-of-descendants/number_of_descendants'

module QCCull
  extend self

  def qc_cull(main_directory, nuix_case, utilities, progress_handler, timer, scoping_query, settings_hash, report_info_hash)
    num_descendants_metadata_key = settings_hash[:num_descendants_metadata_key]
    search_and_tag_files = settings_hash[:search_and_tag_files]
    exclude_tag_prefixes = settings_hash[:exclude_tag_prefixes]
    report_path = settings_hash[:report_path]
  
    # Number of Descendants.
    items = nuix_case.search(scoping_query)
    bulk_annotater = utilities.get_bulk_annotater
    NumberOfDescendants::number_of_descendants(current_case, progress_handler, timer, items, num_descendants_metadata_key, bulk_annotater)

    # Search and Tag. Both QC and culling.
    # Skipped if no .json file is specified.
    if search_and_tag_files.any?
      QCCull::search_and_tag(current_case, progress_handler, timer, search_and_tag_files, scoping_query)
    else
      progress_handler.log_message('Skipping search and tag since no files were selected.')
    end

    # Culling.
    if exclude_tag_prefixes.any?
      QCCull::exclude_items(current_case, scoping_query, exclude_tag_prefixes, progress_handler, timer, utilities)
    else
      progress_handler.log_message('Skipping exclude because no exclude tag prefixes were specified.')
    end

    # Report.
    progress_handler.set_main_status_and_log_it('Generating report...')
    # Find report template.
    report_template_path = File.join(main_directory,'data','misc','qc','qc_report_template.rtf')
    # Generate report.
    QCCull::generate_report(current_case, report_template_path, report_path, report_info_hash, utilities)]
  end
end
