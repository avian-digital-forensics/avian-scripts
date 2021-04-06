report_template_file_path = 'PATH'

keys = [
	'FIELD_project_name',
	'FIELD_collection_number',
	'FIELD_requested_by',
	'FIELD_ingestion_start_date',
	'FIELD_ingestion_end_date',
	'FIELD_ingestion_performed_by',
	'FIELD_qc_start_date',
	'FIELD_qc_end_date',
	'FIELD_qc_performed_by',
	'FIELD_ingestion_statistics',
	'FIELD_num_source_files_provided',
	'FIELD_num_loose_files_in_nuix',
	'FIELD_source_validation_text',
	'FIELD_source_file_statistics',
	'FIELD_encrypted_pdf_num',
	'FIELD_encrypted_text_num',
	'FIELD_encrypted_spreadsheet_num',
	'FIELD_encrypted_presentation_num',
	'FIELD_no_text_statistics',
	'FIELD_num_ocr_items',
	'FIELD_num_with_content_ocr',
	'FIELD_percent_with_content_ocr',
	'FIELD_exclusion_statistics',
	'FIELD_language_counts',
	'FIELD_detailed_ingestion_statistics'
]

report_text = File.read(report_template_file_path)
for key in keys
	unless report_text.include?(key)
		puts("Could not find field '#{key}'")
	end
end
