require_relative File.join('..', '..', 'utils', 'utils')

require_relative File.join('..', '..', 'utils', 'rtf_utils')
require_relative File.join('..', '..', 'utils', 'language')

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
  
  # Converts a two layer hash to an rtf text string.
  # The keys are the categories, the values are themselves hashes.
  # The subhashes contain fields and values.
  # The value for the category is taken to be the total of the subhash values.
  # Results are reported in descending order by values.
  # Params:
  # +hash+:: The hash to report.
  # +report_sub_hashes+:: Whether to add the sub hashes. Defaults to true.
  def report_two_layer_hash(hash, report_sub_hashes=true)
    category_values = {}
    for category,sub_hash in hash
      category_values[category] = sub_hash.values.inject(0){ |sum,x| sum + x }
    end
    
    text = ''

    # Change newline settings.
    text += '\pard\sa200\sl240\slmult1'

    if hash.empty?
      text += RTFUtils.bold('No such items in case') + RTFUtils::newline
    else
      for category,sub_hash in hash.sort_by { |category,sub_hash| -category_values[category] }
        text += RTFUtils.bold("#{category}: #{category_values[category].to_s}") + RTFUtils::newline
        if report_sub_hashes
          for field,value in sub_hash.sort_by { |field, value| -value }
            text += RTFUtils.italics("#{RTFUtils::tab}#{field}: #{value}") + RTFUtils::newline
          end
        end
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
  def report_item_types(nuix_case, result_hash, field_key, scoping_query='', detailed=true)
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

    text = report_two_layer_hash(type_hash, detailed)

    result_hash[field_key] = text
  end

  # Adds a list of languages present in the case and the number of files with that language.
  # Params:
  # +nuix_case+:: The case to report on.
  # +result_hash+:: The hash to add the results to.
  # +scoping_query+:: Limit searches to this query.
  def report_languages(nuix_case, result_hash, scoping_query)
    language_name_index = Language::LanguageIndex::new
    case_languages = nuix_case.languages
    language_counts = {}
    for language_code in case_languages
      name = language_name_index[language_code]
      count = nuix_case.count(Utils::join_queries(scoping_query, "lang:#{language_code}"))
      if count != 0
        language_counts[name] = count
      end
    end
    result_hash['FIELD_language_counts'] = report_two_layer_hash({'Languages' => language_counts})
  end

  # Adds to the result_hash the number of items tagged as encrypted items of various types.
  # Params:
  # +nuix_case+:: The case in which to search.
  # +result_hash+:: The hash to add the results to.
  # +utilities+:: A reference to the Nuix utilities object.
  def report_encrypted_items(nuix_case, result_hash, utilities, scoping_query)
    encrypted_tag_hash = {
      'Avian|QC|Encrypted|PDF' => 'encrypted_pdf_num',
      'Avian|QC|Encrypted|Text Documents' => 'encrypted_text_num',
      'Avian|QC|Encrypted|Spreadsheets' => 'encrypted_spreadsheet_num',
      'Avian|QC|Encrypted|Presentations' => 'encrypted_presentation_num'
    }
    for tag,field_key in encrypted_tag_hash
      result_hash["FIELD_#{field_key}"] = Utils::search_count_deduplicated(nuix_case, Utils::join_queries(scoping_query, Utils::create_tag_query(tag)), utilities)
    end
  end

  # Adds source file validation information to the result_hash.
  # Params:
  # +nuix_case+:: The case in which to search.
  # +result_hash+:: The hash to add the results to.
  # +num_source_files_provided+:: The number of originally provided source files as given by the user.
  # +scoping_query+:: Limit search for loose files.
  def report_source_files(nuix_case, result_hash, num_source_files_provided, scoping_query)
    report_item_types(nuix_case, result_hash, 'FIELD_source_file_statistics', Utils.join_queries(scoping_query, 'flag:loose_file'))
    num_loose_files_in_nuix = nuix_case.count(Utils.join_queries(scoping_query, 'flag:loose_file'))
    
    result_hash['FIELD_num_source_files_provided'] = num_source_files_provided
    result_hash['FIELD_num_loose_files_in_nuix'] = num_loose_files_in_nuix
    if num_source_files_provided.to_i == num_loose_files_in_nuix.to_i
      result_hash['FIELD_source_validation_text'] = 'These numbers match and so all source files were processed without error.'
    else
      result_hash['FIELD_source_validation_text'] = 'These numbers DO NOT MATCH and so some source files ARE MISSING from the case and an error has occurred.'
    end
  end

  # Adds ocr information to the result_hash.
  # Params:
  # +nuix_case+:: The case to provide information about.
  # +result_hash+:: The hash to add the results to.
  # +scoping_query+:: Limit search to this query.
  def report_ocr(nuix_case, result_hash, scoping_query)
    num_ocr = nuix_case.count(Utils::join_queries('(flag:ocr_succ* OR flag:ocr_failed) AND content:*', scoping_query))
    num_embedded = nuix_case.count(Utils::join_queries('tag:"Avian|QC|OCR|OCR Embedded"', scoping_query))
    num_not_embedded = nuix_case.count(Utils::join_queries('tag:"Avian|QC|OCR|OCR Not embedded"', scoping_query))
    num_success_and_content = nuix_case.count(Utils::join_queries('tag:"Avian|QC|OCR|Succes and content"', scoping_query))
    result_hash['FIELD_num_ocr_items'] = num_ocr.to_s
    result_hash['FIELD_num_with_content_ocr'] = num_success_and_content.to_s
    result_hash['FIELD_percent_with_content_ocr'] = num_ocr == 0 ? '0' : (num_success_and_content.to_f/num_ocr * 100).round(0).to_s
  end

  # Formats a list of date FIELDs in the result hash according the the specified date_format.
  # Params:
  # +result_hash+:: The result hash in which to format dates.
  # +date_format+:: The date format to convert them to.
  def format_dates(result_hash, date_format)
    date_fields = ['FIELD_qc_start_date',
                   'FIELD_ingestion_start_date',
                   'FIELD_ingestion_end_date']
    for date_field in date_fields.select { |field| !result_hash[field].nil? }
      puts("helleflynder: #{date_field}:#{result_hash[date_field]}")
      date = Date.parse(result_hash[date_field])
      result_hash[date_field] = date.strftime(date_format)
    end
  end

  # Creates a hash of field key=>field value.
  # Used to gsub the report.
  # Params:
  # +nuix_case+:: The case in which to search.
  # +info_hash+:: A hash with information about the ingestion.
  # +report_settings+:: Settings used for more than simply inserting into the report.
  # +utilities+:: A reference to the Nuix utilities object.
  def create_result_hash(nuix_case, info_hash, report_settings, utilities)
    scoping_query = report_settings[:scoping_query]
    result_hash = {}
    # 1 Ingestion details.
    for key,info in info_hash
        puts('ål:' + key)
        result_hash["FIELD_#{key}"] = info
    end
    current_time = Time.now.strftime("%Y/%m/%d")
    result_hash['FIELD_qc_start_date'] = current_time

    # 2 Ingestion statistics.
    # 2.1 Type statistics.
    report_item_types(nuix_case, result_hash, 'FIELD_ingestion_statistics', scoping_query, false)
    # 2.2 Languages
    report_languages(nuix_case, result_hash, scoping_query)

    # 3 Source validation.
    report_source_files(nuix_case, result_hash, report_settings[:num_source_files_provided], scoping_query)

    # 4 Indexing issues.
    ## 4.1 Encrypted files.
    report_encrypted_items(nuix_case, result_hash, utilities, scoping_query)
    ## 4.2 Items without text.
    report_item_types(nuix_case, result_hash, 'FIELD_no_text_statistics', Utils::join_queries(scoping_query, 'has-exclusion:0 AND tag:"Avian|QC|Unsupported Items|No text"'))

    # 5 OCR.
    report_ocr(nuix_case, result_hash, scoping_query)

    # 6 Ingestion statistics details.
    report_item_types(nuix_case, result_hash, 'FIELD_detailed_ingestion_statistics', scoping_query, true)

    # 7 Culling.
    exclusion_reasons = nuix_case.all_exclusions
    exclusion_hash = {'Excluded items' => Hash[exclusion_reasons.map { |reason| [reason, nuix_case.count("exclusion:\"#{reason}\"")] }.select { |reason| reason[1] != 0 }]}
    result_hash['FIELD_exclusion_statistics'] = report_two_layer_hash(exclusion_hash)

    # Format dates
    format_dates(result_hash, report_settings[:date_format])

    return result_hash
  end

  # Generates the report from a template.
  # Params:
  # +template_path+:: The path to the report template.
  # +report_destination+:: The path in which to place the generated report.
  # +info_hash+:: A hash with information about the ingestion.
  # +report_settings+:: Settings used for more than simply inserting into the report.
  # +utilities+:: Reference to the Nuix Utilities object.
  def generate_report(nuix_case, template_path, report_destination, info_hash, report_settings, utilities)
    # Create hash.
    result_hash = create_result_hash(nuix_case, info_hash, report_settings, utilities)
    # Copy report template.
    Utils::ensure_path_exists(File.expand_path(File.join(report_destination, '..')))
    FileUtils.cp(template_path, report_destination)
    # Update report with results.
    QCCull::update_report(result_hash, report_destination)
  end
end
