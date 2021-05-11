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
    exclusion_sets = settings_hash[:exclusion_sets]
    report_path = settings_hash[:report_path]
    spreadsheet_report_path = settings_hash[:spreadsheet_report_path]
    existing_qc_handling = settings_hash[:existing_qc_handling]

    run_number_of_descendants = settings_hash[:run_number_of_descendants] 
    run_search_and_tag = settings_hash[:run_search_and_tag]
    run_culling = settings_hash[:run_culling]
    run_create_report = settings_hash[:run_create_report]


    cancel_qc = false
    if existing_qc_handling != :ignore
      prev_qc_items = QCCull::check_for_items_with_qc_tags(nuix_case, progress_handler, timer, scoping_query).to_a
      prev_culled_items = QCCull::find_culled_items(nuix_case, progress_handler, timer, scoping_query, exclusion_sets).to_a
      items_with_qc_metadata = prev_qc_items + prev_culled_items

      has_previous_metadata_tag = 'Avian|QC|HasPrevQCMetadata'
      if prev_qc_items.empty? && prev_culled_items.empty?
        progress_handler.log_message('No items with previous QC metadata found.')
      else
        progress_handler.log_message('Items with previous QC metadata found.')
        case existing_qc_handling
        when :clean
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
          raise 'Code should never get here.'
        else
          raise "Invalid value for 'existing_qc_handling' in config: #{existing_qc_handling}"
        end
      end
    end
  
    unless cancel_qc
      # Number of Descendants.
      if run_number_of_descendants
        container_query = 'kind:container NOT ( mime-type:filesystem/directory or text/calendar OR text/calendar-entry OR mime-type:application/java-archive OR mime-type:application/macbinary OR mime-type:application/vnd.ms-cab-compressed or mime-type:application/vnd.ms-installer OR mime-type:application/vnd.ms-mso OR mime-type:application/vnd.ms-ole10native-wrapper OR mime-type:application/vnd.ms-ole2-attachment OR mime-type:application/vnd.ms-ole2-clipboard OR mime-type:application/vnd.ms-onenote-toc OR mime-type:application/vnd.ms-outlook-folder OR mime-type:application/vnd.ms-photo-editor OR mime-type:application/vnd.ms-shell-scrap OR mime-type:application/x-self-extracting-archive OR mime-type:application/vnd.symantec-vault-stream-data OR mime-type:application/x-thumbs-db OR mime-type:application/vnd.ms-clipart-gallery )'
        number_of_descendants_items = nuix_case.search(Utils::join_queries(scoping_query, container_query))
        bulk_annotater = utilities.get_bulk_annotater
        NumberOfDescendants::number_of_descendants(nuix_case, progress_handler, timer, number_of_descendants_items, num_descendants_metadata_key, bulk_annotater)
      else
        progress_handler.log_message('Skipping number of descendants as specified in config.')
      end

      # Search and Tag. Both QC and culling.
      # Skipped if no .json file is specified.
      if run_search_and_tag
        if search_and_tag_files.any?
          QCCull::search_and_tag(nuix_case, progress_handler, timer, search_and_tag_files, scoping_query)
        else
          progress_handler.log_message('Skipping search and tag since no files were selected.')
        end
      else
        progress_handler.log_message('Skipping search and tag as specified in config.')
      end

      # Culling.
      if run_culling
        if exclusion_sets.any?
          QCCull::exclude_items(nuix_case, scoping_query, exclusion_sets, progress_handler, timer, utilities)
        else
          progress_handler.log_message('Skipping exclude because no exclude tag prefixes were specified.')
        end
      else
        progress_handler.log_message('Skipping culling as specified in config.')
      end

      # Report.
      if run_create_report
        progress_handler.set_main_status_and_log_it('Generating report...')
        # Find report template.
        report_template_path = File.join(root_directory,'data','misc','qc','qc_report_template.rtf')
        spreadsheet_report_template_path = File.join(root_directory,'data','misc','qc','qc_spreadsheet_report_template.xml')
        report_settings = { 
          :num_source_files_provided => settings_hash[:num_source_files_provided],
          :scoping_query => scoping_query,
          :date_format => settings_hash[:date_format],
          :exclusion_sets => settings_hash[:exclusion_sets]
        }
        # Generate report.
        QCCull::generate_report(nuix_case, report_template_path, spreadsheet_report_template_path, report_path, spreadsheet_report_path, report_info_hash, report_settings, utilities)
      else
        progress_handler.log_message('Skipping report creation as specified in config.')
      end
    end
  end
end
