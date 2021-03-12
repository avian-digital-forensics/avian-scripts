report_template_file_path = 'PATH'

keys = [
	'FIELD_collection_number',
	'FIELD_latest_revision',
	'FIELD_tag_list'
]

report_text = File.read(report_template_file_path)
for key in keys
	unless report_text.include?(key)
		puts("Could not find field '#{key}'")
	end
end
