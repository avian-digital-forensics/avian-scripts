require_relative 'culling'
require_relative 'report'
require_relative 'search_and_tag'
require_relative '../number-of-descendants/number_of_descendants'
require_relative '../../utils/utils'

module QCCull
  extend self

  def qc_cull(root_directory, nuix_case, utilities, progress_handler, timer, scoping_query, settings_hash, report_info_hash)
    num_descendants_metadata_key = settings_hash[:num_descendants_metadata_key]
    search_and_tag_files = settings_hash[:search_and_tag_files]
    exclude_tag_prefixes = settings_hash[:exclude_tag_prefixes]
    report_path = settings_hash[:report_path]
    existing_qc_handling = settings_hash[:existing_qc_handling]

    prev_qc_items = QCCull::check_for_items_with_qc_tags(nuix_case, progress_handler, timer, scoping_query).to_a
    prev_culled_items = QCCull::find_culled_items(nuix_case, progress_handler, timer, scoping_query, exclude_tag_prefixes).to_a
    items_with_qc_metadata = prev_qc_items + prev_culled_items

    cancel_qc = false
    has_previous_metadata_tag = 'Avian|QC|HasPrevQCMetadata'
    if prev_qc_items.empty? && prev_culled_items.empty?
      progress_handler.log_message('No items with previous QC metadata found.')
    else
      progress_handler.log_message('Items with previous QC metadata found.')
      case existing_qc_handling
      when :remove_metadata
        progress_handler.set_main_status_and_log_it("Removing found QC metadata in accordance with chosen handling method '#{existing_qc_handling}'...")
        QCCull::remove_qc_tags(nuix_case, utilities, progress_handler, timer, scoping_query)
        Utils::bulk_include(utilities, progress_handler, prev_culled_items)
      when :exclude_from_qc
        progress_handler.set_main_status_and_log_it("Excluding items with QC metadata from further QC in accordance with chosen handling method '#{existing_qc_handling}'...")
        Utils::bulk_add_tag(utilities, progress_handler, has_previous_metadata_tag, items_with_qc_metadata)
        scoping_query = Utils::join_queries(scoping_query, "NOT #{Utils::create_tag_query(has_previous_metadata_tag)}")
      when :tag_items_and_cancel_script
        progress_handler.set_main_status_and_log_it("Tagging items with QC metadata and cancelling QC in accordance with chosen handling method '#{existing_qc_handling}'...")
        Utils::bulk_add_tag(utilities, progress_handler, has_previous_metadata_tag, items_with_qc_metadata)
        cancel_qc = true
      when :ignore
        progress_handler.set_main_status_and_log_it("Continuing as usual in accordance with chosen handling method '#{existing_qc_handling}'...")
      end
    end
  
    unless cancel_qc
      # Number of Descendants.
      items = nuix_case.search(scoping_query)
      bulk_annotater = utilities.get_bulk_annotater
      NumberOfDescendants::number_of_descendants(nuix_case, progress_handler, timer, items, num_descendants_metadata_key, bulk_annotater)

      # Search and Tag. Both QC and culling.
      # Skipped if no .json file is specified.
      if search_and_tag_files.any?
        QCCull::search_and_tag(nuix_case, progress_handler, timer, search_and_tag_files, scoping_query)
      else
        progress_handler.log_message('Skipping search and tag since no files were selected.')
      end

      # Culling.
      if exclude_tag_prefixes.any?
        QCCull::exclude_items(nuix_case, scoping_query, exclude_tag_prefixes, progress_handler, timer, utilities)
      else
        progress_handler.log_message('Skipping exclude because no exclude tag prefixes were specified.')
      end

      # Report.
      progress_handler.set_main_status_and_log_it('Generating report...')
      # Find report template.
      report_template_path = File.join(root_directory,'data','misc','qc','qc_report_template.rtf')
      report_settings = { 
        :num_source_files_provided => settings_hash[:num_source_files_provided],
        :scoping_query => scoping_query,
        :date_format => settings_hash[:date_format]
      }
      # Generate report.
      QCCull::generate_report(nuix_case, report_template_path, report_path, report_info_hash, report_settings, utilities)
    end
  end
end
