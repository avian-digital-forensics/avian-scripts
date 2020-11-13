require_relative File.join('..', '..', 'utils', 'utils')

require_relative File.join('..', '..', 'utils', 'rtf_utils')

module QCCull
  extend self

  # Updates the report at the specified path by substituting the values in the result_hash for the keys.
  # +result_hash+:: A hash where the keys are the keys for the fields in the report and the values are the values of those fields.
  # +report_file_path+:: The path to the report.
  def update_report(result_hash, report_file_path)
    report_text = File.read(report_file_path)
    for field,value in result_hash
      if !report_text.include?(field)
        puts('Cannot find field ' + field)
      end
      report_text.gsub!(field,value.to_s)
    end
    
    File.open(report_file_path, 'w') do |file|
      # Prepare special characters for ANSI.
      # Taken from https://stackoverflow.com/a/263324.
      file.write(report_text.unpack("U*").map{|c|c.chr}.join)
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

  # Converts a two layer hash to rtf.
  # The keys are the categories, the values are themselves hashes.
  # The subhashes contain fields and values.
  # The value for the category is taken to be the total of the subhash values.
  # Results are reported in descending order by values.
  # Params:
  # +hash+:: The hash to report.
  def report_two_layer_hash(hash)
    category_values = {}
    for category,sub_hash in hash
      category_values[category] = sub_hash.values.inject(0){ |sum,x| sum + x }
    end
    
    # Change newline settings.
    text = '\pard\sa200\sl240\slmult1'
    for category,sub_hash in hash.sort_by { |category,sub_hash| -category_values[category] }
      text += "#{category}: #{category_values[category].to_s}#{RTFUtils::newline}"
      for field,value in sub_hash.sort_by { |field, value| -value }
        text += "#{RTFUtils::tab}#{field}: #{value}#{RTFUtils::newline}"
      end
    end


    # Change newline settings back.
    text += '\pard\sa200\sl276\slmult1'
  end

  # Add a list of the number of each item type within the query scope to the report.
  # Params:
  # +nuix_case+:: The case in which to find the number of items of each type.
  # +result_hash+:: The result hash to add the result to.
  # +field_key+:: The key to substitute with the result.
  # +scoping_query+:: Only records items within this scope.
  def report_item_types(nuix_case, result_hash, field_key, scoping_query='')
    type_hash = {}
    for type in nuix_case.item_types
      query = Utils::join_queries(scoping_query, "mime-type:#{type.name}")
      num_items = nuix_case.count(query)
      # Add line for this type if there are any items.
      if num_items > 0
        kind_name = type.kind.localised_name
        unless type_hash.key?(kind_name)
          # Create hash for the kind if it isn't there already.
          type_hash[kind_name] = {}
        end
        type_hash[kind_name][type.localised_name] = num_items
      end
    end

    text = report_two_layer_hash(type_hash)

    result_hash[field_key] = text
  end

  # Creates a hash of field key=>field value.
  # Used to gsub the report.
  # Params:
  # +nuix_case+:: The case in which to search.
  # +info_hash+:: A hash with information about the ingestion.
  # +utilities+:: A reference to the Nuix utilities object.
  def create_result_hash(nuix_case, info_hash, utilities)
    result_hash = {}
    # 1 Ingestion details.
    for key,info in info_hash
        result_hash["FIELD_#{key}"] = info
    end
    current_time = Time.now.strftime("%Y/%m/%d")
    result_hash['FIELD_qc_start_date'] = current_time

    # 2 Ingestion statistics.
    report_item_types(nuix_case, result_hash, 'FIELD_ingestion_statistics')

    # 3 Source validation.
    report_item_types(nuix_case, result_hash, 'FIELD_source_file_statistics', 'flag:loose_file')

    result_hash['FIELD_num_source_files_ingested'] = nuix_case.count('flag:loose_file')

    # 4 Indexing issues.
    ## 4.1 Encrypted files.
    report_encrypted_items(nuix_case, result_hash, utilities)
    ## 4.2 Items without text.
    report_item_types(nuix_case, result_hash, 'FIELD_no_text_statistics', 'has-exclusion:0 AND tag:"Avian|QC|Unsupported|No text"')

    # 5 OCR.
    result_hash['FIELD_num_ocr_items'] = nuix_case.count('tag:"Avian|QC|OCR"').to_s

    # 6 Culling.
    exclusion_reasons = nuix_case.all_exclusions
    exclusion_hash = {'Excluded items' => Hash[exclusion_reasons.map { |reason| [reason, nuix_case.count("exclusion:\"#{reason}\"")] }]}
    result_hash['FIELD_exclusion_statistics'] = report_two_layer_hash(exclusion_hash)

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
    Utils::ensure_path_exists(File.expand_path(File.join(report_destination, '..')))
    FileUtils.cp(template_path, report_destination)
    # Update report with results.
    QCCull::update_report(result_hash, report_destination)
  end
end
