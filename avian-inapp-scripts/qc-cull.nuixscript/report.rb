module QCCull
    extend self

    # Updates the report at the specified path by substituting the values in the result_hash for the keys.
    # +result_hash+:: A hash where the keys are the keys for the fields in the report and the values are the values of those fields.
    # +report_file_path+:: The path to the report.
    def update_report(result_hash, report_file_path)
        report_text = File.read(report_file_path)
        updated_report_text = report_text.gsub(/FIELD_.*?\b/, information_hash)
        File.open(report_file_path, 'w') do |file|
            file.write(updated_report_text)
        end
    end

    # Adds to the result_hash the number of items tagged as encrypted items of various types.
    # +nuix_case+:: The case in which to search.
    # +result_hash+:: The hash to add the results to.
    def report_encrypted_items(nuix_case, result_hash)
        encrypted_tag_hash = {
            'Avian|QC|Encrypted|PDF' => 'encrypted_pdf_num',
            'Avian|QC|Encrypted|Text Documents' => 'encrypted_text_num',
            'Avian|QC|Encrypted|Spreadsheets' => 'encrypted_spreadsheet_num',
            'Avian|QC|Encrypted|Presentations' => 'encrypted_presentation_num'
        }
        for tag,field_key in encrypted_tag_hash
            result_hash[field_key] = nuix_case.count("tag:\"#{tag}\"")
        end
    end
end
        