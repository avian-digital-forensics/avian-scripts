script_directory = File.dirname(__FILE__)
require File.join(script_directory,'..','setup.nuixscript','get_main_directory')

main_directory = get_main_directory(false)

unless main_directory
    puts('Script cancelled because no main directory could be found.')
    return
end

require File.join(main_directory, 'utils', 'utils')

module QCCull
  extend self

  # Updates the report at the specified path by substituting the values in the result_hash for the keys.
  # +result_hash+:: A hash where the keys are the keys for the fields in the report and the values are the values of those fields.
  # +report_file_path+:: The path to the report.
  def update_report(result_hash, report_file_path)
    report_text = File.read(report_file_path)
    for field,value in result_hash
      report_text.gsub!(field,value)
    end
    File.open(report_file_path, 'w') do |file|
      file.write(report_text)
    end
  end

  # Adds to the result_hash the number of items tagged as encrypted items of various types.
  # Params:
  # +nuix_case+:: The case in which to search.
  # +result_hash+:: The hash to add the results to.
  # +utilities+:: A reference to the Nuix utilities object.
  def report_encrypted_items(nuix_case, result_hash, utilities)
    encrypted_tag_hash = {
      'Avian|QC|Encrypted|PDF' => 'encrypted_pdf_num',
      'Avian|QC|Encrypted|Text Documents' => 'encrypted_text_num',
      'Avian|QC|Encrypted|Spreadsheets' => 'encrypted_spreadsheet_num',
      'Avian|QC|Encrypted|Presentations' => 'encrypted_presentation_num'
    }
    for tag,field_key in encrypted_tag_hash
      result_hash["FIELD_#{field_key}"] = Utils::search_count_deduplicated(nuix_case, "tag:\"#{tag}\"", utilities)
    end
  end

  # Adds to the result_hash the number of excluded items.
  # Params:
  # +nuix_case+:: The case in which to search.
  # +result_hash+:: The hash to add the results to.
  # +utilities+:: A reference to the Nuix utilities object.
  def report_culling(nuix_case, result_hash, utilities)
    result_hash['FIELD_num_excluded_items'] = nuix_case.count('has-exclusion:1').to_s
  end

  # Creates a hash of field key=>field value.
  # Used to gsub the report.
  # Params:
  # +nuix_case+:: The case in which to search.
  # +info_hash+:: A hash with information about the ingestion.
  # +utilities+:: A reference to the Nuix utilities object.
  def create_result_hash(nuix_case, info_hash, utilities)
    result_hash = {}
    # Add ingestion information to report.
    for key,info in info_hash
        result_hash["FIELD_#{key}"] = info
    end
    current_time = Time.now.strftime("%d/%m/%Y")
    result_hash['FIELD_qc_start_date'] = current_time
    report_encrypted_items(nuix_case, result_hash, utilities)

    result_hash['FIELD_num_ocr_items'] = nuix_case.count('tag:"Avian|QC|OCR"').to_s

    report_culling(nuix_case, result_hash, utilities)

    return result_hash
  end

  # Generates the report from a template.
  # Params:
  # +template_path+:: The path to the report template.
  # +report_destination+:: The path in which to place the generated report.
  # +info_hash+:: A hash with information about the ingestion.
  def generate_report(nuix_case, template_path, report_destination, info_hash, utilities)
    # Create hash.
    result_hash = create_result_hash(nuix_case, info_hash, utilities)
    # Copy report template.
    FileUtils.cp(template_path, report_destination)
    # Update report with results.
    QCCull::update_report(result_hash, report_destination)
  end
end
    