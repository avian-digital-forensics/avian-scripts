# For loading and writing index.
require 'csv'

module Language
    extend self

    # Contains an index of language codes to language names.
    class LanguageIndex
        # Initializes the LanguageIndex with the modified ISO 639-3 index in the resources directory.
        def initialize
            @index = {}
            CSV.foreach(File.join(File.dirname(__FILE__), '..', 'resources/iso-639-3_index_without_inverted.tab'), col_sep: "\t") do |row|
                @index[row[0]] = row[1]
            end
        end

        # Finds the reference name of the language with the specified code.
        # Params:
        # +language_code+:: The language code of the language whose name to find.
        def [](language_code)
            return @index[language_code]
        end
    end


    # Removes the Inverted_Name column from the ISO 639-3 language index at the specified path.
    # Params:
    # +index_path+:: The file to remove the column from.
    def remove_inverted_name_from_index(index_path, output_path)
        index_array = []
        CSV.foreach(index_path, col_sep: "\t") do |row|
            index_array << row[0..1]
        end
        CSV.open(output_path, 'wb', col_sep: "\t") do |csv|
            for row in index_array
                csv << row
            end
        end
    end
end
